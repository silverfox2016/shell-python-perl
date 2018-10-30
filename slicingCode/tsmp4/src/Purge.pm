package Purge;

use strict;
use warnings;

use MogileFS::Client;
use Parallel::ForkManager;
use LWP::UserAgent;
use HTTP::Status;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(purge_cache);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

our @cache_servers = qw(
                        112.245.17.194
                        112.245.17.195
                        112.245.17.200
                        112.245.17.204
                        119.147.152.130
                        119.147.152.133
                   );
sub purge_cache {
    my ($id) = @_;
    ### $id
    return if ( $id !~ /(?:\d+)(?:M|E)(?:\d+)?/);

    purge_videoinfo($id);
    my $videoinfo = "$id-videoinfo.xml";
    my ($lang, $base_url, $bitrate) = get_videoinfo( $videoinfo );

    my $languages = lang_number_2_string( $lang );
    $base_url = change_purge_url( $id, $base_url );
    my $mp4 = purge_mp4( $base_url, $bitrate, $id );
    my ($flag, $purge_main_m3u8) = purge_m3u8( $id, $languages, $base_url );
    # if the main m3u8 is not found, then the url is not need to purge
    my $result = purge_ts( $base_url, $purge_main_m3u8 );

    return;
}

sub get_videoinfo {
    my $file = shift;

    my $mogc = connect_mogilefs();
    my $fh   = $mogc->read_file( $file );

    my ($lang, $url);
    my $bitrate;
    while ( <$fh> ) {
        chomp;
        if ( /vsound/ ) {
            ($lang) = $_ =~ m{<vsound>(.*?)</vsound>};
        } elsif ( /vurl/ ) {
            ($url)  = $_ =~ m{<vurl>(.*?)</vurl>};
        } elsif ( /v(cn|en)size/) {
            # <vcnsize>368|75936782,600|117749274,750|144767588,900|171800174,1200|235977420</vcnsize>
            my $line = $_;
            my ($language, $bit) = $line =~ m{<v(en|cn)size>(.*?)</v(?:en|cn)size>};
            my @bit_detail = split(/,/, $bit);
            push @{$bitrate->{$language}}, (split(/\|/, $_))[0] foreach @bit_detail;
        }
    }

    return ($lang, $url, $bitrate);
}

=p
sub purge_ts {
    my ($base_url, $m3u8s) = @_;

    my $mogc = connect_mogilefs();

    foreach my $slave_m3u8 ( @$m3u8s ) {
        my $fh   = $mogc->read_file( $slave_m3u8 );
        ### $slave_m3u8

        my ($language) = $slave_m3u8 =~ m{(?:\w+?)-(cn|en)-\d+k\.m3u8};
        ### $language
        my @ts;
        my $e_url = "$base_url/$language/video.ssm";
        ### $e_url
        while ( <$fh> ) {
            chomp;
            next if /^#/ or /^\s+$/ or /^$/;
            push @ts, "$e_url/$_";
        }

        lwp_get_url(\@ts);
    }

    return;
}
=cut
# Add by xianglong.meng
sub purge_ts {
    my ($base_url, $m3u8s) = @_;

    my $mogc = connect_mogilefs();

    foreach my $slave_m3u8 ( @$m3u8s ) {
        my $fh   = $mogc->read_file( $slave_m3u8 );
        ### $slave_m3u8

        my ($language) = $slave_m3u8 =~ m{(?:\w+?)-(cn|en)-\d+k\.m3u8};
        ### $language
        my @ts;
        my $e_url = "$base_url/$language/video.ssm";
        ### $e_url
        while ( <$fh> ) {
            chomp;
            next if /^#/ or /^\s+$/ or /^$/;
            push @ts, "$e_url/$_";
        }

        lwp_get_url(\@ts);
    }

    return;
}


