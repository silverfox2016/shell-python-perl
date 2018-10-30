package RemoveChapter;

use strict;
use warnings;

use Smart::Comments;

use base qw(Exporter);

use LekanUtils;

our $VERSION = '0.01';

our @EXPORT = qw(remove_chapter);
our @EXPORTER = qw();

sub remove_chapter {
    my $file = shift;

    return if not defined $file or not -f $file;

    my $cmd_name = "/usr/local/bin/mp4chaps";
    my $flag = 0;
    
    my $has_chapter = find_chapter($file);
    if ( $has_chapter ) {
        `$cmd_name -r $file`;
        my $ret = $? >> 8;

        if ( $ret == 0 ) {
            runlog(__PACKAGE__, "$file remove chapter success");
        } else {
            runlog(__PACKAGE__, "$file remove chapter failed");
            $flag = 1;
        }
    }

    return $flag;
}

sub find_chapter {
    my $file = shift;
    my $chapter = `/usr/local/bin/mediainfo $file 2>/dev/null |grep 'Menu'`;

    my $ret = 0;
    if ( $chapter ne '' ) {
        $ret = 1;
    }

    return $ret;
}

1;
