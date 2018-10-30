#!/usr/bin/perl
# 向 mogilefs 存儲 mp4 文件

use strict;
use warnings;

use Smart::Comments;

use MogileFS::Client;
use File::Find::Rule;
use FindBin;
use DBI;
use File::Path;

#lekan_daemon();
worker();
 
sub worker {
    my $dbh = connect_database();

### $dbh
    while ( 1 ) {
        $dbh ||= connect_database();
        my $work_info = get_job_from_db( $dbh );

### $work_info
        unless ( @$work_info ) {
            sleep 300;
            next;
        }
    
        my ($id, $path) = @$work_info;

### $id
### $path
        my $rule = File::Find::Rule->new();
        $rule->file;
        $rule->name('*.mp4');
        my @mp4 = $rule->in( $path );

        @mp4 = sort { -s $a <=> -s $b } @mp4;

### @mp4
        my $flag = 0;
        my $mogile_key;
        update_db($dbh, 'mp4file', $id, 'status', 1);        
        foreach my $mp4_file ( @mp4 ) {
            $mogile_key = get_video_id( $mp4_file ) if not defined $mogile_key;
            my $ret  = store_file( $mp4_file );
            if ( $ret == 1 ) {
                $flag = 1;
                runlog($mp4_file, 'store failed');
            }
        }
        if ( $flag == 1 ) {
            update_db($dbh, 'mp4file', $id, 'status', 13);
            runlog($path, $id, 'store FAILED');
        } else {
            update_db($dbh, 'mp4file', $id, 'status', 2);
            insert_into_mp4task($dbh, $mogile_key);
            delete_dir( $path );
        }
    }

    return;
}

sub get_job_from_db {
    my $dbh = shift;
    my $data = [];
    for my $pri ( reverse 0..5 ) {
        my $sql = "SELECT id,path FROM mp4file WHERE status=0 and priority=$pri order by id limit 1";
        $data = $dbh->selectrow_arrayref( $sql );
### $data
        last if defined $data;
    }

    $data = [] if not defined $data;
    return $data;
}

sub store_file {
    my $file = shift;

    my $key  = generate_key( $file );
    return 1 if (not defined $key);
    runlog(__PACKAGE__, 'start store', $file, 'to mogilefs');
    
    my $class = 'ts';
    my $flag;
    my $i = 1;
### $file
### $key
    while ( $i++ ) {
        my $ret_store = store($class, $key, $file);
### $ret_store
        if ( $ret_store ) {
            runlog(__PACKAGE__, 'success store', $file, 'to mogilefs');
            $flag = 0;
            last;
        }

        sleep $i;
        if ( $i > 100 ) {
            runlog(__PACKAGE__, 'failed store', $file, 'to mogilefs');
            $flag = 1;
            last;
        }     
    }

    return $flag;
}

sub store {
    my ($class, $key, $file) = @_;

    my $size;
    while ( 1 ) {
        my $mogc = connect_mogilefs();
        $size = eval {
            $mogc->store_file($key, $class, $file, {
                'chunk_size' => 10240000,
            });};
        if ( $@ ) {
            sleep 10;
            runlog(__PACKAGE__, 'retry store file', $file, 'into mogilefs');
            next;
        }
        last;
    }
    return $size;
}

sub generate_key {
    my ($path) = @_;
    # /cts/out_video/917/17/13917E25/cn/video-1200k.mp4
    if ( $path =~ m{\d+/\d+/(\S+)/(\S+)/video-(\S+)\.mp4} ) {
        return "$1-$2-$3.mp4";
    }

    return;
}

sub get_video_id {
    my $file = shift;

    my @path = split /\//, $file;

    my ($retkey) = grep { /(\d+(M|E)(\d+)?)/ } @path;

    ### $retkey
    return $retkey;
}

sub insert_into_mp4task {
    my ($dbh, $key) = @_;
    my $sth = $dbh->prepare( qq{INSERT INTO mp4task(mogilekey) VALUES(?) } ) ;

    $sth->execute($key);

    my $ret = 1;
    if ( $dbh->errstr ) {
        $ret = 0;
        runlog(__PACKAGE__, 'insert into 132 database,sendfile failed:', $dbh->errstr);
    }

    return $ret;
}

sub connect_database {
### 'connect_db'
    my $dbhost = 'localhost';
    my $dbport = 3306;
    my $dbuser = 'root';
    my $dbpass = '';
    my $dbname = 'sendfile';

    my $db     = "DBI:mysql:$dbname;host=$dbhost";
    my $dbh;
    while ( 1 ) {
        $dbh = DBI->connect( $db, $dbuser, $dbpass,
                             {
                                 RaiseError => 1,
                             }
                         );
        last if not defined $DBI::errstr;
### $DBI::errstr
        sleep 5;
    }

### $dbh
    return $dbh;
}

sub lekan_daemon {
    my ($pid, $sess_id, $i);

    if ( $pid = fork ) {
        exit 0;
    }

    Carp::croak "can't detach from controlling terminal"
          unless $sess_id = POSIX::setsid();

    $SIG{'HUP'} = 'IGNORE';

    if ( $pid = fork ) {
        exit 0;
    }

    chdir "/";
    umask 0;

    open(STDIN,  "<", "/dev/null");
    open(STDOUT, "<", "/dev/null");
    open(STDERR, "<", "/dev/null");
}

sub runlog {
    my @log_message = @_;

    my $file = $FindBin::Bin. '/store-file.log';
    #    my $file = '/cts/cts-working.log';
    open my $fh, '>>', $file
	or die "Can't open $file: $!";

    print $fh scalar localtime;
    print $fh ' ';
    print $fh join ' ', @log_message;
    print $fh "\n";

    return;
}

sub update_db {
    #update_db($dbh, 'mp4file', $id, 'status', 1);        
    my ($dbh, $table, $id, $key, $value) = @_;

    my $sql = qq{update $table set $key='$value' where id=$id};

    my $rows_affected = $dbh->do( $sql );

    my $flag;
    if ( $rows_affected > 0 ) {
        runlog(__PACKAGE__, '更新表', $table, ':', $id, $key, '=>', $value, '成功');
        $flag = 0;
    } else {
        runlog(__PACKAGE__, '更新表', $table, ':', $id, $key, '=>', $value, '失败');
        $flag = 1;       
    }

    return $flag;
}

sub connect_mogilefs {
    my $domain = 'TS';
    my $hosts  = '192.168.1.222:7001';

    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => $domain,
                                                hosts  => [ $hosts ]
                                            ); };

        last unless $@;
        # 连接成功后退出
        sleep 10;
        runlog(__PACKAGE__, 'retry connect to mogilefs');
    }

    return $mogc;
}

sub delete_dir {
    my $dir = shift;

    my $err;
    rmtree( $dir, { error => \$err } );

    if ( defined $err ) {
        runlog('delete dir', $dir, 'failed', @$err);
    } else {
        runlog('delete dir', $dir, 'SUCCESS');
    }

    return;
}

