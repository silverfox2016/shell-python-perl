package Database70;

use strict;
use warnings;
use DBI;
#use Smart::Comments;

use base qw(Exporter);

our @EXPORT = qw(open_db_70 close_db_70 get_task_from_db_70);
our @EXPORT_OK = qw();

sub open_db_70 {
    my $dbhost = '218.241.129.62';
    my $dbport = '12306';
    my $dbuser = 'cts';
    my $dbpass = 'cts';
    my $dbname = 'cts';

    my $db     = "DBI:mysql:$dbname;host=$dbhost;port=$dbport";
    my $dbh;
    while ( 1 ) {
        $dbh = DBI->connect( $db, $dbuser, $dbpass,
                               {
                                   RaiseError => 1,
                               }
                           );
        if ( $DBI::errstr ) {
            sleep 10;
            next;
        }
        last;
    }
    return $dbh;
}


sub close_db_70 {
    my $dbh = shift;
    $dbh->disconnect;
}

sub get_task_from_db_70 {
    my ($dbh, $vid) = @_;
    my $statement = "SELECT  pathName FROM task where pathName like '%$vid%' order by id desc limit 1";

    my $ref = $dbh->selectrow_arrayref($statement) || ();

### $ref
    return $ref;
}

1;
