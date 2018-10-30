package Worker;

use strict;
use warnings;

use Smart::Comments;
use File::Basename;
use File::Copy;
use File::Path;
use POSIX;

use FindBin;
use lib $FindBin::Bin;
use Database;
use LekanUtils;
use LekanConfig;
use DeleteFile;
use CheckVideo;
use DvdDeinterlace;

use base qw(Exporter);

our @EXPORT = qw(worker);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub worker {
    my $task = fetch_task();
    
    return if not defined $task;

    ### $task
    my $sourceId = $task->{sourceId};
    my $workdir  = get_work_dir( $task->{sourceId} );

    chdir $workdir;

    # 跟新数据库相关表，将该任务状态置成不可取
    update_db( 'worker', 'status', 1, $task->{id} );
    update_db( 'video', 'status', 1, $task->{video_id} );
    my $ip = get_local_ipaddr();
    update_db('worker', 'ipId', $ip, $task->{id} );

    # 等一段时间，取出 ip，地址，看是否和本机的一样
    # 如果不一样的话，说明任务被别人抢拉，需要重新
    # 找任务
    sleep 5;
    my $check_flag = check_task_duplicate( $task->{id}, $ip );
    return if $check_flag;

    my $time = strftime("%Y-%m-%d %H:%M:%S", localtime);
    update_db('video', 'beginTime', $time, $task->{video_id});

    if ( $task->{type} eq 'onepass' ) {
        update_db('task', 'status', 1, $task->{sourceId});
        update_db('task', 'beginTime', $time, $task->{sourceId});
        my $need_deinterlace = get_dvd_by_name( $task->{sourceId} );
        if ( $need_deinterlace ) {
            # $need_deinterlace 为 task 里的一个 ID
            # 含有视频的相关信息
            my $interlace_ret = deinterlace_dvd( $need_deinterlace );
            if ( $interlace_ret ) {
                update_db('worker', 'status', 13, $task->{id} );
                sleep 5;
                update_db('task', 'status', 13, $task->{sourceId} );
                return;
            }
        }
    }
    
    my $mplayer = '/usr/local/bin/mplayer';
    my $x264    = '/usr/local/bin/x264';
    my $ffmpeg  = '/usr/local/bin/ffmpeg';
    my $flag = 0;
    
    my $retry = 0;
    my $command = $task->{command1};
    $command =~ s{MPLAYER_PROG}{$mplayer}e;
    $command =~ s{X264_PROG}{$x264}e;
    $command =~ s{FFMPEG_PROG}{$ffmpeg}e;
    
    my $first_cmd_script = generate_tmp_script( \$command );
	runlog(__PACKAGE__, $task->{id}, "$command");
    while ( $retry < 3 ) {
        `./$first_cmd_script>/root/debug.log`;
        my $job_worker_ret = $? >> 8;
    
        if ( $job_worker_ret == 0 ) {
            runlog(__PACKAGE__, $task->{id}, 'command1 任务成功执行');
            unlink $first_cmd_script;
            last;
            # 跟新 worker 表
        } elsif (++$retry < 3) {
            runlog(__PACKAGE__, $task->{id}, '任务执行失败', '重试第', $retry, '次');
            sleep 6;
        } else {
            my $time = strftime("%Y-%m-%d %H:%M:%S", localtime);
            runlog(__PACKAGE__, $task->{id}, '任务执行失败');
            update_db('worker', 'status', 13, $task->{id} );
            update_db('video', 'status', 13, $task->{video_id} );
            update_db('task', 'finishTime', $time, $task->{sourceId});
            return;
        }
    }

    my $s_cmd = $task->{command2};
    if ( defined $s_cmd ) {
        delete_duplicate_file( $task->{video_id} ) if ( $task->{type} eq 'twopass' );
        $s_cmd =~ s{MPLAYER_PROG}{$mplayer}e;
        $s_cmd =~ s{X264_PROG}{$x264}e;
        $s_cmd =~ s{FFMPEG_PROG}{$ffmpeg}e;
        
        `$s_cmd`;
        my $qt_ret = $?;
        $flag = check_return_value( $qt_ret );
        if ( $flag ) {
            update_db('worker', 'status', 13, $task->{id} );
            return;
        }
    }
    
    my $t_cmd = $task->{command3};    
    if ( defined $t_cmd) {
        $t_cmd =~ s{MPLAYER_PROG}{$mplayer}e;
        $t_cmd =~ s{X264_PROG}{$x264}e;
        $t_cmd =~ s{FFMPEG_PROG}{$ffmpeg}e;
        `$t_cmd`;
        my $qt_ret = $?;
        $flag = check_return_value( $qt_ret );
        if ( $flag ) {
            update_db('worker', 'status', 13, $task->{id} );
            return;
        }
    }

    if ($task->{type} eq 'onepass') {
        $flag = 0;
    } elsif ( $task->{type} eq 'twopass' ) {
        $flag = check_encode_video( $task );
    }

    if ( $flag == 1 ) {
        update_db('worker', 'status', 13, $task->{id} );
        update_db('video', 'status', 13, $task->{video_id} );
        update_db('task', 'status', 13, $task->{sourceId} );

        return;
    }
    
    update_db('worker', 'status', 2, $task->{id} );
    update_db('video', 'status', 2, $task->{video_id} );
    
    $time = strftime("%Y-%m-%d %H:%M:%S", localtime);
    update_db('video', 'endTime', $time, $task->{video_id});
    # 如果 worker 表里同一个 sourceId 的所有任务状态
    # 都为 2， 则更新 task 状态为 2
    if ( check_task_is_done( $task->{sourceId} ) ) {
        update_db( 'task', 'status', 2, $task->{sourceId} );
        update_db( 'task', 'finishTime', $time, $task->{sourceId});
        delete_file( $workdir );
        insert_into_upload( $workdir, $task->{sourceId} );
    }
}

