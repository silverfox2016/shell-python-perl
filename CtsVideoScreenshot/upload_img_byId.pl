#!/usr/bin/env perl

use strict;
use warnings;
use Smart::Comments;

use YAML;
use FindBin;
use DBI;

use lib $FindBin::Bin;

#lekan_daemon();

our $options = do {
	local $/;
	my $data = <DATA>;
	YAML::Load($data);
};

my $id = shift;
die "input image table id: $id \n" if ( not $id );

my $upload_img_log = "/cts/img/log/upload_img.log";

{
	my $dbh = connect_cts_database( $options );
	my $sql_command = "SELECT id,outputPath FROM image WHERE id=$id";
	my $data = $dbh->selectrow_arrayref( $sql_command );
	$dbh->disconnect;
	my ($id, $img_path, $remote_img_path);
	$remote_img_path = "/lekan/content/video/";
	if ( not defined $data ) {
		print 'sleep 300'."\n";
		sleep 300;
		next;
	}else{
		$id = $data->[0];
		$img_path = $data->[1];
	}
	my ($relative_path) = $img_path =~ /((?:\d+\/)+(?:E\d+\/)?)/;
	$remote_img_path .= $relative_path;
	my $video_ID = $relative_path;
	$video_ID =~ s/\///g;
### $id
### $img_path
### $relative_path
### $remote_img_path
### $video_ID

	my $status;
	if ( -d $img_path ) {
		print "cd $img_path && rsync -avRP * 58.68.228.46:$remote_img_path\n";
        check_remote_path($remote_img_path);
        `cd $img_path && rsync -avRP * 58.68.228.46:$remote_img_path`;
		if ( $? == 0 ){	
			$status = 3;
			&recordlog($upload_img_log, "$video_ID upload success");
		}else{
			$status = 6;
		}
	}else{
		$status = 6;
	}
### $status
	my $dbImageSta = &update_db("image", "status", "$status", "id", "$id");
### $dbImageSta


	print 'sleep 5'."\n";
	sleep 5;
}

# table: cts.image
# status 0:未处理 1:截图中 2:截图完成 3:上传完成 4:截出图片数量出错 5:图片花边 6:上传出错
#

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
	my $rows_affected = $dbh->do( $sql );

	my $flag;
	if ( $rows_affected > 0 ) {
		&recordlog($upload_img_log, '更新表', $table, ':', $bykey, $key, '=>', $value, '成功');
		$flag = 0;
	} else {
		&recordlog($upload_img_log, '更新表', $table, ':', $bykey, $key, '=>', $value, '失败');
		$flag = 1;
	}
### $flag
	return $flag;
}

sub check_remote_path{
	my $path = shift;
	`ssh 58.68.228.46 test -d $path`;
	my $ret = $?;
	unless ( $ret == 0 ){
		print "make remote dir: $path \n";
		`ssh 58.68.228.46 mkdir -p $path`;
	}
	return;
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



__DATA__
---
  database:
    hostname: '192.168.0.70'
    ip: 192.168.0.70
    port: 3306
    user: cts
    passwd: cts
    dbname: cts
