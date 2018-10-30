package Worker;

use strict;
use warnings;

use Smart::Comments;
use File::Find::Rule;
use File::Basename;
use LWP::UserAgent;

use FindBin;
use lib $FindBin::Bin;
use MogileFSUtil;
use LekanUtils;
use LekanConfig;
use RemoveChapter;
use BackUp;
use Database;
use StoreMp4;
use POSIX;
use JSON;
use Digest::MD5 qw(md5 md5_hex md5_base64);

use base qw(Exporter);

our @EXPORT = qw(store_worker);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub store_worker  {
    my $dbh = connect_local_database();
    
#	my $hour_t = strftime("%H", localtime(time));
#	if ( $hour_t >=18 and $hour_t <=22 ){
#		runlog(__PACKAGE__, 'stop transfer between 18-23: ', "[$hour_t]");
#		die;
#	}

    while ( 1 ) {
        $dbh ||= connect_local_database();
        my $data;
        for my $pri ( reverse 0..5 ) {
            my $sql = "SELECT id,path,sourceId FROM upload WHERE status in ('0','15') and  priority=$pri order by rand()";
            #my $sql = "SELECT id,path,sourceId FROM upload WHERE status=0 and verification=1 and priority=$pri";
            $data = $dbh->selectrow_arrayref( $sql );
            last if defined $data;
        }

        if ( not defined $data ) {
            sleep 300;
            next;
        }
    
        my $path = $data->[1];
        my $id   = $data->[0];
        my $sid  = $data->[2];
        
		update_db('upload', 'status', 1, $id);
        sleep 10;

        my @need_files;
        if ( -d $path ) {
            my $rule = File::Find::Rule->new();
            $rule->file;
            $rule->name('*.mp4');
            my @mp4 = $rule->in( $path );
            ### 删除老的 key，bug (en|cn)
            @mp4 = sort { -s $a <=> -s $b } @mp4;
            push @need_files, @mp4;
        } elsif ( -f $path ) {
            push @need_files, $path;
        }

        my $flag = 0;
        my $mogile_key_or_path;
	#my ($pre_status,$up_status) = get_video_status($path);
        my $mp4_count = scalar @need_files;
        if ( $mp4_count != 4 and $mp4_count != 8 and $mp4_count != 7 ) {
            update_db('upload', 'status', 13, $id);
            runlog(__PACKAGE__, $id, '文件不全', $mp4_count, "@need_files");
        ########
        #}elsif( $pre_status == 0 ){# this condition add by tiankai 20150906
        # 	update_db('upload', 'status', 15, $id);
        #	runlog(__PACKAGE__, $id, '视频缓存未完成', $path);
        } else {
        	
        	delete_from_mogilefs_and_memcache($path);#this condition add by tiankai 20150907
            foreach my $mp4_file ( @need_files ) {
                $mogile_key_or_path = get_file_directory( $mp4_file ) if not defined $mogile_key_or_path;
                ### $mogile_key_or_path
                ### $mp4_file
                my $ret_value = remove_chapter( $mp4_file );
                ### $ret_value
                if ( $ret_value == 0 ) {
                    my $ret  = store_file( $mp4_file );
                    #update_Mp4_length($mp4_file);
                    $flag = 1 if $ret;
                } else {
                    $flag = 1;
                }
            }

            if ( $flag == 0 and defined $mogile_key_or_path ) { 
                #  backup_file( $data );
                update_db('upload', 'status', 2, $id);
                
                # this condition add by tiankai 20150906
                # 等于1代表是旧视频，提交一个上传状态，方便后面清缓存
		#####
                #if ($pre_status == 1 and $up_status == 0){
                # 	update_store_status($path);
                #}
                
                sleep 5;
                update_db('task', 'status', 4, $sid);
                insert_into_mp4file($mogile_key_or_path);
            } else {
                update_db('upload', 'status', 13, $id);
            }
        }

#		my $hour_t = strftime("%H", localtime(time));
#		if ( $hour_t >=18 and $hour_t <=23 ) {
#        	runlog(__PACKAGE__, 'stop transfer between 18-23');
#			die;
#		}
    }

    $dbh->disconnect;
}

