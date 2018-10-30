package SplitJob;

use strict;
use warnings;

use Smart::Comments;
use File::Basename;
use Time::HiRes qw(gettimeofday);
use POSIX;

use base qw(Exporter);

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;
use LekanConfig;
use Database;
use GetVideoInfo;

our @EXPORT = qw(split_job);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub split_job {
    my $job = get_job_from_cts();

    ### $job
    return if not defined $job;
    my ($interlace, $type);
    if ( $job->{f_type} =~ /Interlaced/ ) {
        # 需要拉丝
        $interlace = 1;
        if ( $job->{fileType} == 1 ) {
            $type = 'BluRay';
        } else {
            $type = 'DVD';
        }
    } else {
        # 不拉丝
        $interlace = 0;
        if ( $job->{fileType} == 1 ) {
            $type = 'BluRay';
        } else {
            $type = 'DVD';
        }
    }

    ### $interlace
    ### $type
    split_job_into_db($job->{id}, $interlace, $type);
    update_db('task', 'status', 1, $job->{id});
}

sub split_job_into_db {
    my ($sid, $interlace, $type) = @_;

    # 根据 $subtitle, $interlace, $type
    # 找出转码 ID 所在范围

    ### $sid
    ### $interlace
    ### $type
    my @id;

    if ( $type eq 'DVD' ) {
        ## DVD Interlace 的先进行反拉丝
        ## 第二部再转码
        @id = qw(1 5 6)
    } else {
        if ( $interlace == 0) {
            @id = qw(41 45 46 47 48);
        } elsif ( $interlace == 1 ) {
            @id = qw(61 65 66 67 68);
        }
    }

    ### @id
    foreach my $script_id ( @id ) {
        insert_job_to_queue( $sid, $script_id );
    }
}

sub insert_job_to_queue {
    my ($sid, $script_id) = @_;
### $sid
### $script_id    
    my $task_info = get_task_info( $sid );
    
    my $source_file = $task_info->{pathName};
    my $output_path = generate_output_path( $source_file );
    my $script      = generate_script( $script_id, $source_file, $output_path );

    ### $script
    my $encode_type;
    if ( $script->[0] =~ /pass 1/) {
        $encode_type = 'onepass';
    } else {
        $encode_type = 'twopass';
        if ( $script->[0] =~ /750/ ) {
            $script->[0] =~ s{--pass\s+2}{};
        }
    }
    
    my $out_file = get_output_file( $script_id, $output_path );

    # 0000-00-00 00:00:00
    my $time = strftime("%Y-%m-%d %H:%M:%S", localtime(time));
    my $video_id = insert_into_video($sid, $out_file, $script_id, $time, $encode_type);
    insert_into_worker($sid, $video_id, $script, $encode_type);
}

sub generate_script {
    my ($script_id, $in_file, $output_path) = @_;

    my $encode = get_script_by_id($script_id);
    my $video  = get_video_options( $encode->{video_options} );
    my $audio  = get_audio_options( $encode->{audio_options} );

    # 输出文件先定义好
    # 需要多次用到
    # 周三修改
    my @script;
    my $video_script = string_transfer( $video, $in_file, $output_path );
    push @script, $video_script;
    if ( $encode->{name} =~ /onepass/ ) {
        my @audio_id = qw(1 2);
        my @audio_script = get_audio_cmd(\@audio_id, $in_file, $output_path);
        push @script, @audio_script;
        # 一次编码完成后添加音频转换
    } else {
        my $output_file = get_mp4_out_file($in_file, $video->{bitrate});
        my $merge_cmd = get_merge_cmd($in_file, $video->{bitrate}, $audio->{name}, $output_file );
        push @script, $merge_cmd;
    }

    return \@script;
}

sub string_transfer {
    my ($video, $in_file, $output_path ) = @_;

    my $encode_options = get_encode_str( $video->{options} );
    my $bluray     = $video->{bluray};
    my $filter     = $video->{filter};
    my $bitrate    = $video->{bitrate};
    my $subme      = $video->{subme};
    my $interlace  = $video->{interlace};    

    my $out_file;
    my $pass;
    if ( $video->{name} =~ /onepass/ ) {
        $out_file = '/dev/null';
        $encode_options =~ s{PASS_VALUE}{1};
    } else {
        my $out_tmp  = "video-${bitrate}k.h264";
        $out_file = "${output_path}/${out_tmp}";
        $encode_options =~ s{PASS_VALUE}{2};
    }

    # 参数替换
    $encode_options =~ s{INTERLANCE}{$interlace}e;
    $encode_options =~ s{BITRATE}{$bitrate}e;
    $encode_options =~ s{BLURAY}{$bluray}e;
    $encode_options =~ s{SUBME_VALUE}{$subme}e;
    $encode_options =~ s{FILTER}{$filter}e;
    $encode_options =~ s{OUTPUTFILE}{$out_file}e;
    $encode_options =~ s{INPUTFILE}{$in_file}e;

    if ( $bitrate == 368 ) {
    #if ( $bitrate == 6000 ) {
        $encode_options =~ s{--level 3.1}{--level 2.0 --profile baseline};
    }

    return $encode_options;
}

sub get_audio_cmd {
    my ($audio, $in_file, $output_path) = @_;

    my @tmp;
    foreach my $a_id ( @$audio ) {
        my $audio_options = get_audio_options($a_id);
        my $a_options     = $audio_options->{options};
        my $a_bitrate     = $audio_options->{name};
        my $out_file      = "audio-${a_bitrate}.aac";
        my $cmd = "FFMPEG_PROG -i $in_file $a_options -y ${output_path}/${out_file}";
        push @tmp, $cmd;
    }

    return @tmp;
}

sub get_merge_cmd {
    my ($infile, $v_bit, $a_bit, $output_file) = @_;

    my $fps = get_video_fps( $infile );
    my $output_path = generate_output_path( $infile );
    my $video = "${output_path}/video-${v_bit}k.h264";
    my $audio = "${output_path}/audio-${a_bit}.aac";
    unlink $output_file if -e $output_file;
    my $cmd = "MP4Box -fps $fps -add $video -add $audio $output_file";

    return $cmd;
}

sub get_mp4_out_file {
    my ($in_file, $bitrate) = @_;
    my $output_path = generate_output_path( $in_file );
    my $video_file  = "video-${bitrate}k.mp4";

    return "${output_path}/${video_file}";
}

sub get_job_from_cts {
    my $dbh = connect_database;

    my $data;
    ### $dbh
    for my $i ( reverse 0..3 ) {
        my $sql = qq{SELECT * FROM task where status=0 and priority=$i LIMIT 1};
        ### $sql
        $data = $dbh->selectrow_hashref( $sql );
        last if defined $data;
    }

    $dbh->disconnect;
    return $data;
}

sub get_output_file {
    my ($script_id, $output_path) = @_;

    my $script = get_script_by_id( $script_id );

    my $output_file;
    if ($script->{name} =~ /(\d+)/) {
        my $tmp = "video-${1}k.mp4";
        $output_file = "$output_path/$tmp";
    } else {
        $output_file = "/dev/null";
    }

    return $output_file;
}

1;
