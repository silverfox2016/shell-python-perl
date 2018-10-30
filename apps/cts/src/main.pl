#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;
use Worker;

#lekan_daemon();
while ( 1 ) {
    worker();
    sleep 3;
}