sub get_work_dir {
    my $sid = shift;

    my $tmp = get_task_info( $sid );
    my $filename = $tmp->{pathName};

    my $working_dir = generate_output_path( $filename );

    return $working_dir;
}

sub fetch_task {
    my $dbh = connect_database();
    
    my $task;
    for my $index ( reverse 0..5 ) {
        my $sql = qq{SELECT * FROM worker where status=0 and priority=$index
                     ORDER BY sourceId LIMIT 1};
        $task = $dbh->selectrow_hashref( $sql );
        last if defined $task;
    }

    return if not defined $task;

    if ( $task->{type} eq 'twopass' ) {
        # 二次编码必须在一次编码完成后方可以开始
        # 此处会造成死锁，如果某个任务的一次编码
        # 错误，将会导致程序一直循环
        my $can_run = judge_task( $task->{sourceId} );
        ### $can_run
        if ( $can_run == 0 ) {
            judge_task_err( $task->{sourceId}, $task->{id} );
            $task = select_job( $task->{sourceId} );
        }
    }

    $dbh->disconnect;
    return $task;
}

sub judge_task {
    my $sourceId = shift;

    my $dbh = connect_database();

    my $sql = qq{SELECT * FROM worker where status=2 and sourceId=$sourceId
                 and type='onepass'};
    ### $sql
    my $data = $dbh->selectrow_hashref( $sql );

    ### $data
    my $flag = 0;
    if ( defined $data ) {
        $flag = 1;
    }

    ### $flag
    return $flag;
}

## by lixx
# 判断所取任务的onepass状态status=13时,更新该任务为出错状态status=13
sub judge_task_err {
    my ($sourceId, $id) = @_;

    my $dbh = connect_database();
    my $sql = qq{SELECT * FROM worker where status=13 and sourceId=$sourceId and type='onepass'};
    ### $sql
    my $data = $dbh->selectrow_hashref( $sql );

    ### $data
    if ( defined $data ) {
        update_db( 'worker', 'status', 13, $id );
    }
}
## end by lixx

