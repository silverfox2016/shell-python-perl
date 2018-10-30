package Database;

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use File::Basename;
use YAML qw();

use base qw(Exporter);

use lib "$FindBin::Bin";
use LekanUtils;
use LekanConfig;

our @EXPORT = qw( update_db insert_into_backup close_db
                 insert_task_to_upload update_db);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub update_db {
    my ($table, $key, $value, $id) = @_;

### $table
### $key
### $value
### $id
    my $dbh = connect_local_database();
    my $sql = qq{update $table set $key='$value' where id=$id};

    my $rows_affected = $dbh->do( $sql );

    my $flag;
    if ( $rows_affected > 0 ) {
        runlog(__PACKAGE__, '更新表', $table, ':', $id, $key, '=>', $value, '成功');
        $flag = 0;
    } else {
        runlog(__PACKAGE__, '更新表', $table, ':', $id, $key, '=>', $value, '失败');
        $flag = 1;       
    }

    return $flag;
}

sub insert_into_backup {
    my ($ip, $filename, $md5, $size, $type) = @_;

    my $dbh = connect_local_database();
    my $sql = qq{INSERT INTO backup(ip, filename, md5, size, type) VALUES (?, ?, ?, ?, ?)};
    my $sth = $dbh->prepare( $sql );
    $sth->execute($ip, $filename, $md5, $size, $type);

    return;
}

sub insert_task_to_upload {
    my ($file, $sid) = @_;

    my $ip = '192.168.1.222';
    my $dbh = connect_local_database();
    my $sql = qq{INSERT INTO upload(ip,path,sourceId) VALUES (?, ?, ?)};

    my $sth = $dbh->prepare( $sql );
    $sth->execute($ip, $file, $sid);
    ### 25: $dbh->errstr
    $dbh->disconnect;
}

sub close_db {
    my $dbh = shift;

    $dbh->disconnect;
    return;
}

1;
