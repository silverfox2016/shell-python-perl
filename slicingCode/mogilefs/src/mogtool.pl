#!/usr/bin/perl

use strict;
use warnings;

use Smart::Comments;

use FindBin;
use MogileFS::Client;
use List::AllUtils qw(uniq);

use Getopt::Long;
use YAML qw();
use File::Basename;

our $options = {};

GetOptions(
    $options,
    'help|h|?',                 # help
    'id|i=i',                   # 视频的 ID
    'info!',                    # file information
    'check|c!',                 # 查看剧集是否缺少 ts
    'content!',                 # 取出文件内容，仅限于 m3u8 文件
    'episcode|e=s',             # 指定的剧集
    'type|t=s',                 # video type 'E|M'
    'prefix|p=s',               # key's prefix
    'list|l!',                  # list keys
    'lang=s',                   # language
    'key|k=s@',                 # 指定 key
    'device|dev=s',             # dev
    'delete|rm|del!',           # delete
    'store|st|s!'               # store file
) or die usage();

unless (%$options) {
    usage();
    exit 1;
}

if ( $options->{help} ) {
    usage();
    exit 1;
}

my $mogc = mogilefs_connect();

my @all_keys;
my ($file_lost, $ts_one);
if (exists $options->{key}) {
    push @all_keys, @{ $options->{key} };
} else {
    my ($prefix, $err_str) = generate_prefix( $options );
    if ( defined $err_str ) {
        print $err_str;
        exit 1;
    }

# 根据 videoinfo.xml 里的内容
# 找到主的 m3u8 文件
# 取出主 m3u8 文件里的所有从属 m3u8 文件，并取出它们的内容 @m3u8_content
# 根据前缀取出以该前缀的所有文件 @all_m3u8
# 在 @all_m3u8 文件查找每个 @m3u8_content

    for my $video_prefix ( @$prefix ) {
        my $file_videoinfo = get_videoinfo( $mogc, $video_prefix );

        my $m3u8 = generate_m3u8($video_prefix, $file_videoinfo);
        my ($m3u8_content, $m3u8_file, $lack_m3u8) = get_content_from_m3u8( $mogc, $m3u8 );
        if ( @$lack_m3u8 > 0 ) {
            print "$video_prefix 缺少以下文件: ";
            print join "\t", uniq(@$lack_m3u8);
            print "\n";
            next;
        }

        my $mogilefs_ts  = get_ts_from_mogilefs( $mogc, $video_prefix );
        my @mp4 = grep { chomp; /\.mp4/ } @$mogilefs_ts;
        my @xml = grep { chomp; /\.xml/ } @$mogilefs_ts;
        my @f4m = grep { chomp; /\.f4m/ } @$mogilefs_ts;
        push @all_keys, @$m3u8_content, @$m3u8_file, @mp4, @xml, @f4m;

        if ( exists $options->{check} ) {
            ($file_lost, $ts_one) = check_intergity($mogc, \@all_keys);
        }
    }
}

if ( exists $options->{check} ) {
	if ( @$file_lost ) {
		print "缺少以下文件:\n";
		print join "\n", @$file_lost;
	}

	if ( @$ts_one ) {
		print "以下文件只有一份:\n";
		print join "\n", @$ts_one;
	}

	unless ( @$file_lost ) {
		print "\n", $options->{prefix}, " 文件完整\n";
	}
}

if (exists $options->{list} ) {
    print join "\n", @all_keys;
    print "\n";
} elsif ( exists $options->{info} ) {
    foreach ( @all_keys ) {
        get_file_info( $mogc, $_ );
    }
} elsif ( exists $options->{content} ) {
    foreach ( @all_keys ) {
        get_file_content( $mogc, $_ );
    }
} elsif ( exists $options->{delete}) {
    for my $key ( @all_keys ) {
        my ($ret_value, $error) = delete_keys( $mogc, $key );
        if ( $ret_value eq 'error' ) {
            print "Delete $key failed: $error\n";
        } elsif ( $ret_value eq 'ok') {
            print "Delete $key ok\n";
        }
    }
} elsif ( exists $options->{store} ) {
    for my $key ( @all_keys ) {
        my $ret_value= store_keys( $mogc, $key );
        if ( $ret_value ) {
            print "Store $key failed: $ret_value\n";
        } else {
            print "Store $key ok\n";
        }
    }
}

