#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;
use FindBin;
use lib $FindBin::Bin;
use Worker;
use LekanUtils;

#lekan_daemon();

store_worker();
