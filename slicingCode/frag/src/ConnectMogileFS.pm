package ConnectMogileFS;

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use YAML;
use DBI;
use MogileFS::Client;
use LekanUtils;

use base qw(Exporter);

our $VERSION = '0.01';
our @EXPORT = qw(connect_mogilefs connect_db);
our @EXPORT_OK = qw();

our $options = do {
    local $/;
    my $data = <DATA>;
    YAML::Load($data);
};

sub connect_mogilefs {
    my $domain = $options->{trackers}->{domain};
    my $hosts  = join ':', @{$options->{trackers}}{'host','port'};

    my $mogc = MogileFS::Client->new(  domain => $domain,
                                       hosts  => [ $hosts ]
                                   )
        or die "Can't connect $hosts: $!";

    return $mogc;
}

sub connect_db {
    my $logfile = "$FindBin::Bin/../logs/downlaod.log";
    my $dbinfo = $options->{database};
    runlog($logfile, $dbinfo->{ip});
    my $dbhost = $dbinfo->{ip};
    my $dbport = $dbinfo->{port} || 3306;
    my $dbuser = $dbinfo->{user} || 'root';
    my $dbpass = $dbinfo->{passwd};
    my $dbname = $dbinfo->{dbname};

    my $db     = "DBI:mysql:$dbname;host=$dbhost";
    my $dbh    = DBI->connect( $db, $dbuser, $dbpass,
                               {
                                   RaiseError => 1,
                               }
                           ) or die "Can't connect db: $DBI::errstr\n";

    return $dbh;
}

1;

__DATA__
---
  trackers:
    host: 192.168.1.222
    port: 7001
    domain: TS
    class: ts

  database:
    hostname: '192.168.1.222'
    ip: localhost
    port: 3306
    user: root
    passwd: ''
    dbname: sendfile
    
