package GenerateTask;

use strict;
use warnings;

use MogileFS::Client;
use JSON;
use Smart::Comments;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;

use version;
use base qw(Exporter);

our $VERSION = v0.1;
our @EXPORT  = qw(generate_task_msg);

sub generate_task_msg {
    my $key = shift;

    my $mogc = connect_mogilefs();
    my ($lang, $bitrate, undef) = get_bit_and_lang( $mogc, $key );
### $lang
### $bitrate
    my $ts_count = get_ts_count( $mogc, $key, $bitrate );
    my $mp4_368  = get_368k_count( $mogc, $key, $bitrate );

    my $key_info;
    for my $lang ( keys %$ts_count ) {
        $key_info->{$lang}{ts} = $ts_count->{$lang}{ts};
        $key_info->{$lang}{368} = $mp4_368->{$lang}{368};
    }

    my $info = {
        key       => $key,
        %$key_info,
    };

### $info
    return encode_json($info);
}

sub get_bit_and_lang {
    my ($mogc, $key) = @_;
    my $file = join "-", $key, 'videoinfo.xml';

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
            push @{$bitrate->{$language}->{bitrates}}, (split(/\|/, $_))[0] foreach @bit_detail;
        }
    }

    return ($lang, $bitrate, $url);
}

sub get_ts_count {
    my ($mogc, $key, $bitrates) = @_;
    my $hash;
    for my $lang ( keys %$bitrates ) {
       $hash->{$lang}{ts}{count} = count_ts($mogc, $key, $lang, '1200');
       $hash->{$lang}{ts}{bits} = $bitrates->{$lang}->{bitrates};
    }

### $hash
    return $hash;
}

sub count_ts {
    my ($mogc, $key, $lang, $bit) = @_;
    # 134780E1-en-1200k.mp4
    my $file = join "-", $key, $lang, "${bit}k.m3u8";
### $file

    my $fh   = $mogc->read_file( $file );

    my $ts_max_num = 0;
    # BUG: when file too big, this will eat all memory
    while ( <$fh> ) {
        s/\r\n//;
        if ( /ts$/ ) {
            my ($ts_max) = $_ =~ /(\d+)\.ts$/;
            $ts_max_num = $ts_max if $ts_max > $ts_max_num;
        }
    }

### $ts_max_num
    return $ts_max_num;
}

sub get_368k_count {
    my ($mogc, $key, $bitrates) = @_;
    my $hash;
    for my $lang ( keys %$bitrates ) {
       $hash->{$lang}{368}{count} = count_368k_mp4($mogc, $key, $lang, '368');
    }

    return $hash;
}

sub count_368k_mp4 {
    my ($mogc, $key, $lang, $bit) = @_;
    # 134780E1-en-368k.mp4
    my $file = join "-", $key, $lang, "${bit}k.mp4";
### $file
    my $mp4_info = $mogc->file_info( $file, {devices => 0});
    my $size = $mp4_info->{length};
    my $count = int($size / 1048576 + 2);

    return $count;
}
