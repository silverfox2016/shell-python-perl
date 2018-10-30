#!/usr/bin/perl

# table:cts.task
# status: 2转码完成 4视频上传完成 3截图完成
## table: cts.image  
## status 0:未处理 1:截图中 2:截图完成 3:上传完成 4:截出图片数量出错 5:图片花边 6:上传出错
##
# videoType 1纪录片 2电影 3动画片
# fileType 0和2是DVD 1蓝光

use strict;
use warnings;

$|=1; #关闭缓冲区

use Smart::Comments;
use YAML;
use FindBin;
use lib $FindBin::Bin;
use File::Find::Rule;
use File::Path;
use File::Basename;
use DBI;
use MIME::Lite;
use POSIX qw(strftime);

use VideoScreenshots;

## 监测截图进程是否已经存在,若存在即退出
#check_screenshot_alive();
#lekan_daemon();

our $options = do {
    local $/;
    my $data = <DATA>;
    YAML::Load($data);
};
our $outPath = "/cts/img/";
my $logFile = "/cts/img/log/screenshots.log";
my $logwork = "/cts/img/log/screenshotswork.log";

while ( 1 ) {
    my $dbh = connect_cts_database( $options );
    # 从cts.task表里面取得转码完成的视频 #
    #my $sql_command1 = "SELECT id,fileType,pathName FROM task WHERE status=2 LIMIT 0,1";
    my $sql_command1 = "SELECT id,fileType,pathName FROM task WHERE status=4 and pathName like '/cts/work/%' ORDER BY id DESC LIMIT 0,1";
    #my $sql_command1 = "SELECT id,fileType,pathName FROM task WHERE status=4  ORDER BY id DESC LIMIT 0,1";
    my $data1 = $dbh->selectrow_arrayref( $sql_command1 );
    # dbh->disconnect;

    my ($id, $fileType, $sourceFile);
    if ( not defined $data1 ) {
		print "INFO: not found task. \n";
		countdown(300);next;
		recordlog($logwork, "Not found task.");
		#exit 0;
    }else{
        $id = $data1->[0];
        $fileType = $data1->[1];
        $sourceFile = $data1->[2];
		recordlog($logwork, "Found task: $sourceFile");
    }
### $id
### $fileType
### $sourceFile
	my ($videoId, $drama) = $sourceFile =~ /\/(\d+)((?:E\d+)|M)/;
	my $videoIdDrama = $videoId.$drama;
    # 检查cts.image表中是否进行过截图 #
    # my $dbh = connect_cts_database( $options );
    my $sql_command2 = qq{SELECT id,outputPath,status FROM image WHERE fileName LIKE "\%$videoIdDrama\\\_\%" or fileName LIKE "\%$videoIdDrama\/\%" LIMIT 0,1};
    my $data2 = $dbh->selectrow_arrayref( $sql_command2 );
    $dbh->disconnect;
    ### $data2

    # inflag=2时，inVideo为转出MP4 #
    my ($inVideo, $inflag) = select_video( $sourceFile, $fileType);

    # 判断视频是否为纪录片 #
    my $videoType = get_video_type($videoId, $drama);
    ### $videoType

    ### $inVideo
    if ( defined $inVideo and -f $inVideo ){
        if ( not $data2 ){
            my $dbinh = connect_cts_database( $options );
            my $sth = $dbinh->prepare("INSERT INTO image(sourceId,fileName,videoType,fileType) VALUES (?, ?, ?, ?)");
            $sth->execute($id, $inVideo, $videoType, $fileType);
            ## $dbh->errstr
            $dbh->disconnect;
        }else{
            my $image_status = $data2->[2];
            my $image_path = $data2->[1];
            my $old_id = $data2->[0];
            if (( -f "$image_path/shot/5_230x130.jpg" ) && ( $image_status == 3 or $image_status == 2 )){
                #update_db("task", "status", 3, "id", "$id");
                #countdown(10);
                #next;
				print "重新截图\n";
                update_db("image", "sourceId", $id, "id", $old_id);
            }else{
                update_db("image", "sourceId", $id, "id", $old_id);
            }
        }
        ## status 1:截图中
        update_db("image", "status", 1, "sourceId", "$id");
        my ($status, $outImgPath);
		($status, $outImgPath) = cut_images( $inVideo, $sourceFile, $outPath, $fileType );
        ### first:$status
        if ( ($status == 5 or $status == 4) and $inflag == 2){
            update_db("image", "fileName", "$sourceFile", "sourceId", "$id");
			($status, $outImgPath) = cut_images( $sourceFile, $sourceFile, $outPath, $fileType );
            ### second:$status
        }
        if ( $status == 5 or $status == 4 ){
            update_db("image", "fileName", "mplayer:$inVideo", "sourceId", "$id");
			($status, $outImgPath) = mplayer_cut_image( $inVideo, $sourceFile, $outPath, $fileType );
            ### third:$status
            if ( ($status == 5 or $status == 4) and $inflag == 2 ){
                update_db("image", "fileName", "mplayer:sourceFile", "sourceId", "$id");
				($status, $outImgPath) = mplayer_cut_image( $sourceFile, $sourceFile, $outPath, $fileType );
                ### four:$status
            }
        }
        if ( $status == 5 or $status == 4 ){
            update_db("image", "fileName", "ffmpeg:$inVideo", "sourceId", "$id");
			($status, $outImgPath) = ffmpeg_cut_image( $inVideo, $sourceFile, $outPath, $fileType );
            ### five:$status
            if ( ($status == 5 or $status == 4) and $inflag == 2){
                update_db("image", "fileName", "ffmpeg:$sourceFile", "sourceId", "$id");
				($status, $outImgPath) = ffmpeg_cut_image( $sourceFile, $sourceFile, $outPath, $fileType );
                ### six:$status
            }
        }
        if ( $status == 5 or $status == 4 ){
			send_notify_mail("id:$id, outImgPath:$outImgPath, status:$status");
		}

        update_db("image", "outputPath", "$outImgPath", "sourceId", "$id");  
        update_db("image", "status", "$status", "sourceId", "$id");
        update_db("task", "status", 3, "id", "$id");

        &recordlog($logFile, "$videoIdDrama screenshots complate");
    }else{
        update_db("task", "status", 15, "id", "$id");
        &recordlog($logFile, "$videoIdDrama video not exist!");
    }
    countdown(20);
	`rm -f 000*.jpg`;
}
#exit 0;
# end while #

