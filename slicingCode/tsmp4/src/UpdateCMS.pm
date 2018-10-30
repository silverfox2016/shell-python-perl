package UpdateCMS;

#use Smart::Comments;
use MogileFS::Client;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;
use Database;

#add 2016-11-01 by wuxp
use Database70;

use base qw(Exporter);

our @EXPORT = qw(update_cms);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub get_videoinfo_content {
    my ($mogc, $key) = @_;
    my $file_info = $mogc->get_file_data( $key );

    my $xml_content = $$file_info;
    my ($vsound, $vtime, $vid);
    if ( defined $xml_content ) {
        ($vsound) = $xml_content =~ /vsound\>(.*)\<\/vsound/;
        ($vtime)  = $xml_content =~ /vtime\>(.*)\<\/vtime/;
        ($vid)    = $xml_content =~ /vid\>(.*)\<\/vid/;
    } else {
        runlog("To get videoinfo.xml content error");
        return;
    }

    ### $vid
    ### $vsound
    ### $vtime
    return ($vsound, $vtime, $vid);
}


sub judgment_video_type {
    my ($mogc, $vid) = @_;
    my $vrate_hd = 0;
    my ( $mp4_enkey, $mp4_cnkey);
    $mp4_enkey = $vid.'-en-2500k.mp4';
    $mp4_cnkey = $vid.'-cn-2500k.mp4';

    my @path_en = $mogc->get_paths( $mp4_enkey );
    my @path_cn = $mogc->get_paths( $mp4_cnkey );
    if((@path_en) or (@path_cn)){
        $vrate_hd = 1;
    }
### $vrate_hd
    return $vrate_hd;
}
sub juge_work{
    my $vid = shift;
    my $dbh = open_db_70();
    my $data = get_task_from_db_70($dbh, $vid);
    if (not defined $data){
        runlog("Not get this $vid video id path from 70db.");
        return 0;
    }
    my $work_name = (split(/\//,$data->[0]))[2];
    return $work_name;
}
sub update_cms{
    my $key = shift;
    my $mogc = connect_mogilefs();
    my ($vsound, $vtime, $vid) = get_videoinfo_content($mogc, $key);
    my $vrate_hd = judgment_video_type($mogc, $vid);

    if (not defined $vid) {
        runlog("To get vsound or vtime or vid information error");
        return 0;
    }
    #add 20161101 by wuxp
    #my $work_name = juge_work($vid);
    my $cmd1,$cmd2;
    #20180305 change by wxp 判断是vogue还是儿童视频
    if ($vid =~ /10\d+(M|E)\d+/){
        $cmd1 = qq{curl -s -d "videoId=$vid" -d "songLanguage=$vsound" -d "hd=$vrate_hd" "http://cncms.lekan.com/app/impl/videoPostFile.action"};
        $cmd2 = qq{curl -s -d "videoId=$vid" -d "timelen=$vtime" "http://cncms.lekan.com/app/impl/editVideoTime.action"};
    }else{
        $cmd1 = qq{curl -s -d "videoId=$vid" -d "songLanguage=$vsound" -d "hd=$vrate_hd" "http://cms.lekan.com/app/impl?videoPostFile"};
        $cmd2 = qq{curl -s -d "videoId=$vid" -d "timelen=$vtime" "http://cms.lekan.com/app/impl?editVideoTime"};

    }


    my ($i, $cmd1_flag);
    while ($i++<10){  
    	my ($error) = `$cmd1`;
    	my $hasfile_ret = $? >> 8;

    	if ( $hasfile_ret == 0 && $error == 1 ) {
    	    runlog('update cms OK', $cmd1 );
            $cmd1_flag = 1;
            last;
    	} else {
	    runlog('Retry update cms',"$i times", $cmd1);
            $cmd1_flag = 0;
            next;
    	}
    }
    my ($j, $cmd2_flag);
    while ($j++<10){
    	my ($error) = `$cmd2`;
    	my $time_ret = $? >> 8;
    	
    	if ( $time_ret == 0 && $error == 1 ) {
    	    runlog('update cms OK', $cmd2);
            $cmd2_flag = 1;
            last;
    	} else {
            runlog('Retry update cms',"$j times", $cmd2);
            $cmd2_flag = 0;
    	    next;
    	}
    }
    if ($cmd1_flag == 0 || $cmd2_flag == 0){
        runlog('Update cms FAILED!', $vid);
        
   	return 0;
    }
    return 1;
}

sub connect_mogilefs {
    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => 'TS',
                                                hosts  => [ '192.168.1.222:7001' ],
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