sub purge_m3u8 {
    my ( $id, $lang, $e_url ) = @_;

    my ($videoid, $type, $idx) = $id =~ m{(\d+)(M|E)(\d+)?};

    my @m3u8s;
    my @m3u8_keys;
    my $mogc = connect_mogilefs();
    foreach my $language ( @$lang ) {
        my $m3u8 = "$id-$language-video.m3u8";
        my $b_url = "$e_url/$language/video.ssm";
        push @m3u8s, "$b_url/video.m3u8";
        my $fh = $mogc->read_file( $m3u8 );
        while ( <$fh> ) {
            chomp;
            if ( /^video-(\w+)\.m3u8$/ ) {
                push @m3u8s, "$b_url/$_";
                push @m3u8_keys, "$id-$language-$1.m3u8";
            }
        }
    }

    ## @m3u8s
    ## @m3u8_keys
    my $ret = lwp_get_url(\@m3u8s);

    return ($ret, \@m3u8_keys);
}

sub purge_mp4 {
    my ($base_url, $bitrate, $id) = @_;

    my @mp4_urls;
    my $mogc = connect_mogilefs();
    #    my $e_url = "$base_url/$language/video.ssm";
    foreach my $lang ( keys %$bitrate ) {
        for my $bit ( @{$bitrate->{$lang}} ) {
            my $e_url = "$base_url/$lang/video-${bit}k.mp4";
            push @mp4_urls, $e_url;
            if ( $bit == 368 ) {
                my $mog_key = "$id-$lang-${bit}k.mp4";
                my ($path) = $base_url =~ /(video.*)/;
                my $tmp_info = $mogc->file_info( $mog_key, {devices => 0} );
                my $size = $tmp_info->{length};
                my $count = $size / 1048576 + 2;
                my $tmp_url = "http://vod1.lekan.com/purge/filesplit?filename=$path/$lang/video-368k.mp4&filenum=";
                foreach my $index ( 1 .. $count ) {
                    push @mp4_urls, "${tmp_url}$index&blocksize=1048576";
                }
            }
        }
    }

    ### @mp4_urls;
    my $ret = lwp_get_mp4_url( \@mp4_urls );

    return;
}

sub change_purge_url {
    my ($id, $base_url) = @_;

    my ($videoid) = $id =~ m{(\d+)(?:M|E)};
    my $first = $videoid % 1000;
    my $second = $videoid % 100;

    my $e_url = "$base_url/$first/$second/$id";

    return $e_url;
}

sub lang_number_2_string {
    my $lang = shift;

    my @langs = ();
    if ( $lang eq '1' ) {
        push @langs, 'cn';
    } elsif ( $lang eq '2' ) {
        push @langs, 'en';
    } elsif ( $lang =~ /1(?:\s+)?,(?:\s+)?2/) {
        push @langs, 'cn', 'en';
    }

    return \@langs;
}

