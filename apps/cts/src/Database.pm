package Database;

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use File::Basename;
use YAML qw();

use base qw(Exporter);

use lib "$FindBin::Bin";
use LekanUtils;
use LekanConfig;
use GetVideoInfo;

our @EXPORT = qw(insert_into_task insert_into_onepass insert_into_video
                 insert_into_worker generate_encode_options
                 get_job_from_onepass get_job_from_video get_job_from_task
                 update_db update_task check_task_is_done insert_into_upload
                 get_task_info get_script_by_id get_video_options get_audio_options
                 get_encode_str get_encode_file get_source_file
            );
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub close_db {
    my $dbh = shift;

    $dbh->disconnect;
    return;
}

sub insert_into_task {
    my $video = shift;
    ### $video
    my $dbh  = connect_database();

    my $subtitle  = get_subtitle( $video );
    ### $subtitle    
    my $filetype  = get_file_type( $video );
    ### $filetype    
    my $vtype     = get_video_type( $video );
    ### $vtype    
    my $interlace = get_video_interlaced( $video );
    ### $interlace
    if ( not defined $subtitle or not defined $filetype or not defined $vtype or not defined $interlace) {
        runlog(__PACKAGE__, $video, '获取视频信息出错', "字幕 [$subtitle]", "文件类型 [$filetype]", "视频类型 [$vtype],", $interlace, "是否拉丝 [$interlace]");
        return 1;
    }
    my $sql = qq{INSERT INTO task (pathName, subtitle, fileType, videoType, f_type) VALUES(?, ?, ?,?, ?)};

    my $sth = $dbh->prepare( $sql );
    $sth->execute($video, $subtitle, $filetype, $vtype, $interlace );

    if ($dbh->errstr) {
        # 记录错误日志
        runlog(__PACKAGE__, "INSERT ERROR: ", $dbh->errstr);
        return 1;
    }

    close_db($dbh);
    return 0;
}

sub insert_into_img {
    my $video_path = shift;
    
    my $output_pic_path = generate_img_path();

    my $sqp = '';
    my $dbh = connect_database();
    my $sql = 'insert into image ...';
    my $sth = $dbh->prepare( $sql );
    $sth->execure;
}

sub insert_into_machine {
    my @options = @_;

    my $ip = $options[0];
    my $dbh = connect_database();
    # 找出最大的机器的 ID，然后给该 ID 加1作为下一台机器的 ID
    my $sql = qq{select * from machine where max id};
    my $data = $dbh->selectrow_arrayref($sql);

    my $id = $data->[0] + 1;

    $sql = qq{ INSERT INTO machine (ip, id, hostname) VALUES (?, ?, ?)};
    my $sth = $dbh->prepare( $sql );
    $sth->execute();
}

sub insert_into_worker {
    my ($sid, $video_id, $script, $encode_type) = @_;
#    ($sid, $video_id, $priority, $script)
    my $dbh = connect_database();
    my $f_cmd = $script->[0];
    my $s_cmd = $script->[1];
    my $t_cmd = $script->[2];

    my $task_info = get_task_info( $sid );
    my $priority  = $task_info->{priority};
    my $sql = qq{INSERT INTO worker (sourceId, video_id, type, command1, command2, command3, priority) VALUES (?, ?, ?, ?, ?, ?, ?) };
    my $sth = $dbh->prepare( $sql );
    $sth->execute($sid, $video_id, $encode_type, $f_cmd, $s_cmd, $t_cmd,  $priority);
    my $flag = 0;
    if ( $dbh->errstr ) {
        runlog(__PACKAGE__, "向 worker 表里插入数据 $sid 出错",  $dbh->errstr);
        $flag = 1;
    } else {
        runlog(__PACKAGE__, "向 worker 表里插入数据 $sid 成功");
    }

    $dbh->disconnect;
    return $flag;
}

