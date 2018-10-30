use strict;
use LWP::UserAgent;
#use Time::Local;
#use Net::SNMP;

#version: 1.0  ----- 283
#version: 1.1  ----- 294
#version: 1.2  ----- 296
#version: 1.3  ----- 342

my $conf = shift || "/usr/local/script/sysmon.conf";
my %g_conf;
$g_conf{'trapserver'} = '';
$g_conf{'community'} = 'VSJPg7Gpm0Z08hbR';
$g_conf{'record_dir'} = '/lekan/logs/sys_mon/';
$g_conf{'mysql_user'} = 'root';
$g_conf{'mysql_passwd'} = '';
$g_conf{'mysql_socket'} = '/var/lib/mysql/mysql.sock';
if(open(DDD,$conf)) {
    while(<DDD>) {
        chomp;
        my ($k,$v) = (/^\s*([^#]{1}\S+)\s*=\s*(\S+)/o);
        if ($k == "proc_thread_num") {
            push @{$g_conf{$k}}, $v;
        } else {
            $g_conf{$k} = $v;
        }
    }
    close(DDD);
}
if (! -d $g_conf{'record_dir'}) {
    system("mkdir -p " . $g_conf{'record_dir'});
}
my %tid;
$tid{'mysql_salve'} = '.1.3.6.1.4.1.99988.20.10.2.9';
$tid{'hdc'} = '.1.3.6.1.4.1.99988.20.20.2.1';
$tid{'disk'} = '.1.3.6.1.4.1.99988.20.30.2.1';
$tid{'diskst'} = '.1.3.6.1.4.1.99988.20.30.3.1';
$tid{'netlink'} = '.1.3.6.1.4.1.99988.20.40.2.1';
$tid{'openfile'} = '.1.3.6.1.4.1.99988.20.50.2.1';
$tid{'idlecpu'} = '.1.3.6.1.4.1.99988.20.60.2.1';

my %STAT;
$STAT{'netlink'}{0} = 'UP';
$STAT{'netlink'}{1} = 'DOWN';

if (! -d $g_conf{'record_dir'}) {
    mkdir($g_conf{'record_dir'});
}
my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime();
my $ldate = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday );
my $record_time = sprintf("%04d%02d%02d %02d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
my $record_file = $g_conf{'record_dir'} . $ldate . "_sys.info";
my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time()-30*3600*24);
$ldate = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday );
my $old_record_file = $g_conf{'record_dir'} . $ldate . "_sys.info";
#print $record_file,"\n";
#print $old_record_file,"\n";

my %sysinfo;
unlink $old_record_file if (-f $old_record_file);

$sysinfo{'mem'} = "";
$sysinfo{'procmem'} = "";
$sysinfo{'procnum'} = "";
$sysinfo{'proccpu'} = "";
$sysinfo{'cpu'} = "";
$sysinfo{'pcpu'} = "";
$sysinfo{'mysql_slave'} = 0;
$sysinfo{'load'} = "";
$sysinfo{'netlink'} = "";
$sysinfo{'disk'} = "";
$sysinfo{'tcp'} = "";
$sysinfo{'diskst'} = '';
$sysinfo{'netstat'} = "";
$sysinfo{'procall'} = 0;
$sysinfo{'openfile'} = 0;
$sysinfo{'hdc'} = 0;

my %oldinfo;

get_history();

my $alert = 0;
my $opf = 0;
open(DDD,"-|","/usr/bin/free -m") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        my @tt = split();
        if ($tt[0] eq "Mem:") {
            $sysinfo{'mem'} = $tt[3].','.$tt[5].','.$tt[6].','.$tt[2];
        }
    }
    close(DDD);
}
$opf = 0;
open(DDD,"-|","/bin/ps -eo pid,rss,pcpu,comm 2>/dev/null") or $opf = 1;#rss
my (%mm,%mc,%mn);
if ($opf == 0) {
    while(<DDD>) {
        my @tt = split();
        my $k = $tt[0] . "-" . $tt[3];
        $mm{$k} = int($tt[1]/1024);
        $mc{$k} = $tt[2];
        $mn{$tt[3]} += 1;
        $sysinfo{'procall'} += 1;
    }
    close(DDD);
}
$opf = 0;
$sysinfo{'procmem'} = hash_sort_value(\%mm);
$sysinfo{'procnum'} = hash_sort_value(\%mn);
$sysinfo{'proccpu'} = hash_sort_value(\%mc);
open(DDD,"/proc/sys/fs/file-nr") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        my @tt = split();
        $sysinfo{'openfile'} = $tt[0] . ':' . $tt[2];
        my $p = int(($tt[0] / $tt[2]) * 100);
        if ($p > 90) {
            send_trap($tid{'openfile'},'Openfiles ' . $tt[0] . '.Critical');
            $alert = 1;
        } elsif ($p > 80) {
            send_trap($tid{'openfile'},'Openfiles ' . $tt[0] . '.Warning');
            $alert = 1;
        }
    }
    close(DDD);
}

