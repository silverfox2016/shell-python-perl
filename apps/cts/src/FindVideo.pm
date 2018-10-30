package FindVideo;

use strict;
use warnings;

#use Smart::Comments;
use File::Find::Rule;
use File::Path;
use File::Copy;
use File::Basename;

use FindBin;
use lib $FindBin::Bin;
use LekanConfig;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(find_video);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub find_video {
    my $config_file = "$FindBin::Bin/../etc/ctscfg.yaml";
    my $options = load_config( $config_file );
    my $path = $options->{options}->{uploadPath};
    my $working_path = $options->{options}->{workingPath};

    mkpath $working_path if not -d $working_path;

    my $rule = File::Find::Rule->new();
    $rule->file;
    $rule->name('*.mkv', '*.mp4', '*.mpg', '*.mpeg', '*.vob', '*.avi', '*.mov', '*.MP4');

    my @files = $rule->in( $path );

    ### @files
    my %hash;
    for my $video_file ( @files ) {
        ### 40: $video_file
        my $flag = check_video_filename( $video_file );
        next if $flag;
        my $md5 = get_file_md5( $video_file );
        $hash{$video_file} = $md5;
    }

    ### 46:  %hash
    # 为防止文件未上传完就开始转码
    # 间隔 10 分钟计算同一个文件的 md5 值
    sleep 6;
    my @got_video;
    ### @got_video
    for my $video_file ( @files ) {
        ### $video_file
        my $md5 = get_file_md5( $video_file );
        ### $md5
        if ( $md5 eq $hash{$video_file} ) {
            my $basename = basename $video_file;
            my $path = join '/', $working_path, $basename;
            move $video_file => $path;
            push @got_video, $path;
            runlog(__PACKAGE__, 'got task video', $path);
        }
    }

    ### @got_video
    return \@got_video;
}

sub check_video_filename {
    my $file = shift;

    my $base_name = basename $file;
    my $id = (split(/\./, $base_name ))[0];

    my $flag = 1;
    if ( $id =~ /^\d+(?:M|E)(\d+)?_(?:cn|en)$/ ) {
        $flag = 0;
    }

    return $flag;
}

1;
