package VideoScreenshots20140122;

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
use File::Find::Rule;
use File::Path;
use File::Basename;
use GD;
use GD::Image;
use IO::Handle;
use DBI;

use base qw(Exporter);
our @EXPORT = qw( cut_images mplayer_cut_image ffmpeg_cut_image get_video_type);

use DetectionImgBlackBorder;

use lib $FindBin::Bin;

our $logFile='/lekan/xing/screenshots.log';
#our $timeInterval = 60;
our $timeInterval = 2;

sub cut_images {
	my ($in_video, $source_video, $outPath, $fileType, $interval_sec) = @_;
	my ($video_id, $drama, $videoType, $img_path, $out_img_path, $xml_path, $out_xml_path);
	my ($rate, $per_min_frames);

	my $duration_sec = get_duration_sec( $in_video );
	adjust_interval_sec( $duration_sec );
	$rate = `mediainfo $in_video | grep "Frame rate" | grep -v mode`;
	chomp $rate;
	$rate =~ s/[^\d.]//g;
	$rate = 25 if ( not $rate );
	$per_min_frames = $rate * $timeInterval;
	$per_min_frames = $rate * $interval_sec if ( defined $interval_sec );
### $rate
### $per_min_frames

	($video_id, $drama) = $in_video =~ /\/(\d+)((?:E\d+)|M)/;
	$videoType = get_video_type( $video_id, $drama );
	($xml_path, $img_path) = get_xml_image_path( $video_id, $drama);
	$out_xml_path = $outPath.$xml_path;
	$out_img_path = $outPath.$img_path;

	if ( -d $out_img_path ){
		print "$out_img_path exist\n";
		remove_old_img($out_img_path);
	}else{
		system( "mkdir -p $out_img_path" );
		print "mkdir=$out_img_path\n";
	}
	if ( -e "$out_xml_path/screenshot_data.xml" ){
		print "rm=$out_xml_path/screenshot_data.xml \n";
		unlink "$out_xml_path/screenshot_data.xml";
	}

	CutOutImage_screenshot_img( $in_video, 230, 130, $out_img_path, $per_min_frames);
	if ( $drama =~ /E/ ){
		CutOutImage_screenshot_img( $in_video, 554, 314, $out_img_path, $per_min_frames);
		CutOutImage_screenshot_img( $in_video, 314, 224, $out_img_path, $per_min_frames);
		CutOutImage_screenshot_img( $in_video, 132, 92, $out_img_path, $per_min_frames);
		CutOutImage_screenshot_img( $in_video, 70, 48, $out_img_path, $per_min_frames);

	}
	elsif ( $drama =~ /M/ && $videoType == 1){
		CutOutImage_screenshot_img( $in_video, 640, 360, $out_img_path, $per_min_frames);
		my $duration_sec = get_duration_sec( $in_video );
### $duration_sec
		if ( defined $fileType && $fileType == 1 ){
			mplayer_documentary_iphone_screenshot_img( $source_video, 1280, 420, $duration_sec, $out_img_path);
		}else{
			mplayer_documentary_iphone_screenshot_img( $source_video, 640, 210, $duration_sec, $out_img_path);
		}
	}

	&create_xml( $out_xml_path );
	my $sta = &err_ret_img( $in_video, $out_xml_path);
	$timeInterval = 60;

	return ($sta, $out_xml_path);
}
sub CutOutImage_screenshot_img{
	my ($file_name, $widely, $highly, $img_path, $interval_frames) = @_;

	my $pixel = $widely.'x'.$highly;
	my $out_path = $img_path.'/'.$pixel.'/';
	system( "mkdir -p $out_path" );
	my $cmd = qq{/lekan/apps/ffmpeg/bin/CutOutImage $file_name $widely $highly $out_path $interval_frames};
	system( "$cmd" );
	&recordlog($logFile, "cmd: $cmd");

	mv_image( $img_path, $pixel);
    ## 实现该函数,perl中的rename
    ## rename 's/(\d+)/$1_$pixel/' "$imgPath/$pixel";
    ## `mv $outimgpath/*.jpg $imgPath`;
	return;
}

