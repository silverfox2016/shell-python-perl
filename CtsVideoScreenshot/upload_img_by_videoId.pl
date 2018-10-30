#!/usr/bin/env perl

use strict;
use warnings;
use Smart::Comments;

my $videoId=shift;
die "Input videoId (eg:133901M|133901E1):\n\n" unless ( defined $videoId );
die "Input videoId (eg:133901M|133901E1):\n\n" unless ( $videoId =~ /\d+M|(E\d+)/ );

my ($local_imgpath, $remote_imgpath) = get_img_path( $videoId );
### $local_imgpath
### $remote_imgpath

if ( -d $local_imgpath ) {
	print "rsync -avrP $local_imgpath 58.68.228.46:$remote_imgpath\n";
    check_remote_path($remote_imgpath);
	my $ret = `rsync -avrP $local_imgpath 58.68.228.46:$remote_imgpath`;
## $ret
	if ( $? == 0 ){	
		print "INFO: $videoId upload success \n";
	}else{
		print "ERR: $videoId upload error \n";
	}
}else{
	print "ERR: not found $local_imgpath \n";
}

# end run

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

sub get_img_path {
    my ($vid) = @_;
    my ($videoID, $drama) = $vid =~ /(\d+)(E\d+)?/;

    my $img_path = '/cts/img/';
    my $remote_path = '/lekan/content/video/';
    my $id_path;
    my $id_len = length ( $videoID );

    if ( $id_len <= 2 ){
        $id_path = $videoID;
    }else{
        my $idx = 0;
        while ( $idx < $id_len ){
            $id_path .= substr( $videoID, $idx, 2);
            $id_path .= '/';
            $idx += 2;
        }
    }
	$id_path .= $drama.'/' if ( defined $drama );
    #$id_path .= 'shot';
    $img_path .= $id_path;
    $remote_path .= $id_path;
    return ($img_path, $remote_path);
}

