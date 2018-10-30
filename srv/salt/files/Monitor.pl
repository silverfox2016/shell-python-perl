#! perl -w
use strict;
use warnings;
use JSON;
use LWP::UserAgent;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Sys::HostAddr;

my %ip2port = (
	"58.68.240.34" => "9301,8094,8084,8081,9303",
	"58.68.240.35" => "9301,8094,8084,8081,9303",
	"58.68.240.36" => "9301,8094,8084,8081,9303",
	"58.68.228.37" => "8096",
	"58.68.228.38" => "8096",
	"58.68.240.43" => "8082,8088,8091,8084,8081",
	"58.68.240.42" => "8082,8088,8091,8084,8081",
);

my %port2name = (
	"8082" => "lekan-film",
	"8088" => "lekan-ebook-api",
	"8091" => "kids-win8",
	"9301" => "lekan-huashu",
	"8094" => "kids-new-upgrade",
	"8084" => "kids-new-ios",
	"8081" => "lekan-api",
	"9303" => "lekan-api",
	"8096" => "pay-site",
);

my $ua = LWP::UserAgent->new;
my $interface = Sys::HostAddr->new(ipv => '4', interface => 'eth0');
my $ip = $interface->main_ip;
foreach my $port (split(",",$ip2port{$ip})){
	my $url = "http://$ip:$port/monitoringInterface.action";
	my $error = get_monitor_result($url);
	if ($error){
		sent_sms($error,$ip,$port);
	}else{
		print "$ip:$port <- $port2name{$port} -> safe\n";
	}
}


sub sent_sms{
	my ($error,$ip,$port) = @_;
	$error = "$ip:$port <- $port2name{$port} -> " . $error;
	my $phones = {
                meng_xl   => 18910731072,
		zou_wu    => 13716179941,
		zuhang_y  => 15910345037,
		#tian_kai  => 18601116811,
		yang_s  => 13718713339,
		song_qj   => 18612135446,
		di_yz => 18610116661,
		han_ys => 15010870210,
		liu_ys => 18601087176,
	};
	my $times = time;
	my $code = 1028;
	my $wdstr = "lekanbjlekan".$times;
	my $pwd = md5_hex($wdstr);
	for my $worker ( keys %$phones ) {
		my $number = $phones->{$worker};
		my $url_sms = "http://sms.ensms.com:8080/sendsms/?username=lekan&pwd=".$pwd."&dt=".$times."&mobiles=".$number."&code=".$code."&msg=【乐看】【警告】ip34".$error;
		
		if ($url_sms ne ""){
			my $ua1 = LWP::UserAgent->new();
			my $response1 = $ua1->get($url_sms);
			if(($response1->content) eq "0"){
				print "$number send success\n";
			}else{
				print "$number send FAILED\n";
			};
		}
	}
}

sub get_monitor_result{
	my ($url) = @_;
	my $i = 1;
	my $error = "";
	while( $i< 6){
		my $response = $ua->get($url);
		if ($response->is_success) {
		    my $content = $response->decoded_content;  # or whatever
		    if($content){
		    	my $content_js = from_json($content);
			    my $status = $$content_js{"status"};
			    my $redisConnect = $$content_js{"redisConnect"};
			    my $dbConnect = $$content_js{"dbConnect"};
			    print "$status,$redisConnect,$dbConnect\n";
			    if ($status == 1){
			    	if ($redisConnect == 0 and $dbConnect == 0){
			    		last;
			    	}elsif( $redisConnect != 0 ){
			    		$error = "redis disconnected, redisConnect: $redisConnect!";
			    	}elsif( $dbConnect != 0 ){
			    		$error = "database disconnected, dbConnect: $dbConnect!";
			    	}
			    	last;
			    }else{
			    	$error = "interFace failed, status: $status!";
			    }
			    
		    }else{
		    	$error = "interFace return null!";
		    }
		}
		else {
		    $error = $response->status_line;
		}
		sleep(1);
		$i++;
	}
	return $error;
}