sub ffmpeg_cut_image {
	my ($in_video, $source_video, $outPath, $fileType) = @_;
	my ($video_id, $drama, $videoType, $img_path, $out_img_path, $xml_path, $out_xml_path);

	my $duration_sec = get_duration_sec( $in_video );
### $duration_sec
	($video_id, $drama) = $in_video =~ /\/(\d+)((?:E\d+)|M)/;
	$videoType = get_video_type( $video_id, $drama );
	($xml_path, $img_path) = get_xml_image_path($video_id, $drama);
	$out_xml_path = $outPath.$xml_path;
	$out_img_path = $outPath.$img_path;
### $img_path
### $xml_path

	if ( -d $out_img_path ){
		print "$out_img_path exist.\n";
		remove_old_img($out_img_path);
	}else {
		print "mkdir=$out_img_path\n";
		`mkdir -p $out_img_path`;
	}
	if ( -e "$out_xml_path/screenshot_data.xml" ){
		print "rm=$out_xml_path/screenshot_data.xml \n";
		unlink "$out_xml_path/screenshot_data.xml";
	}

	my ($cropWidth, $cropHeight, $srcWidth, $srcHeight) = calc_crop_param($in_video, $duration_sec);
	adjust_interval_sec( $duration_sec );
	ffmpeg_screenshot_img( $in_video, 230, 130, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
	if ( $in_video =~ /E/ ){
		ffmpeg_screenshot_img( $in_video, 554, 314, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		ffmpeg_screenshot_img( $in_video, 314, 224, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		ffmpeg_screenshot_img( $in_video, 132, 92, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		ffmpeg_screenshot_img( $in_video, 70, 48, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
	}
	elsif ( $in_video =~ /M/ && $videoType == 1 ){
		ffmpeg_screenshot_img( $in_video, 640, 360, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		if ( defined $fileType && $fileType == 1 ){
			ffmpeg_documentary_iphone_screenshot_img( $source_video, 1280, 420, $duration_sec, $out_img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight);
		}else{
			ffmpeg_documentary_iphone_screenshot_img( $source_video, 640, 210, $duration_sec, $out_img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight);
		}
	}

	&create_xml( $out_xml_path );
    my $sta = &err_ret_img( $in_video, $out_xml_path);
	$timeInterval = 60;

    return ($sta, $out_xml_path);
}

sub ffmpeg_screenshot_img{
	my ($file_name, $width, $height, $time_len, $img_path, $cropWidth, $cropHeight) = @_;
	my ($new_pic, $cmd);
	my $scale_param;

	my ( $ii, $time_offset);
	if ( $cropHeight <= 0 || $cropWidth <= 0 ){
        # $cmd = qq(ffmpeg -i $file_name -y -f image2 -ss $time_offset -vframes 1 -vf "scale=$width:$height" ${img_path}${ii}_${width}x${height}.jpg);
		$scale_param = qq(scale=$width:$height);
	} else {
		# $cmd = qq(ffmpeg -i $file_name -y -f image2 -ss $time_offset -vframes 1 -vf "crop=$cropWidth:$cropHeight,scale=$width:$height" ${img_path}${ii}_${width}x${height}.jpg);
		$scale_param = qq(crop=$cropWidth:$cropHeight,scale=$width:$height);
	}
	for( $time_offset=$timeInterval, $ii=1; $time_offset <= $time_len; $time_offset += $timeInterval, $ii++) {
		print "#### ii=$ii, time_offset=$time_offset \n";
        ($new_pic, $cmd) = ffmpeg_run_screenshot( $time_offset, $scale_param, $file_name);
        `mv -f $new_pic "$img_path/${ii}_${width}x${height}.jpg"`;

        # 检测图片是否花边，若花边则不在截图 #
	    if ( $ii == 5 ){
			my $status = checkMottlePicture ($img_path);
			last if ( $status == 1);
		}
    }
    &recordlog($logFile, "cmd: $cmd");
	return;
}

sub ffmpeg_documentary_iphone_screenshot_img{
    my ($file_name, $width, $height, $time_len, $img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight) = @_;
	my ($new_pic, $cmd);
	my $scale_param;

	my ($scaleWidth, $scaleHeight) = (0,0);
	$scaleWidth = $width;
	$scaleHeight = sprintf("%d", $height * $srcWidth / $srcHeight) if( $srcHeight > 0);
	# $scaleHeight = '-1';
	# $scaleHeight = '640:640*ih/iw';

	if ($cropWidth <= 0 || $cropHeight <= 0 ){
        # $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "scale=$width:$height" $file_name );
		$scale_param = qq(scale=$width:$height);
	} else {
        # $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "crop=$cropWidth:$cropHeight,scale=$scaleWidth:$scaleHeight,crop=$width:$height" $file_name );
		$scale_param = qq(crop=$cropWidth:$cropHeight,scale=$scaleWidth:$scaleHeight,crop=$width:$height);
	}
    my ($time_offset, $ii);
	for( $time_offset = $timeInterval, $ii=1; $time_offset <= $time_len; $time_offset += $timeInterval, $ii++ ){
		print "#### ii=$ii, time_offset=$time_offset \n";
		($new_pic, $cmd) = ffmpeg_run_screenshot( $time_offset, $scale_param, $file_name );
		`mv -f $new_pic "$img_path/${ii}_${width}x${height}.jpg"`;
	}
	&recordlog($logFile, "cmd: $cmd");
	return;
}

sub mplayer_cut_image {
	my ($in_video, $source_video, $outPath, $fileType) = @_;
	my ($video_id, $drama, $videoType, $img_path, $out_img_path, $xml_path, $out_xml_path);

	my $duration_sec = get_duration_sec( $in_video );
### $duration_sec
	($video_id, $drama) = $in_video =~ /\/(\d+)((?:E\d+)|M)/;
	$videoType = get_video_type( $video_id, $drama );
	($xml_path, $img_path) = get_xml_image_path($video_id, $drama);
	$out_xml_path = $outPath.$xml_path;
	$out_img_path = $outPath.$img_path;
### $out_img_path
### $out_xml_path

	if ( -d $out_img_path ){
		print "$out_img_path exist.\n";
		remove_old_img($out_img_path);
	}else {
		print "mkdir=$out_img_path\n";
		`mkdir -p $out_img_path`;
	}
	if ( -e "$out_xml_path/screenshot_data.xml" ){
		print "rm=$out_xml_path/screenshot_data.xml \n";
		unlink "$out_xml_path/screenshot_data.xml";
	}

	my ($cropWidth, $cropHeight, $srcWidth, $srcHeight) = calc_crop_param($in_video, $duration_sec);
	adjust_interval_sec( $duration_sec );
	mplayer_screenshot_img( $in_video, 230, 130, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
	if ( $in_video =~ /E/ ){
		mplayer_screenshot_img( $in_video, 554, 314, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		mplayer_screenshot_img( $in_video, 314, 224, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		mplayer_screenshot_img( $in_video, 132, 92, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		mplayer_screenshot_img( $in_video, 70, 48, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
	}
	elsif ( $in_video =~ /M/ && $videoType == 1 ){
		mplayer_screenshot_img( $in_video, 640, 360, $duration_sec, $out_img_path, $cropWidth, $cropHeight);
		if ( defined $fileType && $fileType == 1 ){
			mplayer_documentary_iphone_screenshot_img( $source_video, 1280, 420, $duration_sec, $out_img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight);
		}else{
			mplayer_documentary_iphone_screenshot_img( $source_video, 640, 210, $duration_sec, $out_img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight);
		}
	}

	&create_xml( $out_xml_path );
    my $sta = &err_ret_img( $in_video, $out_xml_path);
	$timeInterval = 60;

    return ($sta, $out_xml_path);
}

sub mplayer_screenshot_img{
    my ($file_name, $width, $height, $time_len, $img_path, $cropWidth, $cropHeight) = @_;
	my ($new_pic, $cmd);
	my $scale_param;

	my ($time_offset, $ii);
	if ( $cropHeight <= 0 || $cropWidth <= 0 ){
		# $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "scale=$width:$height" $file_name );
		$scale_param = qq(scale=$width:$height);
	} else {
		# $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "crop=$cropWidth:$cropHeight,scale=$width:$height" $file_name );
		$scale_param = qq(crop=$cropWidth:$cropHeight,scale=$width:$height);
	}
	for( $time_offset=$timeInterval, $ii=1; $time_offset <= $time_len; $time_offset += $timeInterval, $ii++ ){
		print "#### ii=$ii, time_offset=$time_offset \n";
		($new_pic, $cmd) = mplayer_run_screenshot( $time_offset, $scale_param, $file_name );
		`mv -f $new_pic "$img_path/${ii}_${width}x${height}.jpg"`;
	}
	&recordlog($logFile, "cmd: $cmd");
	return;
}

sub mplayer_documentary_iphone_screenshot_img{
    my ($file_name, $width, $height, $time_len, $img_path, $cropWidth, $cropHeight, $srcWidth, $srcHeight) = @_;
	my ($new_pic, $cmd);
	my $scale_param;

	my ($scaleWidth, $scaleHeight) = (0,0);
	$scaleWidth = $width;
	# $scaleHeight = sprintf("%d", $height * $srcWidth / $srcHeight) if( $srcHeight > 0);
    $scaleHeight = '-3';

	if ($cropWidth <= 0 || $cropHeight <= 0 ){
        # $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "scale=$width:$height" $file_name );
		$scale_param = qq(scale=$width:$height);
	} else {
        # $cmd = qq(mplayer -ss $time_offset -noframedrop -nosound -vo jpeg -frames $frames_num -vf "crop=$cropWidth:$cropHeight,scale=$scaleWidth:$scaleHeight,crop=$width:$height" $file_name );
		$scale_param = qq(crop=$cropWidth:$cropHeight,scale=$scaleWidth:$scaleHeight,crop=$width:$height);
	}
    my ($time_offset, $ii);
	for( $time_offset = $timeInterval, $ii=1; $time_offset <= $time_len; $time_offset += $timeInterval, $ii++ ){
		print "#### ii=$ii, time_offset=$time_offset \n";
		($new_pic, $cmd) = mplayer_run_screenshot( $time_offset, $scale_param, $file_name );
		`mv -f $new_pic "$img_path/${ii}_${width}x${height}.jpg"`;
	}
	&recordlog($logFile, "cmd: $cmd");
	return;
}

sub mplayer_run_screenshot {
	my ($off_time, $scale_param, $file_name) = @_;
	my ($new_pic, $cmd);

	my @imgs = glob("00*.jpg");
	foreach my $img ( @imgs ){
		unlink $img;
	}
	my $isblack_screen = 1;
	my $off_sec = $off_time;
	for( my $i=0; $i<30; $i++){
		$off_sec --;
		for(my $frames_num=2; $frames_num<50;$frames_num++){
			$cmd = qq(mplayer -ss $off_sec -noframedrop -nosound -vo jpeg -frames $frames_num -vf "$scale_param" $file_name);
			#`$cmd 2>&1 >/dev/null`;
			`$cmd`;
			if ( $?>>8 == 0 ){
				my @list = sort {
					my $n1 = $a =~ m{/\d+\.jpg};
					my $n2 = $a =~ m{/\d+\.jpg};
					$n1 <=> $n2;
				} glob("./00*.jpg");
				$new_pic = $list[-1];
			}
			my $pp = `pwd`;
			print $pp;
			$isblack_screen = isBlackImg( $new_pic );
			last if( $isblack_screen != 1 )
		}
		last if( $isblack_screen != 1 )
	}
	if ( $isblack_screen == 1 ){
		($new_pic, $cmd) = ffmpeg_run_screenshot($off_time, $scale_param, $file_name);
	}
	return ($new_pic, $cmd);
}

sub ffmpeg_run_screenshot {
	my ($off_time, $scale_param, $file_name) = @_;
	my $new_pic = $off_time.'temp.jpg';
	my $cmd = qq(/lekan/apps/mplayer/bin/ffmpeg -i $file_name -y -f image2 -ss $off_time -vf "$scale_param" -vframes 1 $new_pic);
### $cmd
	`$cmd`;
	return ($new_pic, $cmd);
}

sub remove_old_img {
	my $img_path = shift;
	return 1 unless( -d $img_path );
	my @imgs = glob("$img_path/*.jpg");
	foreach my $img ( @imgs ){
		unlink $img;
	}   
	return 0;
}

sub calc_crop_param {
	my ($file_name, $time_len) = @_;
	my ($srcWidth, $srcHeight, $cropWidth, $cropHeight) = (0,0,0,0);
	my ($leftEdge, $rightEdge, $topEdge, $bottomEdge) = (0,0,0,0);
	my ($new_pic, $cmd);
	my $scale_param;
	
	my $test_t = $time_len/2;
	return  if ( $test_t == 0 );
	# $cmd = qq(mplayer -ss $test_t -noframedrop -nosound -vo jpeg -frames $frames_num -vf "scale=" $file_name);
	$scale_param = qq(scale=);
	($new_pic, $cmd) = mplayer_run_screenshot( $test_t, $scale_param, $file_name );
	if ( -f $new_pic ){
		($leftEdge, $rightEdge, $topEdge, $bottomEdge) = detectionImgBlackborder( $new_pic );
		if ( $leftEdge + $rightEdge > 0 || $topEdge + $bottomEdge > 0 ){
			($srcWidth, $srcHeight) = getImgWidthHeight( $new_pic );
			$cropWidth = $srcWidth - $leftEdge - $rightEdge;
			$cropHeight = $srcHeight - $topEdge - $bottomEdge;
		}
		($cropWidth, $cropHeight) = (0, 0) if ($cropWidth < 0 || $cropHeight < 0);
	}
	return ($cropWidth, $cropHeight, $srcWidth, $srcHeight);
}

sub get_duration_min {
	my $video_file = shift;
	#my $duration = `mediainfo $video_file | grep "^Duration" | awk '{print $3$4$5}'| head -1`;
	my $duration = `mediainfo $video_file | grep "^Duration" | tr -d " Duration" | head -1`;
	chomp ( $duration );
### $duration
	my ($hour, $min, $sec);
	my $time_len = 0;
	if ( defined $duration ){
		($hour) = $duration =~ /(\d+)h/;
		($min) = $duration =~ /(\d+)mn?(?!s)/;
	}
	if ( defined $hour ){
		$time_len += $hour * $timeInterval;
	}
	if ( defined $min ){
		$time_len += $min;
	}
	return $time_len;
}

sub get_duration_sec {
	my $video_file = shift;
	my $duration = `mediainfo $video_file | grep "^Duration" | tr -d " Duration" | head -1`;
	chomp ( $duration );
### $duration
	my ($hour, $min, $sec);
	my $time_len = 0;
	if ( defined $duration ){
		($hour) = $duration =~ /(\d+)h/;
		($min) = $duration =~ /(\d+)mn?(?!s)/;
		($sec) = $duration =~ /(\d+)s/;
	}
	if ( defined $hour ){
		$time_len += $hour * 3600;
	}
	if ( defined $min ){
		$time_len += $min * 60;
	}	
	if ( defined $sec ) {
		$time_len += $sec;
	}
	return $time_len;
}


## 调节截图时间间隔,确保最少截图5张
sub adjust_interval_sec {
	my $time_sec = shift;
	return if ( not $time_sec || $time_sec == 0 );
	my $num = $time_sec / $timeInterval;
	$timeInterval = $time_sec / 5 if ( $num < 5 );
}

sub get_xml_image_path {
	my ($videoId, $drama) = @_;
	my ($imagePath, $xmlPath);
### $drama
	my $idLenth = length( $videoId );
	if ( $idLenth <= 2 ){
		$xmlPath = "$videoId";
		$imagePath = "$videoId/shot/";
	}else{
		my $idx = 0;
		while ( $idx < $idLenth ){
			$xmlPath .= substr( $videoId, $idx, 2);
			$xmlPath .= "/";
			$idx += 2;
		}
		if ( $drama =~ /E/){
			$xmlPath .= $drama;
			$xmlPath .= "/";
		}
		$imagePath .= $xmlPath."shot/";
	}
### $xmlPath
### $imagePath
	return ($xmlPath, $imagePath);
}

sub mv_image{
	my ($imgPath, $pixel) = @_;
	my $outimgpath = "$imgPath/$pixel";

	my @imgages = File::Find::Rule->file()
		->name('*.jpg')
		->in( $outimgpath);

	foreach my $tmp_img_name ( @imgages )
	{
		my $imgName = fileparse( $tmp_img_name, '.jpg');
		$imgName .= "_${pixel}.jpg";
### $imgName
		`mv $tmp_img_name "$imgPath/$imgName"`;
	}
	return;
}

sub create_xml {
	my $xmlPath = shift;
	my $xmlfile = $xmlPath.'screenshot_data.xml';

	open my $fh_in, ">>", $xmlfile or die "open screenshot_data.xml failed: $!\n";
	print $fh_in '<?xml version="1.0" encoding="UTF-8"?>'."\n".'<shot>'."\n".'<time>60</time>'."\n";

	my $num;
	if( -f "$xmlPath/shot/1_230x130.jpg" ){
		$num = `ls $xmlPath/shot/*_230x130.jpg | wc -l`;
		chomp $num;
	}else{
		$num = 0;
	}
	for (my $i=1; $i<=$num; $i+=1){
		print $fh_in '<pic time="10" file="shot/'.$i.'_230x130.jpg"/>'."\n";
	}
	print $fh_in '</shot>'."\n";
	close $fh_in;
	print "Created screenshot_data.xml end.\n";
	return;
}

sub err_ret_img {
	my ($videofile, $xmlPath) = @_;
	my ($img_num, $real_img_num, $diff_num);
	my $dura_time = get_duration_sec( $videofile );
	$img_num = $dura_time / $timeInterval;
	$real_img_num = `ls $xmlPath/shot/*_230x130.jpg | wc -l`;
	chomp $real_img_num;

### $dura_time
### $img_num
### $real_img_num
	if ( $img_num > $real_img_num ){
		$diff_num = $img_num - $real_img_num;
	}else{
		$diff_num = $real_img_num - $img_num;
	}
	print "$xmlPath/shot/ \n";

	my $status = 0;
	$status = checkMottlePicture( "$xmlPath/shot/" );
	my $isblack_screen = isBlackImgByPath( $xmlPath );
### $status
	if ( $status == 1 || $isblack_screen == 1 ){
		print "----------Cut out pictures of lace!!----------\n";
		&recordlog($logFile, "Cut out pictures of lace");
		return 5;
	}elsif ( $diff_num > 5 ){
		print "----------Cut out pictures number is wrong!!----------\n";
		&recordlog($logFile, "Cut out pictures number is wrong");
		return 4;
	}elsif ( $status == 0 ){
		print "----------Cut out pictures of success!----------\n";
		&recordlog($logFile, "Cut out pictures of success");
		return 2;
	}
	return 0;
}

# videoType 1纪录片 2电影 3动画片
sub get_video_type {
	my ($videoId, $drama) = @_;

	return 3 if ($drama =~ /E/);
	return 0 if( not $videoId );
	my $cmd1 = qq{curl -s -d "videoId=$videoId" "http://58.68.228.46:9006/app/impl?videoDocu"};
	my $ret = `$cmd1`;
	return 2 if ($ret eq 0);
	return 1 if ($ret eq 1);

	return 0;
}

sub recordlog {
    my ($file, @log_message) = @_;
### @log_message
    open my $fh, '>>', $file
        or return "Can't open $file: $!";

    print $fh scalar localtime;
    print $fh ' ';
    print $fh join ' ', @log_message;
    print $fh "\n";
}

1;
