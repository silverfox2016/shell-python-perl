package LekanUtils;

use POSIX qw(strftime);

use DBI;
use YAML;
use MogileFS::Client;
use POSIX;
use LekanConfig;
use version;
use base qw(Exporter);

our $VERSION = v0.1;
our @EXPORT  = qw(ip_addr date hostname runlog get_server_status
                  scale_time_in_second write_log lekan_daemon
                  connect_mogilefs connect_database);

# ip=`ifconfig |grep '192.168.0'|awk '{print $2}'|sed 's/addr://'`
sub ip_addr {
    open my $fh, '-|', '/sbin/ifconfig'
        or die "Can't open pipe: $!";

    while ( <$fh> ) {
        if ( /192\.168\.0/ ) {
            ($ip) = (split)[1];
            $ip =~ s/addr://;
            return $ip;
        }
    }

    return undef;
}

sub date {
    return strftime("%Y%m%d", localtime);
}

sub hostname {

}

sub runlog {
    my (@log_message) = @_;

    return if not @log_message;
    my $log_file = $FindBin::Bin. "/../logs/tsmp4_run.log";
    open my $fh, '>>', $log_file
	or die "Can't open $log_file: $!";

    print $fh scalar localtime;
    print $fh ' ';
    print $fh join ' ', @log_message;
    print $fh "\n";

    return;
}
sub write_log {
    my ($type, @log_message) = @_;

    $type = lc $type;
    my $log_type = {
        runlog => '',
        warn   => 'WARN',
        error  => 'ERROR',
        fatal  => 'FATAL',
        debug  => 'DEBUG',
    };

    my $logtype = exists $log_type->{$type}
        ? $log_type->{$type} : 'UNKNOWN LOG TYPE';
    return $logtype, " @log_message\n";
}

sub get_server_status {
    my $url = shift;

    my $ua         = LWP::UserAgent->new();
    my $request    = HTTP::Request->new( GET => $url );
    my $response   = $ua->request( $request );

    my $rep_content = $response->content();

    return $rep_content || '0';
}

sub scale_time_in_second {
    my $time = shift;

    my $ret_time;
    my ($number) = $time =~ m{(\d+)};
    if ( $time =~ /ms/ ) {
        $ret_time = $number / 1000;
    } elsif ( $time =~ /s|S/ ) {
        $ret_time = $number;
    } elsif ( $time =~ /(m|mn)/ ) {
        $ret_time = $number * 60;
    } elsif ( $time =~ /H|h/ ) {
        $ret_time = $number * 60 * 60;
    } elsif ( $time =~ /D|d/ ) {
        $ret_time = $number * 60 * 60 * 60;
    } elsif ( $time =~ /W|w/ ) {
        $ret_time = $number * 7 * 60 * 60 * 60;
    }

    return $ret_time;
}

sub lekan_daemon {
    my ($pid, $sess_id, $i);

    if ( $pid = fork ) {
        exit 0;
    }

    Carp::croak "can't detach from controlling terminal"
          unless $sess_id = POSIX::setsid();

    $SIG{'HUP'} = 'IGNORE';

    if ( $pid = fork ) {
        exit 0;
    }

    chdir "/";
    umask 0;


    open(STDIN,  "<", "/dev/null");
    open(STDOUT, "<", "/dev/null");
    open(STDERR, "<", "/dev/null");
}

sub connect_database {
    my $cfg     = join '/', $FindBin::Bin, '..', 'etc', 'cfg.yaml';
    my $options = load_config( $cfg );
    my $dbinfo = $options->{database};

    my $dbhost = $dbinfo->{ip};
    my $dbport = $dbinfo->{port} || 3306;
    my $dbuser = $dbinfo->{user} || 'root';
    my $dbpass = $dbinfo->{passwd} || '123456';
    my $dbname = $dbinfo->{dbname};

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

sub connect_mogilefs {
    my $config_file = join '/', $FindBin::Bin, '..', 'etc', 'cfg.yaml';
    my $options = YAML::LoadFile( $config_file );

    my $domain = $options->{trackers}->{domain};
    my $hosts  = join ':', @{$options->{trackers}}{'host','port'};

    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => $domain,
                                                hosts  => [ $hosts, ],
                                            );
                    };
        if ( $@ ) {
            sleep 10;
            runlog(__PACKAGE__, 'retry connect to mogilefs');
            next;
        }
        last;
    }

    return $mogc;
}

1;