sub insert_into_video {
    my ($sid, $out_file, $script_id, $time, $encode_type) = @_;

    ### $sid
    ### $out_file
    ### $script_id
    ### $time
    ### $encode_type
    my $dbh = connect_database();
    my $sql = qq(INSERT INTO video(sourceId,outputFilename,script,time,encode_type) values (?,?,?,?,?));
    my $sth = $dbh->prepare( $sql );
    $sth->execute($sid, $out_file, $script_id, $time, $encode_type);

    $sql = qq(SELECT id FROM video where sourceId=$sid and script=$script_id and outputFilename='$out_file' and script=$script_id and encode_type='$encode_type' order by id desc limit 1);

    ### $sql
#    $sth = $dbh->prepare( $sql );
    my $id = $dbh->selectrow_array($sql);

    ### $id
    return $id;
}

sub update_db {
    my ($table, $key, $value, $id) = @_;

    my $dbh = connect_database();
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

sub get_task_info {
    my $id = shift;

    ### $id
    my $dbh = connect_database();
    my $sql = qq{select * from task where id=$id};
    my $data = $dbh->selectrow_hashref( $sql );

    ### $data
    return $data;
}



sub check_task_is_done {
    my $sourceId = shift;

    my $dbh = connect_database();
    my $sql = qq{SELECT status FROM worker WHERE sourceId=$sourceId};

    my $data = $dbh->selectall_arrayref( $sql );

    my $flag = 1;

    ### $data
    for my $status ( @$data ) {
        ### $flag
        if ( $status->[0] != 2 ) {
            $flag = 0;
            ### 349: $flag
            last;
        }
    }

    return $flag;
}

sub insert_into_upload {
    my ($path, $sid) = @_;
    
    my $ip = '192.168.1.222';

    my $dbh = connect_database();

    runlog(__PACKAGE__, "insert $path => upload");
    my $sql = qq{INSERT INTO upload(ip,path,sourceId) VALUES (?, ?, ?)};
    my $sth = $dbh->prepare( $sql );
    $sth->execute($ip, $path,$sid);
    if ($dbh->errstr ){
        runlog(__PACKAGE__, $dbh->errstr);
    }

    $dbh->disconnect;
}

# 获取转码脚本相关参数信息
sub get_script_by_id {
    my $id = shift;
    my $dbh = connect_database();
    my $sql = qq{select * from script where id=$id};

    my $data = $dbh->selectrow_hashref($sql);
    $dbh->disconnect;

    ### 'script': $data
    return $data;
}

#    my $video  = get_video_options( $encode->{video_options} );
sub get_video_options {
    my $id = shift;
    my $dbh = connect_database();
    my $sql = qq{select * from video_options where id=$id};
	print"$sql";

    my $data = $dbh->selectrow_hashref($sql);
	print"my $data";
    $dbh->disconnect;

    ### 'video_options': $data
    return $data;
}

sub get_audio_options {
    my $script_id = shift;

    ### $script_id
    my $dbh = connect_database();
    my $sql = qq{select * from audio_options where id=$script_id};

    my $data = $dbh->selectrow_hashref($sql);
    $dbh->disconnect;

    return $data;
}

sub get_encode_str {
    my $script_id = shift;

    ### $script_id
    my $dbh = connect_database();
    my $sql = qq{select * from encode_options where id=$script_id};

    my $data = $dbh->selectrow_hashref($sql);
    $dbh->disconnect;

    return $data->{arguments};
}

sub get_encode_file {
    my $id = shift;

    my $info = get_video_info( $id );

    return $info->{outputFileName};
}

sub get_source_file {
    my $id = shift;

    my $info = get_task_info( $id );

    return $info->{pathName};
}

sub get_video_info {
    my $id = shift;
    my $dbh = connect_database();
    my $sql = qq{select * from video where id=$id};

    my $data = $dbh->selectrow_hashref($sql);
    $dbh->disconnect;

    return $data;
}

1;
