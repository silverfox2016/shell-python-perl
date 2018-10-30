sub get_video_fps {
    my $file = shift;

    open my $fh, '-|', "mediainfo /cts/work/1000523E16_en.mp4"
    #open my $fh, '-|', "mediainfo /cts/work/1000576E2_en.mp4"
        or die "Can't open command: $!";

    my $fps;
    while ( <$fh> ) {
        if ( /Frame rate\s+:/ ) {
            chomp;
            ($fps,$ss) = $_ =~ /:\s+([\d\.]+)\s+(\(.*\)\s+)?FPS/;
            #$fps) = $_ =~ /:\s+([\d\.]+)\s+FPS/;
            print "$_ \n";
	    print "$fps\n";
            $fps =~ s{(?:^\s+|\s+$)}{};
            last;
        }
    }
### $fps
    return $fps;
	#print "$fps\n";
    }

get_video_fps()
