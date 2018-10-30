package LekanConfig;

use strict;
use warnings;

use FindBin;

use YAML qw();

use version;
use base qw(Exporter);

our $VERSION = v0.1;
our @EXPORT  = qw(load_config get_config);

sub load_config {
    my $config_file = shift;

    my $config;
    eval {
        $config = YAML::LoadFile( $config_file );
    };

    if ( $@ ) {
        die "$@";
    } else {
        return $config;
    }
}

1;
