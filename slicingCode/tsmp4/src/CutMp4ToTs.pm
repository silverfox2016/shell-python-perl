package CutMp4ToTs;

use strict;
use warnings;

use Smart::Comments;

use File::Find::Rule;
use File::Basename;
use File::Path;
use File::Copy;

use FindBin;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(cut_ts);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub cut_ts {
    my $mp4_path = shift;

    runlog( "开始切割 ts: $mp4_path ");
    ### $mp4_path

    my @mp4_file = File::Find::Rule->file()
        ->name('*.mp4')
            ->in( $mp4_path );

    @mp4_file = grep { /video-\d+k\.mp4/ } @mp4_file;

    @mp4_file = sort { -s $a <=> -s $b } @mp4_file;
#    my $mp4s = filter_mp4( \@mp4_file );
    my $mp4s = \@mp4_file;
    ### $mp4s

    if (not defined $mp4s or not @$mp4s) {
        return 0;
    }
    my ($old_dir, $cur_dir);
    my ($g_bitrate, $g_mp4);
    my $main_m3u8;
    foreach my $file ( @$mp4s ) {
        ### $file
        my $dir = dirname($file);
        if ( not defined $g_bitrate ) {
            my $m3u8_file = "$dir/video.ssm/video.m3u8";
            if (not -e $m3u8_file) {
                runlog( "$m3u8_file is not exists");
                next;
            }
            ($g_bitrate, $g_mp4) = translate_bitrate($m3u8_file);
            ### $g_bitrate
        }
        my ($bitrate) = $file =~ /video-(\d+)k\.mp4/;

#        $bitrate = $g_bitrate->{$bitrate};
#        next if not defined $bitrate;
        my $ts_dir    = "$dir/ts/$bitrate";
        if (not -e $ts_dir) {
            mkpath $ts_dir
                or die "Can't mkdir $ts_dir: $!";
        }

        chdir $ts_dir
            or die "Can't chdir $ts_dir: $!";

        my ($video_id, $video_lang) = $dir =~ m{/([^/]+)/([^/]+)$};
        my $m3u8file   = "$ts_dir/$video_id-$video_lang-${bitrate}k.m3u8";
        # 文档上标注为 10s 一切
        #my $cmd = "/lekan/apps/bin/mp42ts --segment 40 --playlist $m3u8file $file ${video_id}-${video_lang}-$bitrate-%d.ts";
        my $cmd = "/sbin/mp42ts --segment 10 --segment-duration-threshold 100 --playlist $m3u8file $file ${video_id}-${video_lang}-$bitrate-%d.ts";
        #my $cmd = "/lekan/apps/bin/mp42ts --segment 5 --playlist $m3u8file $file ${video_id}-${video_lang}-$bitrate-%d.ts";
        runlog( $cmd);
        # $cmd
        `$cmd`;
        my $ret = $? >> 8;
        if ($ret == 0) {
            runlog( "切割 $file 成功");
            my $videoinfo_file = "$ts_dir/../../../videoinfo.xml";
            adjust_time_for_m3u8($m3u8file, $videoinfo_file);
        } else {
            runlog( "切割 $file 失败");
        }

        chdir $dir
            or die "Can't chdir $dir: $!";
        my $old_m3u8 = "$dir/video.ssm/video.m3u8";
        my $new_m3u8 = "$dir/ts/${video_id}-${video_lang}-video.m3u8";
        if ( -e $old_m3u8 and not -e $new_m3u8 ) {
	    edit_m3u8( $old_m3u8, $g_mp4 );
            copy $old_m3u8 => $new_m3u8
                or warn "61: $!";
        }
    }

    return 1;
}

sub translate_bitrate {
    my $m3u8_file = shift;

    open my $fh, '<', $m3u8_file
        or die "Can't open $m3u8_file";

    my @m3u8_bitrate;
    while ( <$fh> ) {
        print;
        chomp;
        next if /^$/ or /^#/;
        if ( /video-(\d+)k\.m3u8/ ) {
            push @m3u8_bitrate, $1;
        }
    }

    ### @m3u8_bitrate
    my @bitrate = qw(900 1200);

    my $number = scalar @m3u8_bitrate;

    if ( $number == 4 ) {
        push @bitrate, 1600, 2500;
    } elsif ( $number == 5 ) {
        push @bitrate, 1600, 2500, 4000;
    }

    my (%mp42m3u8, %m3u82mp4);

    @mp42m3u8{@bitrate} = @m3u8_bitrate;

    while( my ($k, $v) = each %mp42m3u8 ) {
        $m3u82mp4{$v} = $k;
    }

    return (\%mp42m3u8, \%m3u82mp4);
}