if ($alert == 0) {
    my $rr = $oldinfo{'openfile'};
    if ($rr ne "") {
        my @tt = split(':',$rr);
        my $p = int(($tt[0] / $tt[1]) * 100);
        if ($p > 80) {
            send_trap($tid{'openfile'},'Openfiles ' . $tt[0] . '.Ok');
        } 
    }
}
$opf = 0;
open(DDD,"/proc/loadavg") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        my @tt = split();
        $sysinfo{'load'} = $tt[0] . ',' . $tt[1] . ',' . $tt[2];
    }
    close(DDD);
}
$opf = 0;
my %netlink;
foreach my $t (split(',',$oldinfo{'netlink'})) {
    my @tt = split(':',$t);
    $netlink{$tt[0]} = $tt[1];
}
open(DDD,"/proc/net/dev") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        my ($eth) = (/^\s+([a-z]+\d):/o);
        if ($eth) {
            my $l = system("/usr/sbin/ethtool $eth | grep 'Link detected: yes' >/dev/null");
            $l = 1 if ($l != 0);
            if ($l == 0) {
                open(FFF,"/sys/class/net/$eth/statistics/rx_bytes") or $opf = 1;
                my $rx = <FFF>;
                chomp($rx);
                $sysinfo{$eth."-flow"} = "rx:" . $rx . ',';
                close(FFF);
                $opf = 0;
                open(FFF,"/sys/class/net/$eth/statistics/tx_bytes") or $opf = 1;
                my $tx = <FFF>;
                chomp($tx);
                $sysinfo{$eth."-flow"} .= "tx:" . $tx;
                close(FFF);
            }
            $sysinfo{'netlink'} .= $eth . ':' . $l . ',';
            if ($netlink{$eth} != $l) {
                send_trap($tid{'netlink'},$eth.':'.$STAT{'netlink'}{$l});
            }
        }
    }
    close(DDD);
}


