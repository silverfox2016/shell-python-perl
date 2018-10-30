#!/usr/bin/env perl

use strict;
use warnings;
use Smart::Comments;

my $videoID=shift;
my $listfile = $videoID;

if ( -f $listfile ){
    open my $fh, "<", $listfile or die "Can't open $listfile: $!";
    while (<$fh>){
        my $vid = $_;
        my $imgpath = get_img_path( $vid );
        print "$imgpath \n";
    }
    close $fh;
}else{
        my $imgpath = get_img_path( $videoID );
        print "$imgpath \n";
}


sub get_img_path {
    my ($vid) = @_;
    my ($videoID, $drama) = $vid =~ /(\d+)(E\d+)?/;

    my $img_path = '/cts/img/';
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
    $id_path .= 'shot';
    $img_path .= $id_path;
    return $img_path;
}