sub usage {
    print <<"EOF";
usage: $0 -i number -t type -e from-to
help h ?      help                     bool
id i          视频的 ID                number
info          显示视频信息             bool
check c       查看剧集是否缺少 ts      bool
content       查看文件内容             bool
episcode e    指定的剧集               number 1,5-7,10-12
type t        视频类型 E(剧集) M(电影) char
prefix p      文件前缀                 string
list l        列出文件                 bool
lang          视频语言                 cn/en
key k         指定文件的 key           string
device dev    文件存储位置             string
delete rm del 删除文件                 bool
store  st s   存储文件                 bool
EOF

    exit 1;
}

sub mogilefs_connect {
    my $mogilefs_configfile = $FindBin::Bin . '/../etc/mogilefs.yaml';
    my $mogilefs_options = load_config( $mogilefs_configfile );

    my $domain = $mogilefs_options->{trackers}->{domain};
    my $hosts  = join ':', @{$mogilefs_options->{trackers}}{'host','port'};

    my $mogc = MogileFS::Client->new(
        domain => $domain,
        hosts  => [ $hosts ]
    ) or die "Can't connect $hosts: $!";

    return $mogc;
}

sub generate_m3u8 {
    my ($prefix, $key) = @_;

    my @m3u8 = ();

    if ( $key eq '1' ){
    	push @m3u8, "$prefix-cn-video.m3u8";
    } elsif ( $key eq '2' ){
    	push @m3u8, "$prefix-en-video.m3u8";
    } elsif ( $key eq "1,2" ){
    	push @m3u8, "$prefix-cn-video.m3u8", "$prefix-en-video.m3u8";
    }

    return \@m3u8;
}

sub generate_prefix {
    my $options = shift;

    my $prefix = [];

    if ( exists $options->{prefix}) {
        push @$prefix, $options->{prefix};
    } else {
        my $id   = $options->{id};
        my $type = lc $options->{type};
        my $epis = $options->{episcode};


        if ( $type eq 'e' or $type eq 'episcode' ) {
            $type = 'E';
        } elsif ( $type eq 'm' or $type eq 'movie' or $type eq 'film' or $type eq 'f' ) {
            $type = 'M';
        } else {
            my $err_str =<<EOF;
Can't recongise video type: $type
You can only choose: M for movie or E for episcode
EOF
            return ([], $err_str);
        }

        my $vprefix = "$id$type";

        if ( $type eq 'M' ) {
            return [ $vprefix ];
        }

        my @range = split(/,/, $epis);
        foreach ( @range ) {
            my ($from, $to) = split(/-/, $_);
            $to = $from if (not defined $to);
            for my $index ( $from .. $to ) {
                my $epis_prefix = join '', $vprefix, $index;
                push @$prefix, $epis_prefix;
            }
        }
    }

    return $prefix;
}

sub check_intergity {
    my ($mogc, $ts) = @_;
    my (@lack_ts, @ts_count_1);
    foreach my $each_ts ( @$ts ) {
        my $flag = file_exists($mogc, $each_ts);
        my ($exists, $count) = file_exists($mogc, $each_ts);
        unless ( $exists ) {
            push @lack_ts, $each_ts;
        } else {
            push @ts_count_1, $each_ts if $count < 2;
        }
    }

    return (\@lack_ts, \@ts_count_1);
}

sub file_exists {
    my ($mogc, $key) = @_;

    my $info = $mogc->file_info( $key,{ devices => 0 } );

    my ($ret, $count) = (0, 0);
    if (defined $info) {
        $ret = 1;
        $count = $info->{devcount};
    }

    return ($ret, $count);
}