sub insert_into_mp4file {
    my $key = shift;
    my $dbh = connect_mogilefs_database();
    my $sth = $dbh->prepare( qq{INSERT INTO mp4file(path) VALUES(?) } ) ;

    $sth->execute($key);

    my $ret = 1;
    if ( $dbh->errstr ) {
        $ret = 0;
        runlog(__PACKAGE__, 'insert into 37 database,sendfile failed:', $dbh->errstr);
    }

    return $ret;
}

sub get_file_directory {
    my $file = shift;

    my $tmp_dir = dirname $file;
    
    my $dir = "/lekan_video/video${tmp_dir}";
    return $dir;
}

sub get_video_status{
	my $path = shift;
	my $hosturl = "http://precache.lekan.com/episode.php";
	my $pre_status = -1;
	my $up_status = -1;
	if($path =~ /\/(\d+)[ME](\d+)?\/(en|cn)/){
		my $videoID = $1;
		my $idx = defined $2 ? $2 : 1;
		my $lang = $3;
		my $browser = LWP::UserAgent->new();
		my $response= $browser->post($hosturl, 
			[ "upvideo" => 'search',
			  "video_sn" => $videoID,
			  "video_sets" => $idx,
			  "episode_lang" => $lang,
			]
		);
		my $content = $response->content;
		chomp($content);
                print "$content";
		if ($content){
			my $json_ref = from_json($content);
			return $$json_ref{"pre_status"},$$json_ref{"up_status"};
		}
	}
	return $pre_status,$up_status;
}

sub update_store_status{
	my $path = shift;
	my $hosturl = "http://precache.lekan.com/episode.php";
	if($path =~ /\/(\d+)[ME](\d+)?\/(en|cn)/){
		my $videoID = $1;
		my $idx = defined $2 ? $2 : 1;
		my $lang = $3;
		my $browser = LWP::UserAgent->new();
		my $response= $browser->post($hosturl, 
			[ "upvideo" => 'update',
			  "video_sn" => $videoID,
			  "video_sets" => $idx,
			  "episode_lang" => $lang,
			]
		);
		my $content = $response->content;
		chomp($content);
		if ($content){
			if ($content eq "true"){
				runlog(__PACKAGE__, 'upload success and report success', $path );
			}else{
				runlog(__PACKAGE__, 'upload success but report fail', $path );
			}
		}
	}
}

sub get_Mp4_length{
	my $mp4_file = shift;
	my @items = stat($mp4_file);
	return $items[7];
}

#sub update_Mp4_length{
#	my $mp4_file = shift;
#	
#	my @items = split(/\//,$mp4_file);
#	my $stream = $items[-1];
#	$stream =~ s/.*-//;
#	my $dkey = $items[-3] . "-" . $items[-2] . "-" . $stream;
#	
#	my $mp4_length = get_Mp4_length($mp4_file);
#	my $ua = LWP::UserAgent->new;
#	my $time = time();
#	my $encryptStr =  md5_hex($time . "lekan99");
#	#my $cmsApiStr = "http://cms.lekan.com/app/video?addVideoInfos&dkey=$dkey&fileSize=$mp4_length&encryptStr=$encryptStr&privateKey=$time";
#	runlog(__PACKAGE__, 'cmsApiStr:', $cmsApiStr);
#	#my $response = $ua->get("http://cms.lekan.com/app/video?addVideoInfos&dkey=$dkey&fileSize=$mp4_length&encryptStr=$encryptStr&privateKey=$time");
#	if($response->status_line =~ /200/){
#		my $content = $response->content;
#		if ($content =~ /code:(\d+)/){
#			my $code = $1;
#			if($code != 1){
#				runlog(__PACKAGE__, '上传mp4大小失败', $code);
#			}
#		}else{
#			runlog(__PACKAGE__, '上传mp4大小失败', $content);
#		}
#	}else{
#		runlog(__PACKAGE__, '上传mp4大小失败', $response->status_line);
#	}
#}

1;