###sockstat
##tcp stat
#inuse: 
#orphan: not attached to any user file handle
#tw: timewait
#alloc: sockets_allocated
#mem: memory_allocated
$opf = 0;
open(DDD,"/proc/net/sockstat") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        if (/^TCP: (.+)/o) {
            $sysinfo{'tcp'} = $1;
        }
    }
    close(DDD); 
}
$opf = 0;
my ($tcp,$tcp6);
open($tcp,"/proc/net/tcp") or $opf = 1;
open($tcp6,"/proc/net/tcp6");
my %tcpst;
if ($opf == 0) {
    foreach my $t ($tcp,$tcp6) {
        while(<$t>) {
            my @tt = split(' ');
            my $port;
            my ($tt1,$p) = split(':',$tt[1]);
            if (defined $p) {
                $port = hex($p); 
                $tcpst{$port}{'TOTAL'} = 0 if ($tt[3] eq "0A");
            }
            my @ip = split('',$tt[2]);
            my $clip = hex($ip[6] . $ip[7]) . "." . hex($ip[4] . $ip[5]) . "." . hex($ip[2] . $ip[3]) . "." . hex($ip[0] . $ip[1]);
            if($tt[3] eq "st") {
                next;
            } elsif($tt[3] eq "01") {
                if (exists($tcpst{$port})) {
                    $tcpst{$port}{'ESTABLISHED'} += 1;
                    $tcpst{$port}{'clip'}{$clip} += 1;
                }
                $tcpst{'all'}{'ESTABLISHED'} += 1;
            } elsif($tt[3] eq "03") {
                if (exists($tcpst{$port})) {
                    $tcpst{$port}{'SYN_RECV'} += 1;
                }
                $tcpst{'all'}{'SYN_RECV'} += 1;
            } elsif($tt[3] eq "04" or $tt[3] eq "05") {
                $tcpst{$port}{'FIN_WAIT'} += 1 if (exists($tcpst{$port}));
                $tcpst{'all'}{'FIN_WAIT'} += 1;
            } elsif($tt[3] eq "06") {
                $tcpst{$port}{'TIME_WAIT'} += 1 if (exists($tcpst{$port}));
                $tcpst{'all'}{'TIME_WAIT'} += 1;
            } elsif($tt[3] eq "07" or $tt[3] eq "08" or $tt[3] eq "0B") {
                $tcpst{$port}{'CLOSE'} += 1 if (exists($tcpst{$port}));
                $tcpst{'all'}{'CLOSE'} += 1;
            }
            $tcpst{'all'}{'TOTAL'} += 1;
            $tcpst{$port}{'TOTAL'} += 1 if (exists($tcpst{$port}));
        }
        close($t);
    } 
    foreach my $k (keys %tcpst) {
        foreach my $kk (keys %{$tcpst{$k}}) {
            if ($kk eq "clip") {
                my $ss = $tcpst{$k}{$kk};
                #print ref $ss,": ",$ss,"--$k\n";
                next if ref $ss ne "HASH";
                my $i = 0;
                foreach my $sk (sort {$ss->{$b} <=> $ss->{$a}} keys %{$ss}) {
                    next if ($i > 10);
                    $sysinfo{"netstat_clip_".$k} .= $sk . ":" . $ss->{$sk} . ',';
                    $i++;
                }
            } else {
                $sysinfo{'netstat_'.$k} .= $kk . ":" . $tcpst{$k}{$kk} . ',';
            }
        }
    }
}

my %old_cpu;

my @tt = split(':',$oldinfo{'cpu'});
$old_cpu{'user'} = $tt[0];
$old_cpu{'nice'} = $tt[1];
$old_cpu{'system'} = $tt[2];
$old_cpu{'idle'} = $tt[3];
$old_cpu{'iowait'} = $tt[4];
$old_cpu{'irq'} = $tt[5];
$old_cpu{'softirq'} = $tt[6];

$opf = 0;
$alert = 0;
open(DDD,"/proc/stat") or $opf = 1;
my (%cur_cpu,%pcpu,$acpu);
if ($opf == 0) {
    while(<DDD>) {
        my @tt = split();
        if ($tt[0] eq "cpu") {
            $sysinfo{'cpu'} = $tt[1].":".$tt[2].":".$tt[3].":".$tt[4].":".$tt[5].":".$tt[6].":".$tt[7];
            $pcpu{'user'} = $tt[1] - $old_cpu{'user'};
            $acpu += $pcpu{'user'};
            $pcpu{'nice'} = $tt[2] - $old_cpu{'nice'};
            $acpu += $pcpu{'nice'};
            $pcpu{'system'} = $tt[3] - $old_cpu{'system'};
            $acpu += $pcpu{'system'};
            $pcpu{'idle'} = $tt[4] - $old_cpu{'idle'};
            $acpu += $pcpu{'idle'};
            $pcpu{'iowait'} = $tt[5] - $old_cpu{'iowait'};
            $acpu += $pcpu{'iowait'};
            $pcpu{'irq'} = $tt[6] - $old_cpu{'irq'};
            $acpu += $pcpu{'irq'};
            $pcpu{'softirq'} = $tt[7] - $old_cpu{'softirq'};
            $acpu += $pcpu{'softirq'};
            #$pcpu{'all'} = $acpu;
            last;
        }
    }
    close(DDD);
    foreach my $k (keys %pcpu) {
        my $p = $pcpu{$k} / $acpu * 100;
        if ($k eq "idle") {
            if (($p*100) <= 10) {
                send_trap($tid{'idlecpu'},'Critical');
                $alert = 1;
            } elsif (($p*100) < 20) {
                send_trap($tid{'idlecpu'},'Warning');
                $alert = 1;
            }
        }
        $sysinfo{'pcpu'} .= sprintf("%s:%.2f%%,",$k,$p);
    }
}
if ($alert == 0) {
    my $rr = $oldinfo{'pcpu'};
    if ($rr ne "") {
        foreach my $ff (split(',',$rr)) {
            my @tt = split(':',$ff);
            if ($tt[0] eq "idle") {
                if ($tt[1] < 20) {
                    send_trap($tid{'idlecpu'},'OK');
                } 
            }
        }
    }
}

