sub CutOutImage_screenshot_img{
        #my ($file_name, $widely, $highly, $img_path, $interval_frames) = @_;
        my ($file_name, $widely, $highly, $img_path, $interval_frames) = ('/cts/out_video/576/76/1000576E3/en/video-1200k.mp4',230,130,'/cts/img/10/00/57/6/E3/shot/','12960.238464');

        my $pixel = $widely.'x'.$highly;
        my $out_path = $img_path.$pixel;
        #system( "mkdir -p $out_path" );
        #my $cmd = qq{/lekan/apps/ffmpeg/bin/CutOutImage $file_name $widely $highly $out_path $interval_frames};
        my $cmd = qq{/usr/local/bin/ffmpeg -i $file_name -y -f image2 -t 0.001 -s $pixel $out_path/$pixel.jpg};
        system( "$cmd" );
        &recordlog($logFile, "cmd: $cmd");

        mv_image( $img_path, $pixel);
    ## 实现该函数,perl中的rename
    ## rename 's/(\d+)/$1_$pixel/' "$imgPath/$pixel";
    ## `mv $outimgpath/*.jpg $imgPath`;
        return;
}

CutOutImage_screenshot_img()
