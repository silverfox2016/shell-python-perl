use strict;
use warnings;
use Smart::Comments;
use FindBin;
use File::Find::Rule;
use File::Path;
use File::Basename;
use GD;
use GD::Image;
use IO::Handle;
use DBI;

sub mv_image{
        my ($imgPath, $pixel) = ('/cts/img/10/00/59/5/E1/shot/','230x130');
        my $outimgpath = "$imgPath/$pixel";

        my @imgages = File::Find::Rule->file()
                ->name('*.jpg')
                ->in( $outimgpath);

        foreach my $tmp_img_name ( @imgages )
        {
                my $imgName = fileparse( $tmp_img_name, '.jpg');
                $imgName .= "_${pixel}.jpg";
### $imgName
                `mv $tmp_img_name "$imgPath/$imgName"`;
        }
        return;
}

mv_image()
