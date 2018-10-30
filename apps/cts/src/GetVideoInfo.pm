package GetVideoInfo;

use strict;
use warnings;

use Smart::Comments;

use base qw(Exporter);

our @EXPORT = qw(get_subtitle get_video_type get_file_type
                 get_video_time get_video_interlaced get_video_fps
                 get_video_id_count);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub get_subtitle {
    my $file = shift;
    my $fh = open_command( $file );

    my $flag = 0;
    
    while ( <$fh> ) {
        if ( /Text/ ) {
            ### $_
            $flag = 1;
            last;
        }
    }

    # 0: no subtitle
    # 1: have subtitle
    close_command( $fh );
    return $flag;
}
  
sub get_file_type {
    my $file = shift;
    my $fh = open_command( $file );

    my $flag;
    
    while ( <$fh> ) {
        if ( /Width/ ) {
            s/\s+//g;
            ### $_
            my ($width) = $_ =~ /(\d+)/;
            if ( $width >= 1280 ) {
                $flag = 1;
            } elsif ( $width == 896 && $width == 720 or $width == 480 ) {
                $flag = 0;
            } else {
               $flag = 2;
            }
            last;
        }
    }

    # 0: DVD
    # 1: BluRay
    # 2: DVD
    close_command( $fh );
    return $flag;
}

sub get_video_type {
    my $file = shift;

    my $flag = 2;
    
    if ( $file =~ /E/ ) {
        $flag = 0;
    } elsif ( $file =~ /M/) {
        $flag = 1;
    }       

    # 0: Episode 剧集
    # 1: Movie 电影
    return $flag;
}

sub get_video_time {
    my $file = shift;
    my $fh = open_command( $file );

    my ($general, $video, $audio);
    while ( <$fh> ) {
        chomp;
        if ( /General/ .. /Duration/ ) {
            if ( /Duration/ ) {
                $general = (split(/:/, $_))[1];
                $general =~ s{(?:^\s+|\s+$)}{};
            }
        }
        
        if ( /Video/ .. /Duration/ ) {
            if ( /Duration/ ) {
                $video = (split(/:/, $_))[1];
                $video =~ s{(?:^\s+|\s+$)}{};
            }
        }
        
        if ( /Audio/ .. /Duration/ ) {
            if ( /Duration/ ) {
                $audio = (split(/:/, $_))[1];
                $audio =~ s{(?:^\s+|\s+$)}{};
            }
        }
    }

    ### $general
    ### $video
    ### $audio
    return ($general, $video, $audio);
}

sub get_video_interlaced {
    my $file = shift;

    # vob file does not have the Scan type
    return 'Interlaced' if $file =~ /vob$/;
    my $fh = open_command( $file );

    my $flag;
    while ( <$fh> ) {
        if ( /Scan type/ ) {
            chomp;
            ### $_
            $flag = (split(/:/, $_))[1];
            $flag =~ s{(?:^\s+|\s+$)}{};
# Scan type            
        }
    }
    
    close_command( $fh );
    return $flag;
}

sub get_video_id_count {
    my $file = shift;

    my $fh = open_command( $file );

    my $count = 0;
    while ( <$fh> ) {
        chomp;
        $count ++ if ( /^ID/ );
    }
    
    close_command( $fh );
    return $count;
}

sub get_video_fps {
    my $file = shift;

    open my $fh, '-|', "mediainfo $file"
        or die "Can't open command: $!";

    my $fps;
    while ( <$fh> ) {
        if ( /Frame rate\s+:/ ) {
            chomp;
	    ($fps) = $_ =~ /:\s+([\d\.]+)\s+(\(.*\)\s+)?FPS/;
	    print "$_ \n";
	    print "$fps \n";	
            $fps =~ s{(?:^\s+|\s+$)}{};
            last;
        }
    }
### $fps
    return $fps;
}

sub open_command {
    my $file = shift;

    open my $fh, '-|', "mediainfo $file"
        or die "Can't open command: $!";

    return $fh;
}

sub close_command {
    my $handle = shift;

    close $handle;
    return;
}


1;

__END__
三次打开文件 => 打开一次文件，然后把所有信息都取出来
放入 hash