sub connect_cts_database {
    #my $cfg     = join '/', $FindBin::Bin, '..', 'etc', 'ctscfg.yaml';
    #my $options = load_config( $cfg );
    $options = shift;
    my $dbinfo = $options->{database};

    my $dbhost = $dbinfo->{ip};
    my $dbport = $dbinfo->{port} || 3306;
    my $dbuser = $dbinfo->{user} || 'root';
    my $dbpass = $dbinfo->{passwd} || '123456';
    my $dbname = $dbinfo->{dbname};

    my $db     = "DBI:mysql:$dbname;host=$dbhost";
    my $dbh    = DBI->connect( $db, $dbuser, $dbpass,
                               {
                                   RaiseError => 1,
                               }
                           ) or die "Can't connect db: $DBI::errstr\n";
    return $dbh;
}
sub update_db {
    my ($table, $key, $value, $bykey, $byvalue) = @_;

    my $dbh = connect_cts_database( $options );
    my $sql = qq{update $table set $key='$value' where $bykey=$byvalue};
### $sql
    my $rows_affected = $dbh->do( $sql );

    my $flag;
    if ( $rows_affected > 0 ) {
		print "更新表成功\n";
        $flag = 0;
    } else {
        $flag = 1;
    }
    return $flag;
}


# 若blueray首选1200k,不存在1200k则选择sourceVideo #    
# 若dvd首选sourceVideo，不存在sourceVideo则选择1200k #
sub select_video{
    my ($sourceFile, $fileType) = @_;
    my ( $inVideo, $inflag);
    if ( not $fileType ){
        $inVideo = $sourceFile;
        $inflag = 1;
    }elsif ( $fileType == 2 ){
        print "dvd\n";
        $inVideo = $sourceFile;
        $inflag = 1;
        if ( not -e $inVideo ){
            $inVideo = get_mp4_path( $sourceFile );
            $inflag = 2;
        }
    }elsif ( $fileType == 1 ){
        print "blueray\n";
        $inVideo = get_mp4_path( $sourceFile );
        $inflag = 2;    
        if ( not $inVideo || not -e $inVideo ){
            $inVideo = $sourceFile;
            $inflag = 1;
        }
    }
    # 排除对 .vob 文件截图 #
    if ( defined $inVideo and $inVideo =~ /\.vob/ ){
        $inVideo = get_mp4_path( $sourceFile );
        $inflag = 2;
    }
    return ($inVideo, $inflag);
}

