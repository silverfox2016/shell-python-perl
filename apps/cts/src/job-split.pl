#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use lib $FindBin::Bin;
use Database;
use LekanUtils;
use LekanConfig;
use SplitJob;

#lekan_daemon();

while ( 1 ) {
    split_job();
    sleep 50;
}
