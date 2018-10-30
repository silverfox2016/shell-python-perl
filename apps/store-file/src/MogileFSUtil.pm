package MogileFSUtil;

use strict;
use warnings;

use MogileFS::Client;
use Cache::Memcached::Fast;
use LekanUtils;
use FindBin;
use lib $FindBin::Bin;
use base qw(Exporter);

our @EXPORT = qw(delete_from_mogilefs_and_memcache);
our @EXPORT_OK = qw();

sub connect_mogilefs {
    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => 'TS',
                                                hosts  => [ '192.168.1.222:7001', ],
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

sub connect_memcache{
	my $ip = shift;
	my $mem = new Cache::Memcached::Fast({
	     servers =>["$ip:11211"],
	     connect_timeout => 0.2,
	});
	return $mem;
}

sub getkey {
	my ($path) = @_;
	if($path =~ /\/(\d+)([ME])(\d+)?\/(cn|en)/){
		my $videoID = $1;
		my $type = $2;
		my $idx = defined $3 ? $3 : "";
		my $lang = $4;
		return $videoID . $type . $idx,$lang;
	}
}

sub delete_from_mogilefs_and_memcache{
	my $path = shift;
	
	my ($key,$lang) = getkey($path);
	#add xianglong.meng 
    #解决查找key后，将其他文件勿删除问题如 134588E2 会将134588E2*全部删除
	$key = $key . '-';
	runlog(__PACKAGE__, 'delete', $key,$lang, 'ts from mogilefs and memcache');
	if ($key){
		my $mogc = connect_mogilefs();
		
		my $mem1 = connect_memcache('218.16.119.245');
		my $mem2 = connect_memcache('112.245.17.199');
		my $mem3 = connect_memcache('218.16.119.248');
		my $mem4 = connect_memcache('221.194.137.39');
		my $mem5 = connect_memcache('221.194.137.40');
		my $mem6 = connect_memcache('112.245.17.196');
		
		my $keys = $mogc->list_keys($key);
		foreach (@$keys){
			$mogc->delete($_);
			if ( $_ =~ /ts$/ && $_ =~ /-$lang-/){
				
				$mem1->delete("mogfid:1:$_");
				$mem2->delete("mogfid:1:$_");
				$mem3->delete("mogfid:1:$_");
				$mem4->delete("mogfid:1:$_");
				$mem5->delete("mogfid:1:$_");
				$mem6->delete("mogfid:1:$_");
			}
		}
	}
}

1;
