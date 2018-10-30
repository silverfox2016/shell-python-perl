#!/bin/bash
config=/usr/local/zabbix/etc/zabbix_agentd.conf
execfile=/usr/local/zabbix/script/ss.sh

sed -i '/UserParameter=iptstate/d' $config 
sed -i '/###ss/d' $config 
cat >>$config<<EOF

###ss
UserParameter=iptstate.tcp.[*],/bin/bash /usr/local/zabbix/script/ss.sh \$1
UserParameter=iptstate.[*],/bin/bash /usr/local/zabbix/script/ss.sh \$1

EOF

cat >$execfile<<EOF
#!/bin/bash
#made by xianglong.meng 20150806
#use ss replace netstat

type=\$1

case \$type in 
	TCP|tcp)
		ss -ta |wc -l;;
	UDP|udp)
		ss -ua |wc -l;;			 
	CLOSE_WAIT|close_wait)
		ss -ta |grep -i ^CLOSE-WAIT |wc -l;;
	ESTABLISHED|established)
		ss -ta |grep -i ^ESTAB |wc -l;;
	FIN_WAIT1|fin_wait1)
		ss -ta |grep -i ^FIN-WAIT-1 |wc -l;;
	FIN_WAIT2|fin_wait2)
		ss -ta |grep -i ^FIN-WAIT-2 |wc -l;;
	LAST_ACK|last_ack)
		ss -ta |grep -i ^LAST-ACK |wc -l;;
	CLOSING|closing)
		ss -ta |grep -i ^CLOSING |wc -l;;
	LISTEN|listen)
		ss -ta |grep -i ^LISTEN |wc -l;;
	SYN_RECV|syn_recv)
		ss -ta |grep -i ^SYN-RECV |wc -l;;
	SYN_SENT|syn-sent)
		ss -ta |grep -i ^SYN-SENT |wc -l;;
	TIME_WAIT|time_wait)
		ss -ta |grep -i ^TIME-WAIT |wc -l;;
	*)
		echo "USAGE: \$0 (TCP|tcp UDP|udp | CLOSE_WAIT|close_wait | ESTABLISHED|established | FIN_WAIT1|fin_wait1 | FIN_WAIT2|fin_wait2 | LAST_ACK|last_ack CLOSING|closing | LISTEN|listen | SYN_RECV|syn_recv | SYN_RECV|syn_recv | TIME_WAIT|time_wai ) "
	;;
esac
	
EOF
chmod a+x $execfile
/etc/init.d/zabbix_agentd restart
[ $? -eq 0 ] && echo "is ok!"
