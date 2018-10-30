#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;
use File::Copy;
use File::Basename;

use FindBin;

use lib qw($FindBin::Bin);
use LekanConfig;
use LekanUtils;
use Database;
use GetVideoInfo;
use FindVideo;

#lekan_daemon();

while ( 1 ) {
    my $video = find_video();
    foreach my $task ( @$video ) {
        insert_into_task( $task );
    }

    sleep 3;
}
