#!/usr/bin/perl

# table:cts.task
# status: 2or4转码完成 15截图完成
## table: cts.image  
## status 0:未处理 1:截图中 2:截图完成 3:上传完成 4:截出图片数量出错 5:图片花边 6:上传出错
##
# videoType 1纪录片 2电影 3动画片
# fileType 0和2是DVD 1蓝光

use strict;
use warnings;

use Smart::Comments;
use FindBin;
use lib $FindBin::Bin;

#use VideoScreenshots;
use VideoScreenshots20140122;
use GetVideoInfo;

#our $outPath = "/cts/img/";
#my $logFile = "/cts/img/log/screenshots.log";
our $outPath='./';
my $logFile='./screenshots.log';

my ($sourceFile, $fileType) = @ARGV;
die "input video:$sourceFile \n" unless ( defined $sourceFile && -f $sourceFile );
my $inVideo = $sourceFile;
### $sourceFile

$fileType = get_file_type( $sourceFile ) if ( not $fileType );
### $fileType

my ($status, $outImgPath) = 0;
($status, $outImgPath) = mplayer_cut_image( $inVideo, $sourceFile, $outPath, $fileType );
### second:$status