######check_mysql
if (eval "require DBD") {
    require DBI;
    my $err = 0;
    my $malert = 0;
    my $dbh;
    if (-r $g_conf{'mysql_socket'}) {
        $dbh = DBI->connect("dbi:mysql:mysql;host=localhost;port=3306;mysql_socket=". $g_conf{'mysql_socket'} .
            ";mysql_connect_timeout=10", $g_conf{'mysql_user'},$g_conf{'mysql_passwd'})
            or $err = 1;
    } else {
        $err = 1;
    }    
#     eval {
#         $dbh = DBI->connect("dbi:mysql:mysql;host=localhost;port=3306;mysql_socket=". $g_conf{'mysql_socket'} .
#                 ";mysql_connect_timeout=10", $g_conf{'mysql_user'},$g_conf{'mysql_passwd'})
#                 or die();
#     };
    
    if( $err == 0 ) {
        my $sth = $dbh->prepare('show slave status');
        $sth->execute;
        while(my $row = $sth->fetchrow_hashref()) {
            if ($row->{'Slave_IO_Running'} eq 'No' or $row->{'Slave_SQL_Running'} eq 'No') {
                $sysinfo{'mysql_slave'} = 1;
            } else {
                $sysinfo{'mysql_slave'} = 0;
            }
        }
        if ($sysinfo{'mysql_slave'} == 1) {
            send_trap($tid{'mysql_slave'},'Critical');
        } else{
            my $rr = $oldinfo{'mysql_slave'};
            if ($rr >= 1) {
                send_trap($tid{'mysql_slave'},'Ok');
            }
        }
    }
}

######check_hdc
if (-s '/data/logs/hdcenter.stat') {
    open(DDD, '/data/logs/hdcenter.stat');
    while(<DDD>) {
        chomp;
        $sysinfo{'hdc'} = $_;
    }
    close(DDD);
    send_trap($tid{'hdc'},'Critical');
} else {
    $sysinfo{'hdc'} = 0;
    my $rr = $oldinfo{'hdc'};
    if ($rr != 0) {
        send_trap($tid{'hdc'},'Ok');
    }
}

######check_disk
$opf = 0;
$alert = 0;
my $df = 0;
open(FFF,"-|","/bin/ps -ef") or $opf = 1;
if ($opf == 0) {
    while(<DDD>) {
        if (/\/bin\/df -h/o) {
            $df = 1;
        }
    }
}
close(FFF);
if ($df == 0) {
    open(DDD,"-|","/bin/df -h") or $opf = 1;
    if ($opf == 0) {
        while(<DDD>) {
            my @tt = split();
            my $ttlen = $#tt;
            if ($tt[0] =~ /^\/dev\/sd[a-z0-9]+/o) {
                my $dd = $tt[4] + 0;
                $sysinfo{'disk'} .= $tt[0] . ':' . $dd . ',';
                $tt[$ttlen] .= "/" if ($tt[$ttlen] ne "/");
                if (open(TTT,">".$tt[$ttlen]."cibn-disk-test-write")) {
                    if (syswrite(TTT, "OK")) {
                        close(TTT);
                        unlink($tt[$ttlen]."cibn-disk-test-write")
                    } else {
                        $sysinfo{'diskst'} .= $tt[0].":";
                        send_trap($tid{'diskst'},$tt[0]."(".$tt[$ttlen]."):.Critical");
                        $alert = 1;
                    }
                } else {
                    $sysinfo{'diskst'} .= $tt[0].":";
                    send_trap($tid{'diskst'},$tt[0]."(".$tt[$ttlen]."):.Critical");
                    $alert = 1;
                }
                if ($dd > 90) {
                    send_trap($tid{'disk'},$tt[0]."(".$tt[$ttlen]."):".$dd.'%.Critical');
                    $alert = 1;
                } elsif ($dd >= 80) {
                    send_trap($tid{'disk'},$tt[0]."(".$tt[$ttlen]."):".$dd.'%.Warning');
                    $alert = 1;
                }
            }
        }
    }
    close(DDD);
    if ($alert == 0) {
        my $rr = $oldinfo{'disk'};
        if ($rr ne "") {
            foreach my $ff (split(',',$rr)) {
                my @tt = split(':',$ff);
                if ($tt[1] >= 80) {
                    send_trap($tid{'disk'},$tt[0]."(".$tt[5]."):".$tt[1].'%.OK');
                }
            }
        }
        $rr = $oldinfo{'diskst'};
        if ($rr ne "") {
            send_trap($tid{'diskst'},"Disk write OK");
        }
    }
}

