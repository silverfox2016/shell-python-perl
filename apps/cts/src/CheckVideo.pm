package CheckVideo;

use strict;
use warnings;
#use Smart::Comments;

use FindBin;
use lib $FindBin::Bin;
use GetVideoInfo;
use LekanConfig;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(check_video_time  compare_source_out_video_time check_video_id_count);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub check_video_id_count {
    my $video_file = shift;

    my $id_count = get_video_id_count( $video_file );

    my $flag = 0;
    $flag = 1 if ( $id_count != 2 );

    return $flag;
}

# 转出视频自身的时间比对好后
# 然后对比和源视频的时间
# 一直才算转码完成
sub check_video_time{
    my $video_file = shift;
    unless ( -e $video_file ){
        runlog(__PACKAGE__, 'check_video_time', $video_file,  'not exist');
        return -1;
    }

    my ($general, $video, $audio) = get_video_time( $video_file );

    ### $general
    ### $video
    ### $audio
    $general = time_to_second( $general );
    $video   = time_to_second( $video );
    $audio   = time_to_second( $audio );
    ### $general
    ### $video
    ### $audio    
    my $f = $general - $video;
    my $s = $general - $audio;

    my $flag = 0;
    #if ( $f > 30 or $f < -30 or $s > 30 or $s < -30 ) {
    if ( $f > 40 or $f < -40 or $s > 40 or $s < -40 ) {
        runlog(__PACKAGE__, $video_file, 'video time has some problem');
        $flag = 1;
    }

    return $flag;
}

sub compare_source_out_video_time {
    my ($src_file, $out_file) = @_;
    my ($src_time, undef, undef) = get_video_time( $src_file );
    my ($out_time, undef, undef) = get_video_time( $out_file );
    
    ### $src_time
    ### $out_time
    $src_time = time_to_second( $src_time );
    $out_time = time_to_second( $out_time );

    ### $src_time
    ### $out_time
    my $step = $src_time - $out_time;

    my $flag = 0;
    if ( $step > 20 or $step < -20 ) {
        runlog(__PACKAGE__, $out_file, 'time is different from the source time');        
        $flag = 1;
    }

    return $flag;
}

sub time_to_second {
    my $time = shift;

    $time =~ s{\s+}{ }g;
    my ($f_time, $s_time) = split /\s+/, $time;

    ### $time
    ### $f_time
    ### $s_time
    my $total_second = 0;
    if ($f_time =~ /(\d+)h/) {
        $total_second += $1 * 60 * 60;
    } elsif ( $f_time =~ /(\d+)mn/ ) {
        $total_second += $1 * 60;
    } elsif ( $f_time =~ /(\d+)s/) {
        $total_second += $1;
    }

    if (defined $s_time) {
        if ( $s_time =~ /(\d+)mn/) {
            $total_second += $1 * 60;
        } elsif ( $s_time =~ /(\d+)s/ ) {
            $total_second += $1;
        }
    }

    ### $total_second
    return $total_second;
}

1;
