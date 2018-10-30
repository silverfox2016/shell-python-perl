package DeleteFile;

use strict;
use warnings;

use Smart::Comments;
use File::Find::Rule;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(delete_file);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub delete_file  {
    my $path = shift;

    my $rule = File::Find::Rule->new();
    $rule->file;
    $rule->name('*.aac', '*.log', 'video-*-c.mp4', '*.h264');

    my @files = $rule->in( $path );

    for my $file ( @files) {
        if ( $file !~ /video-(\d+)k\.mp4/ ) {
            runlog(__PACKAGE__, 'delete file:', $file);
            ### $file
            unlink $file;
        }
    }
}

1;
