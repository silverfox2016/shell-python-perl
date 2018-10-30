package GetMp4;

use strict;
use warnings;

use Smart::Comments;

use LWP::Simple;

use File::Path qw(mkpath);
use FindBin;
use ConnectMogileFS;
use DBI;
use LekanUtils;

use base qw(Exporter);

our $VERSION = '0.01';

our @EXPORT = qw(getmp4);
our @EXPORT_OK = qw();

sub getmp4 {
    my $mogc = connect_mogilefs();
    my $logfile = "$FindBin::Bin/../logs/downlaod.log";
    my $dbh = connect_db();
    runlog($logfile, "开始启动getMP4");

### __PACKAGE__
    my $key = get_jobs($dbh);
    
    ### $key
    if ( not defined $key ) {
        runlog($logfile, "未获得任何任务");
        return;
    }
    
    runlog( $logfile,  "Got Job [ $key ]");
    
    my $gotkeys = get_mogilefs_keys($mogc, $key);
#    my $gotkeys = $mogc->list_keys( $key );
### $gotkeys
    my @gotmp4 = grep { /\.mp4/ } @$gotkeys;
### @gotmp4
    my @mp4;

    runlog($logfile, "$key: [ @gotmp4 ]");

    for ( @gotmp4 ) {
        my ($filekey) = split /-/, $_;
        push @mp4, $_ if $filekey eq $key;
    }

    my $all_mp4 = check_download_mp4( \@mp4 );
  
    my $video_path;
    for ( @$all_mp4 ) {
        my $get_url = get_mogile_url($mogc, $_);
        next if not defined $get_url;
        my ($video_id, $lang, $bitrate, $episcode, $type);
        if ( /^\d+M/ ) {
            ($video_id, $type, $lang, $bitrate) = $_ =~ m{^(\d+)(M)-(cn|en)-(\d+k)\.mp4};
        } elsif ( /^\d+E\d+/ ) {
            ($video_id, $type, $episcode, $lang, $bitrate) = $_ =~ m{^(\d+)(E)(\d+)-(cn|en)-(\d+k)\.mp4};
        } else {
            runlog($logfile, "Unknown type: $_");
            next;
        }
      
        my $first_path  = $video_id % 1000;
        my $second_path = $video_id % 100;
        my $video_name  = "$video_id$type";
        my $path        = join '/', $first_path, $second_path, $video_name;
        if (defined $episcode) {
            $path .= $episcode;
        }

        my $ts_base_dir = '/lekan_video/frag';
        my $lang_path = join '/', $ts_base_dir, $path, $lang;
        mkpath $lang_path if not -d $lang_path;

        $video_path = "$ts_base_dir/$path" if not defined $video_path;
        my $store_file = "$lang_path/video-$bitrate.mp4";

        while ( 1 ) {
            runlog($logfile, "start download $store_file from $get_url");
            my $ret = getstore($get_url, $store_file);
            print "$store_file succesed! [$ret] \n";
            last if ( $ret =~ /^2/ );
            sleep 30;
        }
        runlog($logfile, "finished download $store_file");
    }

    update_mp4task($key);
    return $video_path;
}

sub get_mogile_url {
    my ($mogc, $key) = @_;

    my @file_path = $mogc->get_paths( $key );

    my ($url) = grep { /192\.168\.1/ } @file_path;

    $url = $file_path[0] if not defined $url;
    return $url;
}

sub update_mp4task {
    my $key = shift;
    my $dbh = connect_db();
    my $sql = "update mp4task set status=1 where mogilekey='$key'";
    my $rows = $dbh->do($sql);
    
    if ( $rows > 0 ) {
        print "UPDATE OK!\n";
    } else {
        print "UPDATE FAILED!\n";
    }
    
    return;
}

sub check_download_mp4 {
    my $mp4 = shift;

    # 133777E15-cn-600k.mp4
    ### $mp4
    my @bitrate = qw(900 1200 1600 2500 4000);
    my %language = ( cn => 0, en => 0 );
    my $video_id;
    
    foreach ( @$mp4 ) {
        if ( /E/ ) {
            my ($video, $epis, $lang, $bit) = $_ =~ m{^(\d+)E(\d+)-(\w+)-(\d+)k\.mp4};
            $video_id = "${video}E${epis}" if not defined $video_id;
            $language{$lang}++;
        } elsif ( /M/ ) {
            my ($video, $lang, $bit) = $_ =~ m{^(\d+)M-(\w+)-(\d+)k\.mp4};
            $video_id = "${video}M" if not defined $video_id;
            $language{$lang}++;            
        }
    }

    my @all_mp4;
    for my $bit (@bitrate) {
        for my $lang (keys %language) {
            push @all_mp4, "$video_id-$lang-${bit}k.mp4";
        }
    }

    ### @all_mp4
    return \@all_mp4;
}

sub get_jobs {
    my $dbh = shift;

    while ( 1 ) {
        my $flag = judge_db( $dbh );
        last if ( $flag == 0 );
        sleep 200;
    }
    
    my @queue_priority = qw(10 9 8 7 6 5 4 3 2 0);
    for my $priority ( @queue_priority ) {
        my $sql = qq{SELECT mogilekey FROM mp4task WHERE status=0 and priority=$priority LIMIT 1};
        my $data = $dbh->selectrow_arrayref( $sql );
        if ( defined $data ) {
            my $key = $data->[0];
            return $key;
        }
    }

    return;
}

sub judge_db {
    my $dbh = shift;

    my $statement = "SELECT * FROM ts WHERE status=0 OR status=3";

    my $ref = $dbh->selectall_arrayref($statement);

    my $number = @$ref || 0;
### $number
    if ( $number > 30 ) {
        return 1; 
    } else {
        return 0;
    }
}

sub get_mogilefs_keys {
#    my $gotkeys = get_mogiles_keys($mogc, $key);
    my ($mogc, $key) = @_;

    my @keys;
    $mogc->foreach_key( 
		prefix => $key,  	
		sub { 
			my $key = shift; 
			push @keys, $key if $key =~ /mp4/;
		});

    return \@keys;	
}


1;
