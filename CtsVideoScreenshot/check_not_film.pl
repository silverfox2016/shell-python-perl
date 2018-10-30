#!/usr/bin/perl
# videoType 1纪录片 2电影 3动画片

use strict;
use warnings;
use Smart::Comments;

#my ($n, $vid, $ip, $file)=@ARGV;
my $file = shift;

#my ($vid) = $file =~ /video(.+)shot/;
my ($vid) = $file =~ /\/(\d+)M/;
#$vid =~ s/\///g;

if ( $vid =~ /E/ ){
	print $file, "\n";
}else{
	my $videoId = $vid;
	my $cmd1 = qq{curl -s -d "videoId=$videoId" "http://58.68.228.46:9006/app/impl?videoDocu"};
	my $ret = `$cmd1`;
	chomp $ret;
	print $file, "\n" if ( $ret eq 1 );
## $ret
}


__END__

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


