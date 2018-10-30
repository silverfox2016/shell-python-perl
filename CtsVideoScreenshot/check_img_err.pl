#!/usr/bin/env perl

use strict;
use warnings;
use DetectionImgBlackBorder;

my ($imgPath) = @ARGV;
die "input img path: $imgPath" unless( defined $imgPath && -d $imgPath );

my $status = checkMottlePicture( $imgPath );
my $isblack_screen = isBlackImgByPath( $imgPath );
if ( $status == 1  ){
	print "$imgPath    ";
	print "Cut out pictures of lace!!\n";
}
if ( $isblack_screen == 1 ){
	print "$imgPath    ";
	print "Cut out pictures of black screen!!\n";
}
if ( $status == 0 && $isblack_screen == 0 ){
	print "Cut out pictures of success!\n";
}

