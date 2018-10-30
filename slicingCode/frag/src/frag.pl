#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;

use File::Find::Rule;
use File::Path;
use File::Basename;
use File::Copy;

use FindBin;
use GetMp4;
use ConnectMogileFS;
use LekanUtils;

my $work_dir = $FindBin::Bin;
our $log_file = join '/', $work_dir, '../logs/frag.log';

#lekan_daemon();
chdir $work_dir;

while ( 1 ) {
### 'main'
    my $mp4_dir = getmp4();
    ### $mp4_dir
    if ( not defined $mp4_dir ) {
        runlog($log_file, "未获取到任务");
        sleep 300;
        next;
    }

    my $cn_path = "$mp4_dir/cn";
    my $en_path = "$mp4_dir/en";

    my @path = ($cn_path, $en_path);
    foreach my $mp4_path ( @path ) {
        next if not -d $mp4_path;
        my @mp4 = File::Find::Rule->file()
            ->name('*.mp4')
            ->in( $mp4_path );
        runlog( $log_file, "开始处理 $mp4_path" );

        my $video_ssm = "$mp4_path/video.ssm";
        mkpath $video_ssm if not -d $video_ssm;

        foreach my $mp4_file ( @mp4 ) {
            #next if $mp4_file =~ /900k/;
            gen_ismv( $mp4_file );
        }

        #gen_ism( $mp4_path );
        foreach my $type ( qw(ismc m3u8) ) {
            my $file = gen_other($mp4_path, $type);
            edit_m3u8( $file ) if ( $type eq 'm3u8' );
        }
    }

    my $xml = gen_videoinfo( $mp4_dir );
    insert_into_ts( $mp4_dir );
}

sub gen_ismv {
    my $mp4_file = shift;
    my $dirname  = dirname($mp4_file);

    my $basename = basename( $mp4_file );
    my $ismv_name = $basename;
    $ismv_name   =~ s{mp4$}{ismv};

    my $ismv     = join '/', $dirname, 'video.ssm', $ismv_name;

    runlog( $log_file, "/usr/local/bin/mp4split -o $ismv $mp4_file");
    `/usr/local/bin/mp4split -o $ismv $mp4_file`;

    my $ret = $? >> 8;
    if ( $ret == 0 ) {
        print "$mp4_file transfer to ismv successed.\n";
    } else {
        print "$mp4_file transfer to ismv failed: [ $ret ].\n";
        $ismv = undef;
    }

    return $ismv;
}

sub gen_ism {
    my $path = shift;

    my @ismv = glob("$path/video.ssm/*.ismv");
    my $arg  = join ' ', grep { /video-\d+k\.ismv/ } @ismv;

    runlog($log_file, @ismv);
    my $ism = "$path/video.ssm/video.ism";
    runlog($log_file, "/usr/local/bin/mp4split -o $ism '$arg'");
    `/usr/local/bin/mp4split -o $ism '$arg'`;

    my $ret = $? >> 8;
    if ( $ret == 0 ) {
        runlog($log_file, "$path 生成 ism 文件完成");
    } else {
        runlog($log_file, "$path 生成 ism 文件出错, 返回值: [ $ret ]");
        $ism = undef;
    }

    return "$ism";
}

sub gen_other {
    my ($path, $type) = @_;

    my @ismv = glob("$path/video.ssm/*.ismv");
    my $arg  = join ' ', grep { /video-\d+k\.ismv/ } @ismv;

    my $file;
    if ( $type eq 'ismc' ) {
        $file = "$path/video.ssm/video.ismc";
    } elsif ( $type eq 'm3u8' ) {
        $file = "$path/video.ssm/video.m3u8";
    }

    runlog($log_file, "/usr/local/bin/mp4split -o $file $arg");
    `/usr/local/bin/mp4split -o $file $arg`;

    my $ret = $? >> 8;
    if ( $ret == 0 ) {
        runlog($log_file, "$path 生成 $type 文件完成");
# 去掉最后面低码率配置
    } else {
        runlog($log_file, "$path 生成 $type 文件出错: [ $ret ]");
        $file = undef;
    }

    return $file;
}

