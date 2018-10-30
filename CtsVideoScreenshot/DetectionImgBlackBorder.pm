package DetectionImgBlackBorder;

use GD;
use GD::Image;
use IO::Handle;
use FindBin;
use File::Find::Rule;

use base qw(Exporter);
our @EXPORT = qw( detectionImgBlackborder checkMottlePicture isBlackImg isBlackImgByPath getImgWidthHeight);

sub getImgWidthHeight {	
	my $picfile = shift;
	return 1 unless( defined $picfile and -f $picfile );
	STDOUT->autoflush(1);
	local $/;
	open my $image_fh, '<', $picfile;
	my $content = <$image_fh>;
	close $image_fh;

	my $image = newFromJpegData GD::Image($content);
	my ($width,$height) = $image->getBounds();
	return  ($width,$height);
}

sub isBlackImgByPath {
	my $path = shift;
	my @image;
	@image = File::Find::Rule->file()
		#->name('5_*.jpg','4_*.jpg','3_*.jpg')
		->name('*.jpg')
		->in( $path );

	foreach my $pic ( @image ){
		my $ret = isBlackImg($pic);
		if ( defined $ret and $ret == 1 ){
			#print $pic, "\n";
			return 1;
		}
	}
	return 0;
}

sub isBlackImg {
	my $picfile = shift;
	my $is_black = 0;
	return 1 unless( defined $picfile and -f $picfile );
	STDOUT->autoflush(1);
	### $picfile
	local $/;
	open my $image_fh, '<', $picfile;
	my $content = <$image_fh>;
	close $image_fh;

	my $image = newFromJpegData GD::Image($content);
	my ($width,$height) = $image->getBounds();

	my ($topEdge, $bottomEdge, $leftEdge, $rightEdge) = (0,0,0,0);
	my $xWidth  = $width -1;
	my $yHeight = $height -1;

    ## 检查左边缘 ##
	foreach my $x_i ( 0 .. $xWidth ) {
		my %hash;
		my $value;
		foreach my $y_i ( 0 .. $yHeight ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $height * 0.9 && $value < 80){
			### $x_i
			$leftEdge ++;
		}else{
			#print "\n leftEdge: $leftEdge \n";
			last;
		}
	}
    ## 检查右边缘 ##
	for( my $x_i=$xWidth; $x_i>0; $x_i-- ) {
		my %hash;
		my $value;
		foreach my $y_i ( 0 .. $yHeight ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $height * 0.9 && $value < 80){
			### $x_i 
			$rightEdge ++;
		}else{
			#print "\n rightEdge: $rightEdge \n";
			last;
		}
	}
	$is_black = 1 if( $leftEdge+$rightEdge > $width );
	return $is_black;
}

sub detectionImgBlackborder {
	my $picfile = shift;

	STDOUT->autoflush(1);
	### $picfile
	local $/;
	open my $image_fh, '<', $picfile;
	my $content = <$image_fh>;
	close $image_fh;

	my $image = newFromJpegData GD::Image($content);
	my ($width,$height) = $image->getBounds();

	my ($topEdge, $bottomEdge, $leftEdge, $rightEdge) = (0,0,0,0);
	my $xWidth  = $width -1;
	my $yHeight = $height -1;

    ## 检查上边缘 ##
	foreach my $y_i ( 0 .. $yHeight ) {
		my %hash;
		my $value;
		foreach my $x_i ( 0 .. $xWidth ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$red+$green+$blue=$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $width * 0.9 && $value < 80){
			### $y_i 
			$topEdge ++;
		}else{
			#print "\n topEdge: $topEdge \n";
			last;
		}
	}
    ## 检查下边缘 ##
	for( my $y_i=$yHeight; $y_i>0; $y_i-- ) {
		my %hash;
		my $value;
		foreach my $x_i ( 0 .. $xWidth ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $width * 0.9 && $value < 80){
			### $y_i
			$bottomEdge ++;
		}else{
			#print "\n bottomEdge: $bottomEdge \n";
			last;
		}
	}
    ## 检查左边缘 ##
	foreach my $x_i ( 0 .. $xWidth ) {
		my %hash;
		my $value;
		foreach my $y_i ( 0 .. $yHeight ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $height * 0.9 && $value < 80){
			### $x_i
			$leftEdge ++;
		}else{
			#print "\n leftEdge: $leftEdge \n";
			last;
		}
	}
    ## 检查右边缘 ##
	for( my $x_i=$xWidth; $x_i>0; $x_i-- ) {
		my %hash;
		my $value;
		foreach my $y_i ( 0 .. $yHeight ) {
			my $pixel = $image->getPixel($x_i, $y_i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			$value = $red+$green+$blue;
            #print "$value  ";
			$hash{$value} ++;
		}
		if ( $hash{$value} > $height * 0.9 && $value < 80){
			### $x_i 
			$rightEdge ++;
		}else{
			#print "\n rightEdge: $rightEdge \n";
			last;
		}
	}
	print "leftEdge:$leftEdge, rightEdge:$rightEdge, topEdge:$topEdge, bottomEdge:$bottomEdge \n";
	return ($leftEdge, $rightEdge, $topEdge, $bottomEdge);
}

sub checkMottlePicture {
	my $picPath = shift;
	my @image = File::Find::Rule->file()
                            ->name('*.jpg')
                            ->in( $picPath );
# @image
	STDOUT->autoflush(1);
	for my $image_file ( @image ) {
		local $/;
		open my $image_fh, '<', $image_file;
		my $content = <$image_fh>;
		close $image_fh;
	
		my $ret = &check_mottled( $content );
		return 1 if ( $ret );
#		if ( $ret ){
#			print "$image_file BAD\n";	
#		} else {
#			print "$image_file OK\n";	
#		}
	}
	return 0;
}

sub check_mottled {
	my ($blob) = @_;
	my $is_mottled = 0;

	my $image = newFromJpegData GD::Image($blob);
	my ($width,$height) = $image->getBounds();

	my $bottomCount = 0;
	my $sameColor   = 0;
	my $total   = $width - 1;
	my $yHeight = $height - 1;
	for( my $i=0; $i<5; $i++ ){
		foreach my $index ( 0 .. $total ) {
			my $pixel = $image->getPixel($index, $yHeight-$i);
			my ($red, $green, $blue) = $image->rgb($pixel);
			my $t = $red + $green + $blue;
			$hash{$t} ++;
			if ($green > 128 and $red + $blue < 64) {
				$bottomCount++;
			}
			if ( $hash{$t} > $width * 0.8 ){
				$sameColor = 1;
				last;
			}
		}
		if ( $sameColor == 1  and $bottomCount/$total >= 0.2 ){
			$is_mottled++;
		}
		$sameColor = 0;
	}

	#return 1 if ($bottomCount/$total >= 0.8);
    return 1 if ( $is_mottled > 2 );
	return 0;
}

1;