sub get_mp4_path {
    my ($sourVideoPath, $type) = @_;
    my ($video_id, $drama) = $sourVideoPath =~ /\/(\d+)((?:E\d+)|M)/;
    my $mp4File = "/cts/out_video/";
    my $temp1 = $video_id % 1000;
    my $temp2 = $video_id % 100;

    $mp4File = $mp4File.$temp1."/".$temp2."/"."$video_id$drama";
    ### $mp4File
    my ($enMp4File, $cnMp4File);
    if ( not $type or $type == 1 ){
        $enMp4File = "$mp4File/en/video-1200k.mp4";
        $cnMp4File = "$mp4File/cn/video-1200k.mp4";
    } elsif ( $type == 2){
        $enMp4File = "$mp4File/en/video-900k.mp4";
        $cnMp4File = "$mp4File/cn/video-900k.mp4";
    }

    if ( -e $enMp4File ){
        return $enMp4File;
    }elsif ( -e $cnMp4File ) {
        return $cnMp4File;
    }else{
        return;
    }
}

sub send_notify_mail {
	my $str = shift;
    my $count = 0;
    while ( $count ++ < 5 ) {
        eval {
            my $date = strftime("%Y-%m-%d", localtime);
            my $msg = MIME::Lite->new(
                From     => 'xingxing.li@mail.lekan.com',
                To       => 'xingxing.li@mail.lekan.com',
                Subject  => "Video screenshot error from $date",
                Type     => 'text/html',
                Data     => $str,
            );

            $msg->send(
                'smtp',
                'smtp.ym.163.com',
                AuthUser => 'xingxing.li@mail.lekan.com',
                AuthPass => 'xingxing.li',
                Debug => 1,
            );
        };

        if ( not $@ ) {
            recordlog( $logFile, "send mail SUCCESS" );
            last;
        }
        recordlog( $logFile, "send mail FAIED", $@ );
    }
}

sub lekan_daemon {
    my ($pid, $sess_id, $i);

    if ( $pid = fork ) {
        exit 0;
    }

    Carp::croak "can't detach from controlling terminal"
          unless $sess_id = POSIX::setsid();

    $SIG{'HUP'} = 'IGNORE';

    if ( $pid = fork ) {
        exit 0;
    }

    chdir "/";
    umask 0;

    open(STDIN,  "<", "/dev/null");
    open(STDOUT, "<", "/dev/null");
    open(STDERR, "<", "/dev/null");
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

sub countdown{
	my $num = shift;
	print "\ncountdown: 00000";
	while( $num > 0 ){
		my $tmp = sprintf("%-5d",$num);
		print "\b\b\b\b\b$tmp";
		sleep 1;
		$num--;
	}
	print "\n";
}

sub check_screenshot_alive {

	my $proc=`ps aux 2>/dev/null |grep 'cts_screenshots.pl' |grep -v grep |wc -l`;
	chomp $proc;
	my $time=`date`;
	chomp $time;

	print $proc, "\n";
	if ( $proc <= 1 ){
		print "$time: proc not exists.","\n";
	}else{
		print "$time: proc alive.","\n";
		exit 0;
	}
	print "adf\n";
	#exit 0;
}

__DATA__
---
  database:
    hostname: '192.168.1.222'
    ip: 192.168.1.222
    port: 3306
    user: cts
    passwd: cts
    dbname: cts
