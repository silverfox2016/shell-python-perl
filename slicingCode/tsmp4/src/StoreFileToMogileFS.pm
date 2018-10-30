package StoreFileToMogileFS;

use strict;
use warnings;

use Smart::Comments;
use DBD::mysql;
use File::Copy;
use File::Basename;
use File::Find::Rule;
use MogileFS::Client;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;

use base qw(Exporter);

our @EXPORT = qw(store_to_mogilefs);
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub store_to_mogilefs {
    my $file_dir = shift;
#add by xianglong.meng at 20160218
#新增preview m3u8处理模块
	my $m3u8_dir = "$file_dir/ts/";
	my @m3u8_file = File::Find::Rule->file()
                                ->name('*.m3u8')
                                ->in($m3u8_dir);
	@m3u8_file = grep { /k\.m3u8/ } @m3u8_file;
	runlog('start deal preview m3u8 files');
    my $preview_file = \@m3u8_file;
### $preview_file
	preview_m3u8($m3u8_dir,@m3u8_file);
	runlog('Deal preview m3u8 files done!');
	
### $file_dir
    return 0 if not -d $file_dir;
    my $ts_dir = "$file_dir/ts";
    runlog('store file begin');
    my @types = qw(*.m3u8 *.ts);
    my $videoinfo =  "${file_dir}/../videoinfo.xml";
    
    my $files = find_files( $ts_dir, \@types );

    push @$files, $videoinfo;
    my $mogc = connect_mogilefs();
    foreach my $file ( @$files ) {
        next if ($file =~ /-900-/);
        my $ret = store_file( $mogc, $file );
        runlog(__PACKAGE__, 'success store', $file, 'to mogilefs');
        redo if ( $ret == 0 );
    }
    runlog('store file finished');

    return 1;
}

sub find_files {
    my ($dir, $type) = @_;
    my $rule = File::Find::Rule->new();
    $rule->file;
    $rule->name( @$type );
    
    my @files = $rule->in( $dir );

    return \@files;
}

#add by xianglong.meng at 20160218
#用于生成preview m3u8文件
sub preview_m3u8 {
	my ($dir,@m3u8_files) = @_;
	my $files = \@m3u8_files;
    foreach my $file ( @$files ) {
        my ($id,$lang,$bit) = split('-',$file);
        #新的m3u8文件名字
        my $new_file = "$id-$lang-preview-$bit";
        open(FN,$file);
        my $T = 0;
        my $N = 0;
        my $flag = 0;
        my @lines = <FN>;
        foreach my $line (@lines) {
            if ( $line =~ /#EXTINF:(\d+),/ ) {
                $T += $1;
                $N++;
                #用于统计时间，时长为5分钟左右 ，先复制原m3u8文件为preview文件
               	#如总时长小于5分钟，则不操作，如时长大于5分钟后，生成新的preview文件
                if ( $T < 300 ) {
                   copy $file => $new_file;
                } elsif ( $T >= 300 ) {
                   open(WN,"> $new_file");
                   print WN (@lines[0..$N*2+5],@lines[$#lines-1..$#lines],);
                   last;
                }
            }
        }
        close FN;
        close WN;	
    }
}
sub store_file {
    my ($mogc, $file) = @_;

### $file
    my $key = get_key($file);
### $key
    return if (not defined $key);

    my $class = 'ts';
    my $ret_store = store($mogc, $class, $key, $file);
    unless ( $ret_store ) {
        runlog(__PACKAGE__, 'failed store', $file, 'to mogilefs');
        return 0;
    }

    return 1;
}

sub store {
    my ($mogc, $class, $key, $file) = @_;
    print "$key $class $file\n";
    my ($size, $i);
    #$mogc->store_file($key, $class, $file, {'chunk_size' => 102400000});
    while ( $i++<10 ) {
        $size = eval {
            $mogc->store_file($key, $class, $file, {
                'chunk_size' => 102400000,
            });};
        if ( $@ ) {
            sleep 10;
            runlog(__PACKAGE__, 'retry store file', $file, 'into mogilefs');
            next;
        }
        last;
    }

    return $size;
}

=h

sub connect_mogilefs {
    my $mogc;
    while (1) {
        $mogc =  eval { MogileFS::Client->new(  domain => 'TS',
                                                hosts  => [ '60.209.4.35:7001', ],
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
=cut

sub get_key {
    my $file = shift;

    my $key;
    if ( $file =~ m{ts$} or $file =~ m{m3u8$} ) {
        $key = basename($file);
    } elsif ( $file =~ m{xml$}) {
        $key = join '-', (split(/\//, $file))[-4,-1];
    }
    
    return $key;
}

1;