#####check_syslog
#sd 0:0:6:0: [sdg]

#####proc_thread_num
if (exists($g_conf{"proc_thread_num"})) {
    my $procregs = $g_conf{"proc_thread_num"};
    if (open(DDD,"-|","/bin/ps -eLf 2>/dev/null")) {
        while(<DDD>) {
            my $ps = $_;
            foreach my $procreg (@{$procregs}) {
                if ($ps =~ m/$procreg/) {
                    $sysinfo{$procreg} += 1;
                }
            }
        }
    }
}
        

open(DDD,">>$record_file") or die "Cant open $record_file: $!";
print DDD "##########",$record_time,"####################\n";
foreach my $k (keys %sysinfo) {
    print DDD $k,"=",$sysinfo{$k},"\n";
}
close(DDD);
sub hash_sort_value () {
    my $m = shift;
    my $ss;
    my $i = 0;
    foreach my $k (sort {$m->{$b} <=> $m->{$a}} keys %{$m}){
        #print $k,"=>",$m{$k},"\n";
        if ($i < 2) {
            $ss .= $k . ':' . $m->{$k} . ',';
        } elsif ($i == 2) {
            $ss .= $k . ':' . $m->{$k};
            last;
        }
        $i += 1;
    }
    return $ss;
}

sub send_trap () {
    my $tid = shift;
    my $msg = shift;
    foreach my $ts (split(',',$g_conf{'trapserver'})) {
        #my ($session, $error) = Net::SNMP->session(
        #    -hostname  => $ts,
        #        -version   => '2c',
        #    -community => $g_conf{'community'},
        #    -port      => 162,
        #    -timeout   => 30
        #);
        #my $r = $session->snmpv2_trap(
        #    -varbindlist => [
        #    '1.3.6.1.2.1.1.3.0', TIMETICKS, 1000,
        #    '1.3.6.1.6.3.1.1.4.1.0', OBJECT_IDENTIFIER, $tid,
        #    $tid, OCTET_STRING, $msg
        #    ],
        #);
    }
}

sub get_history () {
    #my $key = shift;
    #my $rr = "";
    my $s = 0;
    if (-s $record_file) {
        $s = (stat($record_file))[7];
        open(DDD, $record_file) or $opf = 1;
    } else {
        my ($sec, $min, $hour, $mday, $mon, $year, $wday) = localtime(time()-3600*24);
        $ldate = sprintf("%04d-%02d-%02d", $year+1900, $mon+1, $mday);
        my $rfile = $g_conf{'record_dir'} . $ldate . "_sys.info";
        $s = (stat($rfile))[7];
        open(DDD, $rfile) or $opf = 1;
    }
    if ($opf == 0) {
        if ($s >= 5000) {
            seek(DDD,0,2);
            seek(DDD,-5000,1);
        }
        while(<DDD>) {
            if (/^([^=]+)=(.+)/o) {
                $oldinfo{$1} = $2;
            }
        }
        close(DDD);
    }
    #return $rr;
}