sub edit_m3u8 {
    my ( $file, $m3u82mp4 ) = @_;

    open my $in_fh, "<", $file
        or return 0;

    #    copy $file => "$file.orig";
    my $out_file = join '/', dirname($file ), 'tmp.m3u8';
    ### $out_file
    open my $out_fh, '>', $out_file
        or return 0;

    runlog('edit m3u8 file', $file, 'begin');
    my $video_info;
    while ( my $line = <$in_fh> ) {
        chomp $line;
        if ( $line =~ m{\A#EXT-X-STREAM-INF:PROGRAM-ID=\d,BANDWIDTH} ) {
            $video_info = $line;
        } elsif ( $line =~ m{\Avideo-(\d+)k\.m3u8\Z} ) {
            if ( reduce_bitrate($1) ) {
                ### 152: $video_info
                $video_info =~ s{BANDWIDTH=(\d+)}{'BANDWIDTH='. $1 * 1.5 }xe;
                ### 154: $video_info
            }
            print $out_fh "$video_info\n";

            ### $line
            ### $m3u82mp4
            my ($b) = $line =~ m{\Avideo-(\d+)k\.m3u8\Z};
            my $v = $m3u82mp4->{$b};
            ### $b
            ### $v
            $line =~ s{$b}{$v}ex;
            print $out_fh "$line\n";
        } else {
            print $out_fh "$line\n";
        }
    }
    close $in_fh;
    close $out_fh;

    # 158: 'debug'
    runlog('edit m3u8 file', $out_file, 'finished');
    # debug
    copy $out_file => "$file.orig";
    move $out_file => $file;

    return 1;
}

sub reduce_bitrate {
    my ($bitrate) = shift;

    ### 168: $bitrate
    if ( $bitrate >= 900 ) {
        return 1;
    }

    return 0;
}

sub filter_mp4 {
    my $mp4 = shift;

    ### $mp4
    # DVD 368, 600, 750, 900, 1200
    # BluRay 368, 600, 750, 900, 1200, 1600, 2500, [4000]
    if ( @$mp4 != 5 or @$mp4 != 8 or @$mp4 !=7 ) {
        return;
    }
    
    return $mp4;
}

# m3u8 里的时间可能比 videoinfo 里的时间长
sub adjust_time_for_m3u8 {
    my ($videoinfo, $m3u8) = @_;

    my $video_time = get_videoinfo_time( $videoinfo );
    ### 循环检测文件，直至时间相等
    while ( 1 ) {
        my $m3u8_time = get_m3u8_time($m3u8);
        my $time = compare_time($m3u8_time, $video_time);
        if ( $time > 0 ) {
            runlog('edit file', $m3u8, $time);
            change_time_for_m3u8($m3u8, $time);
        } else {
            last;
        }
    }
}

sub get_videoinfo_time {
    my $file = shift;

    open my $fh, '<', $file
        or die "Can't open $file: $!";

    my $time;
    while ( <$fh> ) {
        if (m{<vtime>(.*?)</vtime>}) {
            $time = $1;
            last;
        }
    }

    return 0 if not defined $time;

    my ($f_time, $s_time) = split /\s+/, $time;

    my $total_second = 0;
    if ($f_time =~ /(\d+)h/) {
        $total_second += $1 * 60 * 60;
    } elsif ( $f_time =~ /(\d+)mn/ ) {
        $total_second += $1 * 60;
    } elsif ( $f_time =~ /(\s+)s/) {
        $total_second += $1;
    }

    if (defined $s_time) {
        if ( $s_time =~ /(\d+)mn/) {
            $total_second += $1 * 60;
        } elsif ( $s_time =~ /(\d+)s/ ) {
            $total_second += $1;
        }
    }

    return $total_second;
}

sub get_m3u8_time {
    my $file = shift;

    open my $fh, '<', $file
        or die "Can't open $file: $!";

    my $time_sum = 0;
    while ( <$fh> ) {
        if ( /#EXTINF:(\d+),/) {
            $time_sum += $1;
        }
    }

    return $time_sum;
}

sub compare_time {
    my ($video_time, $m3u8_time) = @_;

    return $m3u8_time - $video_time;
}

sub change_time_for_m3u8 {
    my ($file, $time) = @_;

    open my $fh, '<', $file
        or die "can't open $file: $!";

    my $tmp_file = "$file.tmp";
    open my $out_fh, '>', $tmp_file
        or die "can't open $file: $!";

    my $flag = 1;
    my @data = reverse <$fh>;
    foreach ( @data ) {
        if ( $flag && /#EXTINF:(\d+),/m) {
            my $old_time = $1;
            if ( $old_time != 0 ) {
                ### $old_time
                ### $time
                if ( $old_time <= $time ) {
                    s/$old_time/0/;
                } else {
                    s/$old_time/$old_time-$time/e;
                }
                $flag = 0;
                ### 176: $_
            }
        }
        print $out_fh $_;
    }

    close $fh;
    close $out_fh;

    open my $o_fh, '>', $file
        or die "can't open $file: $!";

    open my $i_fh, '<', $tmp_file
        or die "can't open $file: $!";

    @data = reverse <$i_fh>;
    foreach ( @data ) {
        print $o_fh $_;
    }

    unlink $tmp_file;
    return;
}

1;