sub get_content_from_m3u8 {
    my ($mogc, $key) = @_;

    my @all_ts    = ();
    my @all_nonts = ();
    my @lack_m3u8 = ();
    my $flag = 0;
    foreach my $file ( @$key ) {
        my $content = $mogc->get_file_data( $file );

        if ( not defined $content) {
            push @lack_m3u8, $file;
            next;
        }

        push @all_nonts, $file;
        my $m3u8 = filter_m3u8( $content );
        my ($m3u8_prefix) = $file =~ /(.*?)-video\.m3u8/;
        my @all_m3u8 = map {
            my $key = join  '-', $m3u8_prefix, $_;
            $key =~ s{-video}{}g;
            $key;
        } @$m3u8;

        for my $each_m3u8 ( @all_m3u8 ) {
            my $ts = $mogc->get_file_data( $each_m3u8 );
            if ( not defined $ts ) {
                push @lack_m3u8, $each_m3u8;
                next;
            }
            my $ts_file = filter_m3u8( $ts );
            if ( defined $ts_file ) {
                 push @all_ts, @$ts_file;
                 push @all_nonts, $each_m3u8;
            }
        }
    }

    push @lack_m3u8, 'video.m3u8' if ($flag == 2);
    return (\@all_ts, \@all_nonts, \@lack_m3u8);
}

=item filter_m3u8($str);

  将 m3u8 文件里的注释和空行的数据过滤掉

=cut

sub filter_m3u8 {
    my $arg = shift;
    my @content = split /\n/, $$arg;

    my @need_content;
    for ( @content ) {
        tr/\015//d;
        next if ( /^#/ or /^$/ );
        s{^\./}{};
        push @need_content, $_;
    }

    return \@need_content;
}

=item get_ts_from_mogilefs($mogc, $key_prefix)

  从 MogileFS 取出指定前缀的文件

=cut

sub get_ts_from_mogilefs {
    my ($mogc, $key_prefix) = @_;

    $key_prefix .= '-' if ( $key_prefix =~ m{\d$} );

    my @whole = ();
    $mogc->foreach_key(
        prefix => $key_prefix,
        sub {
            my $key = shift;
            push @whole, $key;
        }
    );

    return \@whole;
}

=item compare_ts($array_ref1, $array_ref2)

 对比数组元素，查抄第二个数组中有，且在第一个数组中没有的元素

=cut

sub compare_ts {
    my ($mogilefs_ts, $m3u8_ts) = @_;

    chomp for @$mogilefs_ts;
    my @lacked;
    foreach my $ts ( @$m3u8_ts ) {
        unless ( grep { /$ts/ } @$mogilefs_ts ) {
            push @lacked, $ts;
        }
    }

    return \@lacked;
}

=item get_file_data($mogc, $key)

  获取指定 $key 的相关信息

=cut

sub get_file_info {
    my ($mogc, $key) = @_;

    my $info   = $mogc->file_info( $key,
                                   {
                                       devices => 0 },
                               );
    my @path = $mogc->get_paths( $key );
    my %path_hash = map { ; "http_path$_"  => $path[$_] }  0..$#path;
    # 添加分号使括号成块
    return unless (keys %path_hash);
    $info = {
        %$info,
        %path_hash,
    };
    print YAML::Dump( $info );
}

sub get_file_content {
    my ($mogc, $key) = @_;
    my $file_info = $mogc->get_file_data( $key );

    if ( $key !~ /\.(m3u8|xml)$/ ) {
        print "不支持的文件格式，暂时只支持获取 m3u8 和 xml 的文件内容\n";
        return;
    }
    if (defined $file_info){
        print "\nfile: $key\n\n";
        print $$file_info, "\n";
    }
}

sub get_videoinfo {
    my ($mogc, $key) = @_;

    my $videoinfo_xml = "$key-videoinfo.xml";

    my $content = $mogc->get_file_data( $videoinfo_xml );

    if (not defined $content) {
        print "$videoinfo_xml 文件不存在\n";
        return 0;
    }

    if ( $$content =~ m{<vsound>(\S+)</vsound>}) {
        return $1;
    }
}

sub delete_keys {
    my ($mogc, $key) = @_;

    $mogc->delete( $key );
    if ( defined $mogc->errstr ) {
        return ('error', $!);
    } else {
        return ('ok');
    }
}

sub store_keys {
    my ($mogc, $file) = @_;

    my $key = basename $file;
    my $flag;
    my $return_status =  eval {
        $mogc->store_file( $key, 'ts', $file,
                           {'chunk_size'=>1024*1024, 'largefile' => 1}
                       );
    };

    if ( $@ ) {
        $flag = $@;
    }

    return $flag;
}

sub load_config {
    my $config_file = shift;

	my $options = YAML::LoadFile( $config_file );

	return $options;
}