sub gen_videoinfo {
    my $mp4_dir = shift;

    #    my $videoinfo_dir = '/data/download1/fms/lekann/videoinfo.lekan.com';
    my $videoinfo_dir = './';
    my ($video_id) = $mp4_dir =~ /(\d+(?:M|E)(?:\d+)?)/;
    my ($film_id, $episcode) = $video_id =~ /^(\d+)(?:M|E)(\d+)?$/;

    my $first_path  = $film_id % 1000;
    my $second_path = $film_id % 100;

    #  需要放到这个目录下面吗，如果直接存 mogilefs 的话
    #  是否可以存在当前目录下
    #   my $videoinfo_basedir = join '/', $videoinfo_dir, $first_path, $second_path, ;
    #	mkpath $videoinfo_basedir if not -d $videoinfo_basedir;
    my $videoinfo_xml     = join '/', $mp4_dir, 'videoinfo.xml';

    open my $fh, '>', $videoinfo_xml
        or die "Can't open $videoinfo_xml: $!";

    print $fh qq{<?xml version="1.0" encoding="UTF-8"?>\n<root>\n};

    my $cn_path = "$mp4_dir/cn";
    my $en_path = "$mp4_dir/en";

    my $video_file;
    my $sound_flag;
    if ( -d $cn_path ) {
        $sound_flag = 1;
        $video_file = "$cn_path/video-1200k.mp4";
        my $tmp_str = gen_info( $cn_path );
        print $fh join "\n", @$tmp_str;
    }
    
    if ( -d $en_path ) {
        $sound_flag = 2;
        $video_file = "$en_path/video-1200k.mp4";
        my $tmp_str = gen_info( $en_path );
        print $fh join "\n", @$tmp_str;
    }

    if ( -d $cn_path && -d $en_path ) {
        $sound_flag = '1,2';
    }

    my $time = get_video_time( $video_file );
    print $fh "<vsound>$sound_flag</vsound>\n";
    print $fh "<vtime>$time</vtime>\n";
    print $fh "<vid>$video_id</vid>\n";
    print $fh "<vurl>http://vod1.lekan.com/video1</vurl>\n";
    print $fh "</root>\n";

    close $fh;
    runlog($log_file, "生成 $videoinfo_xml");
    return $videoinfo_xml;
}

sub gen_info {
    my $path = shift;
    
    my @mp4 = File::Find::Rule->file()
        ->name('*.mp4')
        ->in( $path );

    my $type;
    if ( $path =~ /cn/ ) {
        $type = 'cn';	
    } elsif ( $path =~ /en/ ) {
        $type = 'en';
    } else {
        print "Unkonwn Language $path\n";
        exit;
    }

    my @video = qw(
                      video-900k.mp4
                      video-1200k.mp4
                      video-1600k.mp4
                      video-2500k.mp4
                      video-4000k.mp4
              );

    my $audio = {
        'video-900k.mp4'  => 96,
        'video-1200k.mp4' => 128,
        'video-1600k.mp4' => 128,
        'video-2500k.mp4' => 128,
        'video-4000k.mp4' => 128,
    };

    my @string;
    my @found_video;
    my %size;
    for my $video_bitrate ( @video ) {
        if ( grep { /$video_bitrate/ } @mp4 ) {
            my ($vbrate) = $video_bitrate =~ /^video-(\d+)k\.mp4$/;
            push @found_video, $vbrate;
            $size{$vbrate} = -s "$path/$video_bitrate";

            push @string, qq{<${type}_rate>\n<vrate>$vbrate</vrate>\n<arate>$audio->{$video_bitrate}</arate>\n</${type}_rate>};
        }
    }
    
    my $vbit =  "<v${type}size>";
    $vbit .= "$_|$size{$_}," foreach @found_video;
    $vbit =~ s{,$}{};
    $vbit .= "</v${type}size>\n";
    $vbit .= "<t${type}size></t${type}size>\n";
    push @string, $vbit;

    return \@string;
}

sub get_video_time {
    my $video_file = shift;

    open my $fh, '-|', '/usr/local/bin/mediainfo', $video_file
        or die "Can't open pipe: $!";

    my $time;
    while ( <$fh> ) {
        if ( /General/ .. /Duration/ ) {
            $time = (split(/:/, $_))[1] if /Duration/;
        }
    }

    chomp $time;
    $time =~ s{^\s+|\s+$}{}g;
    return $time;
}

sub insert_into_ts {
    my $dir = shift;

    my $dbh = connect_db();
    my $time = time;
    my $db   = 'ts';
    my $sth  = $dbh->prepare("INSERT INTO $db (status,path) VALUES (0, ?)");

    $sth->execute($dir)
        or warn runlog($log_file, "insert $dir to db failed", $dbh->errstr);

    return;
}

sub edit_m3u8 {
    my $file = shift;

    open my $in_fh, "<", $file
        or return 0;

    my $out_file = join '/', dirname($file ), 'tmp.m3u8';
    open my $out_fh, '>', $out_file
        or return 0;

    runlog($log_file, 'edit m3u8 file', $file, 'begin');
    my $video_info;
    while ( my $line = <$in_fh> ) {
        $line =~ s{BANDWIDTH=(\d+)\.?(\d+)?}{'BANDWIDTH='. $1 }xe;
        print $out_fh $line;
    }
    close $in_fh;
    close $out_fh;

    runlog($log_file, 'edit m3u8 file', $out_file, 'finished');
    move $out_file => $file;

    return 1;
}