sub lwp_get_url {
    my $url = shift;

    my $conn_cache = LWP::ConnCache->new();
    my $ua = LWP::UserAgent->new( conn_cache => $conn_cache );

    my $not_found_count = 0;
    my $flag = 0;

    # http://61.174.18.3:9000/purge/video1/902/2/13902E40/cn/video.ssm/13902E40-cn-802-141.ts
    #    my @cache_servers = qw(113.105.147.131 113.105.147.132 113.105.147.135 113.105.147.130 60.209.4.38 60.209.4.35 61.174.18.131 124.207.162.208 221.203.3.97 221.203.3.96 61.155.138.2 61.155.138.3 120.199.8.220);
    foreach my $cdn ( @cache_servers ) {
        my $tmp_flag = 0;
        foreach my $cache_url ( @$url ) {
            ## $cache_url
            my $purge_url = $cache_url;
            $purge_url =~ s{http://([^/])+/}{"http://".${cdn}.":9000/purge/"}xe;
            my $req = HTTP::Request->new( GET => $purge_url );
            ### $purge_url
            #            last if $tmp_flag == 1;
            #            last if $not_found_count > 100;
            my $i = 0;
            while ( $i ++ < 30 ) {
                my $ret = $ua->request( $req );
                my $code = $ret->code;
				chomp $code;
                ### $code
                if ( $code == 404 and $purge_url =~ /video\.m3u8$/ ) {
                    $flag++;
                    $tmp_flag = 1;
                }
                $not_found_count++ if $code == 404;
				runPurgeLog($purge_url, $ret->is_success, $code);
                last if ( $code == 404 or $code == 200 );
                last if ( $ret->is_success );
                sleep 1;
            }
            if ( $i == 30 ) {
               runlog("purge failed ", $purge_url);
            }
        }
    }

    return $flag;
}

sub lwp_get_mp4_url {
    my $url = shift;

    my $conn_cache = LWP::ConnCache->new();
    my $ua = LWP::UserAgent->new( conn_cache => $conn_cache );

    my $not_found_count = 0;
    my $flag = 0;

    # http://61.174.18.3:9000/purge/video1/902/2/13902E40/cn/video.ssm/13902E40-cn-802-141.ts
    # my @cache_servers = qw(113.105.147.131 113.105.147.132 113.105.147.135 113.105.147.130 60.209.4.38 60.209.4.35 61.174.18.131 124.207.162.208 221.203.3.97 221.203.3.96 61.155.138.2 61.155.138.3 120.199.8.220);
    foreach my $cdn ( @cache_servers ) {
        my $tmp_flag = 0;
        foreach my $cache_url ( @$url ) {
            ## $cache_url
            my $purge_url = $cache_url;
            $purge_url =~ s{http://([^/])+/}{"http://".${cdn}.":9090/"}xe;
            my $req = HTTP::Request->new( GET => $purge_url );
            ### $purge_url
            #            last if $tmp_flag == 1;
            #            last if $not_found_count > 100;
            my $i = 0;
            while ( $i++ < 10 ) {
                my $ret = $ua->request( $req );
                my $code = $ret->code;
				chomp $code;
                ## $code
                if ( $code == 404 and $purge_url =~ /video\.m3u8$/ ) {
                    $flag++;
                    $tmp_flag = 1;
                }
                $not_found_count++ if $code == 404;
				runPurgeLog($purge_url, $ret->is_success, $code);
                last if ( $code == 404 or $code == 200 );
                last if ( $ret->is_success );
                sleep 1;
            }
            if ( $i == 30 ) {
               runlog("purge failed ", $purge_url);
            }
        }
    }

    return $flag;
}


sub purge_videoinfo {
    my $id = shift;
    my ($video_id) = $id =~ /(\d+)(?:M|E)/;
    my $p_f = $video_id % 1000;
    my $p_s = $video_id % 100;

    my @videoinfo_cache = qw(192.168.1.222);
    my $base_url = 'http://cache:10480/purge';
    my $path = join '/', $p_f, $p_s, $video_id, 'videoinfo.xml';
    my $purge_url = join '/', $base_url, $path;

    for my $c ( @videoinfo_cache ) {
        my $p_url = $purge_url;
        $p_url =~ s/cache/$c/e;
        ### $p_url
        my $ua = LWP::UserAgent->new();
        my $req = HTTP::Request->new( GET => $p_url );

        my $retry_count = 0;
        while ( $retry_count++ < 10 ) {
            my $ret = $ua->request( $req );
            last if ( $ret->is_success or $ret->code == 404 );
			runPurgeLog($p_url, $ret->is_success, $ret->code);
            select undef, undef, undef, 0.1;
        }
    }

    return;
}

sub runPurgeLog {
    my (@log_message) = @_;

    return if not @log_message;
    my $log_file = $FindBin::Bin. "/../logs/purge.log";
    open my $fh, '>>', $log_file
	or die "Can't open $log_file: $!";

    print $fh scalar localtime;
    print $fh ' ';
    print $fh join ' ', @log_message;
    print $fh "\n";

    return;
}

1;
