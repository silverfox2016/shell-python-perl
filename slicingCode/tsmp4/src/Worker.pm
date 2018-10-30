package Worker;

use strict;
use warnings;

use Smart::Comments;
use File::Path;
use Cwd;

use FindBin;
use lib $FindBin::Bin;
use Database;
use StoreFileToMogileFS;
use LekanUtils;
use CutMp4ToTs;
use UpdateCMS;
use Purge;
use PubTask;
use GenerateTask;

use base qw(Exporter);

our @EXPORT = qw(worker);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub worker {
    my $dbh = open_mogilefs_db();

    my ($table, $column) = ('ts', 'status');
    while ( 1 ) {
        my $mp4_dir = get_task_from_db( $dbh );
        if ( not defined $mp4_dir or not @$mp4_dir ) {
# 29: 'sleep'
            sleep 200;
            next;
        }

### $mp4_dir
        my ($id, $ts_dir) = @$mp4_dir;
        runlog(__PACKAGE__, "取到任务 $ts_dir");
        while ( 1 ) {
            my $flag = judge_db( $dbh );
            last unless $flag;
            sleep 60;
        }

### 41: 'cut ts'
        runlog(__PACKAGE__, "$ts_dir 开始切割ts");
        update_db($dbh, 'ts', $id, 'status', 1);
        my $flag = 0;
        for my $lang ( qw(cn en) ) {
            my $lang_dir = "$ts_dir/$lang";
### $lang_dir
            my $ret_value = cut_ts( $lang_dir );
            if ($ret_value == 0) {
                runlog("$lang_dir 切割 ts 失败");
                update_db($dbh, $table, $id, $column, 13);
                #delete_dir( $lang_dir );
                next;
            }
            runlog("$lang_dir 切割 SUCCESS");
            update_db($dbh, 'ts', $id, 'status', 2);


            runlog("$lang_dir 开始传文件");
            update_db($dbh, $table, $id, $column, 3);
### 56: 'finished'
            my $store_ret = store_to_mogilefs( $lang_dir );
            if ( $store_ret ) {
                $flag = 1;
                update_db($dbh, $table, $id, $column, 4);
                runlog("存储 $lang_dir 完成");
            } else {
                update_db($dbh, $table, $id, $column, 13);
                runlog("存储 $lang_dir 失败");
            }

            if (not defined $flag) {
                #delete_dir( $lang_dir );
                next;
            }
        }

        $flag = 0;
        my $key = get_key( $ts_dir );
        my $check_ret = check_file_completeness( $key );
        if ( $check_ret ) {
            $flag = 1;
            update_db($dbh, $table, $id, $column, 5);
            runlog("$key MogileFS 存储完整");
            my $videoinfo = $key. '-videoinfo.xml';
	        my $ret = update_cms( $videoinfo );
            if ( $ret ) {
                runlog("更新 CMS $key 成功");
                update_db($dbh, $table, $id, $column, 6);
                my $task_msg = generate_task_msg($key);
                #publish_task( $task_msg );
				#runlog("add [$task_msg] to rabbit.");
				#runlog("start purge $key cache");
				#purge_cache( $key );
                #runlog("finish purge $key cache");
            } else {
                update_db($dbh, $table, $id, $column, 13);
                runlog("更新 CMS $key 失败");
            }
        } else {
            update_db($dbh, $table, $id, $column, 13);
            runlog("$key MogileFS 存储缺失文件");
            #insert_data_into_db($dbh, 'mp4task',  'mogilekey', $key);
        }
### $ts_dir        
        #delete_dir( $ts_dir );
    }
}

sub check_file_completeness {
    my $key = shift;
    #my $cmd = qq{/home/weinh/mogilefs/src/mogtool.pl -p $key -c};
    #20180305 change by wxp
    my $cmd = qq{/lekan/slicingCode/mogilefs/src/mogtool.pl -p $key -c};

    open my $fh, '-|', $cmd
        or die "Can't open pipe line: $!";

### 119: 'check_file'
    while ( <$fh> ) {
        chomp;
### $_
        if ( /文件完整/ ) {
            return 1;
        }
    }

    return 0;

}

sub get_key {
    my $file = shift;

    my $key = (split(/\//, $file))[-1];

    return $key;
}

sub delete_dir {
    my $dir = shift;
   
    return if not defined $dir;
    chdir $dir;
    chdir "../";

    my $err;
    rmtree( $dir, { error => \$err } );

    if ( defined $err ) {
        runlog('delete dir', $dir, 'failed', error2str($err));
    } else {
        runlog('delete dir', $dir, 'SUCCESS');
    }

    return;
}

sub error2str {
    my $err = shift;
    my @error;
    for my $diag (@$err) {
        my ($file, $message) = %$diag;
        if ($file eq '') {
            push @error, "general error: $message";
        }
        else {
            push @error, "problem unlinking $file: $message";
        }
    }

    return join ' ', @error;
}

1;

__END__
状态说明:
    0  未处理
    1  正在切割 TS
    2  切割 TS 完成
    3  正在 upload 文件
    4  存储 TS 完成
    5  文件完整
    6  更新 CMS 成功
    13 出现错误