sub select_job {
    my $sId = shift;
    my $task;

    my $dbh = connect_database();
    for my $index ( reverse 0..5 ) {
        my $sql = qq{SELECT * FROM worker where status=0 and priority=$index
                     and type='onepass' ORDER BY sourceId LIMIT 1};
        $task = $dbh->selectrow_hashref( $sql );
        last if defined $task;
    }

    my $max_source_id = get_max_source_id( $dbh );

    if (not defined $task) {
        # 有可能某个 ID 的任务不能执行，然后后面的就不行执行了
        # onpass 的 status=13, 然后选取到的任务都是它的二次编码
        # 由此以后选取的都需要跳过他
        while ( $sId ++ <= $max_source_id  ) {
        # 选取任务，在当前 ID 到最大 ID 的范围内
        # FIX: 如果有的任务根据 ID 是后面加进去的
        # 可能会出现问题
            my $flag=0;
            for my $index ( reverse 0..5 ) {
                my $sql = qq{SELECT * FROM worker where status=0 and priority=$index
                             and sourceId>$sId ORDER BY sourceId LIMIT 1};
                ### $sql
                $task = $dbh->selectrow_hashref( $sql );
                if ( defined $task ) {
                    $flag = judge_task( $task->{sourceId} );
                    ### 253: $task
                    ### 254: $flag
                    last if $flag;
                    $task = undef;
                }
            }
            last if $flag;
        }
    }

    ### 'select_job': $task    
    $dbh->disconnect;
    return $task;
}

sub check_return_value {
    my $value = shift;

    my $ret = $value >> 8;

    my $flag = 0;
    if ( $ret != 0 ) {
        $flag = 1;
    }

    return $flag;
}

sub check_encode_video {
    my $task_info = shift;

    my $output_file = get_encode_file( $task_info->{video_id} );

    return 0 if ($output_file eq '/lekan/apps/cts/src/check_encode_video.log');
    return 1 if ( check_video_id_count($output_file) );
    
    my $flag = check_video_time( $output_file );
    if ( $flag ) {
        return 1;
    }
    my $source_file = get_source_file( $task_info->{sourceId} );
    $flag = compare_source_out_video_time( $output_file, $source_file );
    return 1 if $flag;
    return 0;
}

sub generate_tmp_script {
    my $command = shift;

    my $time = time;
    my $file = "mplayer-$time.sh";

    open my $fh, '>', $file
        or return;


    print $fh "#!/bin/bash\n\n";

    print $fh $$command;
    print $fh "\n";
    close $fh;

    `chmod +x $file`;
    return $file;
}

sub delete_duplicate_file {
    my $id = shift;

    my $output_file = get_encode_file( $id );

    unlink $output_file if ( -e $output_file );

    return;
}

sub get_dvd_by_name {
    my $sid = shift;

    my $task = get_task_info( $sid );

    # DVD 全部反拉丝
    return $sid if ( $task->{f_type} =~ /Interlaced/i
                      or $task->{fileType} != 1);

    return $sid if ( $task->{f_type} =~ /Interlaced/i );

    return;
}

sub check_task_duplicate {
    my ($id, $ip) = @_;
    my $dbh = connect_database();
    my $sql = qq{SELECT ipId FROM worker where id=$id};
    my $task = $dbh->selectrow_arrayref( $sql );

    my $flag = 1;

    if (defined $task) {
        my $worker_ip = $task->[0];
        ### $worker_ip
        $flag = 0 if ( $worker_ip eq $ip );
    }

    ### $flag
    $dbh->disconnect; return $flag;
}

sub get_max_source_id {
    my $dbh = shift;

    my $sql = qq{select max(sourceId) from worker};
    my $task = $dbh->selectrow_array( $sql );

    return $task;
}

1;
