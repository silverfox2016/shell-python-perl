package BackUp;

use strict;
use warnings;

use Smart::Comments;

use File::Copy;
use POSIX;

use FindBin;
use lib $FindBin::Bin;
use LekanUtils;
use LekanConfig;

use base qw(Exporter);

our @EXPORT = qw( backup_file );
our @EXPORT_OK = qw();

our $VERSION = '0.01';

sub backup_file {
    my $bak_info = shift;
    my $source_id = $bak_info->[2];
    my $dir       = $bak_info->[1];
    backup_src_video_file( $source_id );
    backup_out_video_file( $dir );
}

sub backup_src_video_file {
    my $id = shift;
    my $src_file = get_source_video( $id );
    my $bak_info = get_backup_dir( 'source' );
    my ($dst_dir, $real_path, $dst_ip) = @$bak_info;
    my $ret = move_file( $src_file, $dst_dir, $dst_ip, 'source', $real_path);

    if ( $ret ) {
        runlog(__PACKAGE__, 'failed backup source video', $src_file);
    } else {
        runlog(__PACKAGE__, 'success backup source video', $src_file);
    }

    return $ret;
}

sub backup_out_video_file {
    my $dir = shift;
    my $files   = get_out_video( $dir );
    my $bak_info = get_backup_dir('out_video' );
    my ($dst_dir, $real_path, $dst_ip) = @$bak_info;
    my $flag = 0;
    foreach my $mp4 ( @$files ) {
        my $ret = move_file( $mp4, $dst_dir, $dst_ip, 'out_video', $real_path ) foreach @$files;

        if ( $ret ) {
            runlog(__PACKAGE__, 'failed backup out video', $mp4);
            $flag = 1;
        } else {
            runlog(__PACKAGE__, 'success backup out video', $mp4);
        }
    }

    return $flag;
}

# /cts/out_video/619/19/133619M/cn
sub get_source_video {
    my $id = shift;

    my $dbh = connect_database();
    my $sql = qq{select * from task where id=$id};
    my $data = $dbh->selectrow_hashref( $sql );

    ### $data
    return $data->{pathName};
}

sub get_out_video {
    my $dir = shift;

    my @need_files;
    if ( -d $dir ) {
        my @mp4 = File::Find::Rule->file()
            ->name('*.mp4')
            ->in( $dir );
        ### 删除老的 key，bug (en|cn)
        @mp4 = sort { -s $a <=> -s $b } @mp4;
        push @need_files, @mp4;
    } elsif ( -f $dir ) {
        push @need_files, $dir;
    }

    return \@need_files;
}

sub move_file {
    my ($src_file, $dst_dir, $ip, $type, $real_dir) = @_;

    if (not -e $src_file) {
        runlog(__PACKAGE__, $src_file, 'not existed');
        return  0;
    }

    my $basename = basename $src_file;
    my $dst_file = "$dst_dir/$basename";
    copy $src_file => $dst_dir;
    my $src_md5 = get_file_md5( $src_file );
    my $dst_md5 = get_file_md5( $dst_file );

    if ( $src_md5 eq $dst_md5 ) {
        runlog(__PACKAGE__, 'backup', $src_file, 'success');
        my $size = -s $dst_file;
        $size = number_2_human_readable($size);
        unlink $src_file;
        my $real_path = "${real_dir}/$basename";
        insert_backup($ip, $real_path, $dst_md5, $size, $type);
        return 0;
    }
    
    runlog(__PACKAGE__, 'backup', $src_file, 'failed');
    unlink $dst_file;

    return 1;
}

sub get_backup_dir {
    # 找到适合空间的目录
    my $type = shift;

    my $config_file = join '/', $FindBin::Bin, '..', 'etc', 'cfg.yaml';
    my $options = load_config( $config_file );

    my @bak_info;
    my $date = strftime("%H%m%d", localtime);
    push @bak_info, join "/", $options->{$type}->{map_to}, $date;
    push @bak_info, join "/", $options->{$type}->{base}, $date;
    push @bak_info, $options->{$type}->{ip};

    return \@bak_info;
}

sub judge_dir_size {
    my $dir = shift;

    my $available = (df $dir)[3];

    my $flag = 0;
    my $size = 500 * 1024 * 1024;
    if ( $available > $size ) {
        my $flag = 1;
    }

    return $flag;
}

1;
