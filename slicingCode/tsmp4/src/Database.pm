package Database;

use strict;
use warnings;

#use Smart::Comments;

use base qw(Exporter);

our @EXPORT = qw(open_mogilefs_db close_mogilefs_db
            insert_data_into_db get_task_from_db update_db judge_db);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub open_mogilefs_db {
    my $dbhost = 'localhost';
    my $dbport = 3360;
    my $dbuser = 'root';
    my $dbpass = '';
    my $dbname = 'sendfile';

    my $db     = "DBI:mysql:$dbname;host=$dbhost";
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

sub insert_data_into_db {
    my ($dbh, $table, $column, $value) = @_;

    my $sql = qq{INSERT INTO $table ($column) VALUES (?)};
    my $sth = $dbh->prepare( $sql );

    $sth->execute( $value );

    if ( $dbh->errstr ) {
        runlog(__PACKAGE__, 'insert into', $table, $column, $value, 'failed');
        return 0;
    }

    return 1;
}

sub close_mogilefs_db {
    my $dbh = shift;
    $dbh->disconnect;
}

sub get_task_from_db {
    my $dbh = shift;
    my $statement = "SELECT id,path FROM ts WHERE status=0 order by id desc limit 1";

    my $ref = $dbh->selectrow_arrayref($statement) || ();

### $ref
    return $ref;
}

sub update_db {
    my ($dbh, $table, $id, $column, $value) = @_;

    my $sql = qq{update $table set $column=? where id=?};
    my $sth = $dbh->prepare( $sql );

    $sth->execute( $value, $id );

    if ( $dbh->errstr ) {
        runlog(__PACKAGE__, 'update', $table, $id, $column, $value, 'failed');
        return 0;
    }

    return 1;
}

sub judge_db {
    my $dbh = shift;
    
    my $sql = qq{SELECT * FROM ts WHERE status=0};
    my $ref = $dbh->selectall_arrayref($sql);
    my $number = scalar @$ref;

    if ( $number > 100 ) {
        return 1; 
    } else {
        return 0;
    }
}

1;
