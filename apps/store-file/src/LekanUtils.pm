package LekanUtils;

use POSIX qw(strftime);
use DBI;
use File::Basename;
use File::Path;
use MogileFS::Client;

use version;
use base qw(Exporter);

use FindBin;
use lib $FindBin::Bin;
use LekanConfig;

our $VERSION = v0.1;
our @EXPORT  = qw(get_local_ipaddr date hostname runlog get_server_status
                  scale_time_in_second write_log lekan_daemon 
                  generate_output_path get_file_md5 number_2_human_readable
                  connect_local_database connect_mogilefs_database
             );

# ip=`ifconfig |grep '192.168.0'|awk '{print $2}'|sed 's/addr://'`
sub get_local_ipaddr {
    open my $fh, '-|', '/sbin/ifconfig'
        or die "Can't open pipe: $!";

    while ( <$fh> ) {
        if ( /192\.168\./ ) {
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
    my @log_message = @_;

    my $file = $FindBin::Bin. '/../logs/upload-file.log';
    #    my $file = '/cts/cts-working.log';
    open my $fh, '>>', $file
	or die "Can't open $file: $!";

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



sub generate_output_path {
    my $filename = shift;
    
    my $basename = basename $filename;
    my ($video_id) = $basename =~ /((?:\d+)(?:M|E)(?:\d+)?)/;

    my ($id) = $video_id =~ /(\d+)(?:M|E)/;
    my ($v_id, $v_epis, $v_lang);

    my $last_path;
    if ( $basename =~ /M/) {
        ($v_id, $v_lang) = $basename =~ /(\d+M)_(\w+)/;
        $last_path = join '/', $v_id, $v_lang;
    } elsif ( $video_id =~ /E/ ) {
        ($v_id, $v_epis, $v_lang) = $basename =~ /(\d+E)(\d+)_(\w+)/;
        $last_path = join '/', "$v_id$v_epis", $v_lang;
    }

    my $path1 = $id % 1000;
    my $path2 = $id % 100;

    my $options = load_config( "$FindBin::Bin/../etc/cfg.yaml" );
    my $base_path = $options->{options}->{outputBasePath};

    my $working_dir = join '/', $base_path, $path1, $path2, $last_path;
    if (not -d $working_dir) {
        runlog(__PACKAGE__, '创建', $working_dir, '目录');
        mkpath $working_dir;
    }

    return $working_dir;
}

sub get_file_md5 {
    my $file = shift;

    ### 69: $file
    if (not -e $file) {
        print "File Not Exists.\n";
        return;
    }

    my $cmd = "md5sum $file 2>/dev/null";
    my $ret = `$cmd`;
    my $md5 = (split /\s+/, $ret)[0];

    return $md5;
}

sub number_2_human_readable {
    my $number = shift;

    # my $measure = {
    #     b => 1,
    #     k => 1024,
    #     M => 1024 * 1024,
    #     G => 1024 * 1024 * 1024,
    #     T => 1024 * 1024 * 1024 * 1024,
    # };

    if ( $number < 1024 ) {
        return sprintf("%.2fb", $number);
    }

    my $k = $number / 1024;
    if ( $k < 1024 ) {
        return sprintf("%.2fk", $k);
    }

    my $m = $k / 1024;
    if ( $m < 1024 ) {
        return sprintf("%.2fM", $m);
        return "${m}m";
    }

    my $g = $m / 1024;
    if ( $g < 1024 ) {
        return sprintf("%.2fG", $g);
    }

    my $t = $g / 1024;
    if ( $t < 1024 ) {
        return sprintf("%.2fT", $g);
    }

    return;
}
=pod
sub connect_mogilefs {
    my $domain = 'TS';
    my $hosts  = '60.209.3.35:7001';

    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => $domain,
                                                hosts  => [ $hosts ]
                                            ); };

        last unless $@;
        # 连接成功后退出
        sleep 10;
        runlog(__PACKAGE__, 'retry connect to mogilefs');
    }

    return $mogc;
}
=cut
sub connect_local_database {
    my $cfg     = join '/', $FindBin::Bin, '..', 'etc', 'cfg.yaml';
    my $options = load_config( $cfg );
    my $dbinfo = $options->{database};

    my $dbh   = connect_database( $dbinfo );
    return $dbh;
}

sub connect_mogilefs_database {
    my $config_file = join '/', $FindBin::Bin, '..', 'etc', 'cfg.yaml';
    my $options = YAML::LoadFile( $config_file );
    my $dbinfo = $options->{mogdatabase};

    my $dbh = connect_database( $dbinfo );
    return $dbh;
}

sub connect_database {
    my $dbinfo = shift;

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
        last if not defined $DBI::errstr;
        sleep 5;
    }

    return $dbh;
}

1;
