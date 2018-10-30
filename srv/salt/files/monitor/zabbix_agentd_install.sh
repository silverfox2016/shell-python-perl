#!/bin/bash
#made by xianglong.meng 
#2015.11.11
#user add 
path=/lekan/
file="zabbix_agentd.tar.gz"
dst_path=/usr/local/
cd $path
[ -f $file ] && tar zxf $file -C $dst_path 
 
useradd -M -s /sbin/nologin -r zabbix

mv ${dst_path}zabbix_agentd /etc/init.d/

[ -x /etc/init.d/zabbix_agentd ] || chmod +x /etc/init.d/zabbix_agentd

echo "Beginning chkconfig add and on"
chkconfig --add zabbix_agentd && chkconfig zabbix_agentd on
echo "service starting!"
service zabbix_agentd start
