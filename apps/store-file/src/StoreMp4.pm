package StoreMp4;

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(store_file);
our @EXPORT_OK = qw();

our $VERSION = '0.02';

sub store_file {
    my ($pathfile, $sid) = @_;

    my $rsync_cmd = "rsync -avRP $pathfile 192.168.1.222:/lekan_video/video/";
    runlog(__PACKAGE__, "$rsync_cmd start");
    
    while (1) {
        my @ouput = `$rsync_cmd`;
        my $ret = $? >> 8;
        if ( $ret == 0 ) {
            runlog(__PACKAGE__, "$pathfile rsync success");
            last;
        }
        
        runlog(__PACKAGE__, "$pathfile retry rsync");
        sleep 30;
    }

    return 0;
}

1;
