package DvdDeinterlace;

use strict;
use warnings;

use Smart::Comments;
use File::Path;
use File::Copy;

use base qw(Exporter);

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;
use GetVideoInfo;
use Database;

our @EXPORT = qw(deinterlace_dvd deinterlace);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub deinterlace_dvd {
    my $sid = shift;
    
    my $working_dir = get_work_dir( $sid );
    chdir $working_dir if defined $working_dir;

    my %file_info;
    my $source_file    = get_source_file( $sid );
    $file_info{source} = $source_file;
    $file_info{fps}    = get_video_fps( $source_file );
    $file_info{output_file} = 'video-6000k.mp4';
    $file_info{tmp_file} = 'video-6000k.h264';
    $file_info{audio_file} = 'audio-128k.aac';

### %file_info
    my $flag = deinterlace( \%file_info );

    # flag == 1, error
    # flag == 0, ok

    return $flag;
}

sub deinterlace {
    my $file_info = shift;
### $file_info

    my $flag = 1;

    my $f_ret = dvd_one_pass( $file_info );
    return $flag if $f_ret;

    my $s_ret = dvd_two_pass( $file_info );
    return $flag if $s_ret;

    my $m_ret = mp4_merge( $file_info );
    return $flag if $m_ret;

    my $r_ret = rename_file( $file_info );
    $flag = 0;

    return $flag;
}

sub dvd_one_pass {
    my $file_info = shift;

    my $mencoder = '/usr/local/bin/mencoder';
    my $file = $file_info->{source};
    my $f_cmd = qq{$mencoder $file -nosound -of rawvideo -vf pp=fd,harddup -mc 0 -noskip -ovc x264 -x264encopts pass=1:bitrate=6000:threads=0:weightp=1:bframes=6:frameref=6:aq_mode=1:aq_strength=1.0:rc_lookahead=50:trellis=0:deblock=-1,-1:b_adapt=0:direct_pred=spatial:cabac:subq=1:scenecut=40:me=dia:me_range=16:keyint_min=50:keyint=250:qp_min=10:qp_max=51:qp_step=4:qcomp=0.6:ip_factor=1.41:pb_factor=1.25:psy-rd=0.8,0.2:partitions=p4x4:chroma_me:no8x8dct:nomixed_refs:weight_b:nofast_pskip:noaud:nombtree:b_pyramid=0 -slang chi -o };

    my $ret = `$f_cmd`;
    my $flag = 0;
    if ( $? >> 8 ) {
        $flag = 1;
    }

    return $flag;
}

sub dvd_two_pass {
    my $file_info = shift;

    ### $file_info

    my $mencoder = '/usr/local/bin/mencoder';
    my $in_file = $file_info->{source};
    my $output  = $file_info->{tmp_file};
    my $s_cmd = qq{$mencoder $in_file -nosound -of rawvideo -vf pp=fd,harddup -mc 0 -noskip -ovc pass=2:bitrate=6000:threads=0:weightp=1:bframes=6:frameref=6:aq_mode=1:aq_strength=1.0:rc_lookahead=50:trellis=1:deblock=-1,-1:b_adapt=0:direct_pred=spatial:cabac:subq=9:scenecut=40:me=umh:me_range=16:keyint_min=50:keyint=250:qp_min=10:qp_max=51:qp_step=4:qcomp=0.6:ip_factor=1.41:pb_factor=1.25:psy-rd=0.8,0.2:partitions=p8x8,p4x4,b8x8,i8x8,i4x4:chroma_me:8x8dct:mixed_refs:weight_b:nofast_pskip:noaud:nombtree:b_pyramid=0:cplx_blur=20:qblur=0.5 -slang chi -o };

    my $ret = `$s_cmd`;
    my $flag = 0;
    if ( $? >> 8 ) {
        $flag = 1;
    }

    return $flag;
}

sub mp4_merge {
    my $file_info = shift;

    my $fps = $file_info->{fps};
    my $src = $file_info->{source};
    my $video = $file_info->{tmp_file};
    my $audio = $file_info->{audio_file};
    my $out   = $file_info->{output_file};

    my $ffmpeg = '/usr/local/bin/ffmpeg';
    my $mp4box = '/usr/local/bin/MP4Box';
    my $a_cmd = qq{$ffmpeg -i $src -vn -acodec libfaac -ab 128k -ac 2 -y $audio };
    `$a_cmd`;
    if ( $? >> 8 ) {
        return 1;
    }
    unlink $out;
    my $cmd = qq{$mp4box -fps $fps -add $video -add $audio $out};

    my $ret = `$cmd`;
    my $flag = 0;
    if ( $? >> 8 ) {
        $flag = 1;
    }

    return $flag;
}

sub rename_file {
    my $file_info = shift;
    my $dst_file = $file_info->{source};
    my $src_file = $file_info->{output_file};
    # bak up dst file
    my $dst_dir = '/cts/work/dvd/';
    #move $dst_file => $dst_dir;
    unlink $dst_file;
    move $src_file => "$dst_file";

    return;
}

sub get_work_dir {
    my $sid = shift;

    my $tmp = get_task_info( $sid );
    my $filename = $tmp->{pathName};

    my $working_dir = generate_output_path( $filename );

    return $working_dir;
}

1;

