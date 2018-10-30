#!/usr/bin/env perl

use strict;
use warnings;
use Smart::Comments;

use DBI;
use File::Find::Rule;
use YAML qw();
use FindBin;
use lib $FindBin::Bin;

our $options = do {
	local $/;
	my $data = <DATA>;
	YAML::Load($data);
};

# DB: cts
# table: video_backup
# create table video_backup(id int not null auto_increment primary key,filename varchar(100),md5 varchar(35) not null,size varchar(15),videoType varchar(15),fileType varchar(10),ip varchar(15),time TIMESTAMP DEFAULT NOW());

#my $logfile = './kidsvideofile.txt';
#my $logfile = './jlpvideofile.txt';

my ($videoID, $logfile) = @ARGV;
die "$0 [ videoID ] \n" if ( not $videoID );

if( not $logfile ){
	$logfile = `date +%Y%m%d`;
	chomp $logfile;
}
my ( $records, $rows) = get_videofile( $videoID );
### $rows
## $records
my $latestRecord;
if ( defined $rows and $rows > 0 ){
	$latestRecord = get_latest_video ( $records );
## $latestRecord
}

### $latestRecord

my ($videofile, $ip) = @$latestRecord;
## $videofile
## $ip
open my $fh, ">>", $logfile or die "Can't open $logfile: $!";
print $fh "$rows  ";
print $fh "$videoID  ";
print $fh "$ip  ";
print $fh "$videofile  ";
print $fh "\n";
close $fh;
exit 0;


## sub ##
sub get_latest_video {
	my ($records) = @_;
	my ( $latestTime, $latestRecord);

	foreach my $record ( @$records ){
		my ($backTime) = $record->[0] =~ /\/(201\d{5})\//;
		if ( not $latestTime ){
			$latestTime = $backTime;
			$latestRecord = $record;
		}else{
			if ( $backTime > $latestTime ){
				$latestTime = $backTime;
				$latestRecord = $record;
			}
		}
	}
	return $latestRecord;
}

sub get_videofile {
	my $videoID = shift;
	return if ( not $videoID );

	my $dbh = connect_cts_database( $options );
#my $sql_cmd = qq/SELECT md5,size,filename,ip FROM video_backup WHERE filename like "\%$videoID\%" AND fileType='source'/;
	#my $sql_cmd = qq/SELECT filename,ip FROM video_backup WHERE videoID='$videoID' AND fileType='source'/;
	my $sql_cmd = qq(select filename,ip from video_backup where fileType='encodeMp4' and videoID='$videoID' and filename like "\%video-1200k\%");

#my $data = $dbh->selectall_arrayref( $sql_cmd );
#my $data = $dbh->selectrow_arrayref( $sql_cmd );
	my $sth = $dbh->prepare( $sql_cmd );
	$sth->execute();
	my $rows = $sth->rows;
	my $records = $sth->fetchall_arrayref;

	return ( $records, $rows );
}

sub connect_cts_database {
	my $options = shift;
	my $dbinfo	= $options->{database};

	my $dbhost	= $dbinfo->{ip};
	my $dbport	= $dbinfo->{port} || 3306;
	my $dbuser	= $dbinfo->{user} || 'root';
	my $dbpass	= $dbinfo->{passwd} || '123456';
	my $dbname	= $dbinfo->{dbname};

	my $db	= "DBI:mysql:$dbname;host=$dbhost";
	my $dbh	= DBI->connect( $db, $dbuser, $dbpass,
				{
					RaiseError => 1,
				}
			) or die "Can't connect db: $DBI::errstr\n";
	return $dbh;
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
