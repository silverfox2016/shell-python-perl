#!/bin/bash
#made by xianglong.meng 20150806
#use ss replace netstat

type=$1

case $type in 
	TCP|tcp)
		ss -tna |wc -l;;
	UDP|udp)
		ss -ua |wc -l;;			 
	CLOSE_WAIT|close_wait)
		ss -tna |grep -i ^CLOSE-WAIT |wc -l;;
	ESTABLISHED|established)
		ss -tna |grep -i ^ESTAB |wc -l;;
	FIN_WAIT1|fin_wait1)
		ss -tna |grep -i ^FIN-WAIT-1 |wc -l;;
	FIN_WAIT2|fin_wait2)
		ss -tna |grep -i ^FIN-WAIT-2 |wc -l;;
	LAST_ACK|last_ack)
		ss -tna |grep -i ^LAST-ACK |wc -l;;
	CLOSING|closing)
		ss -tna |grep -i ^CLOSING |wc -l;;
	LISTEN|listen)
		ss -tna |grep -i ^LISTEN |wc -l;;
	SYN_RECV|syn_recv)
		ss -tna |grep -i ^SYN-RECV |wc -l;;
	SYN_SENT|syn-sent)
		ss -tna |grep -i ^SYN-SENT |wc -l;;
	TIME_WAIT|time_wait)
		ss -tna |grep -i ^TIME-WAIT |wc -l;;
    inuse)
        cat /proc/net/sockstat|grep TCP|awk '{print $3}';;
    orphan)
        cat /proc/net/sockstat|grep TCP|awk '{print $5}';;
    tw)
        cat /proc/net/sockstat|grep TCP|awk '{print $7}';;
    alloc)
        cat /proc/net/sockstat|grep TCP|awk '{print $9}';;
    mem)
        cat /proc/net/sockstat|grep TCP|awk '{print $11}';;
	*)
		echo "USAGE: $0 (TCP|tcp UDP|udp | CLOSE_WAIT|close_wait | ESTABLISHED|established | FIN_WAIT1|fin_wait1 | FIN_WAIT2|fin_wait2 | LAST_ACK|last_ack CLOSING|closing | LISTEN|listen | SYN_RECV|syn_recv | SYN_RECV|syn_recv | TIME_WAIT|time_wai ) "
	;;
esac
	
