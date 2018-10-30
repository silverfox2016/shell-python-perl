#!/bin/sh
ZabbixHost=`grep -E "^Hostname"  /usr/local/zabbix/etc/zabbix_agentd.conf|awk -F "="  '{print $2}'`
Check_Desc="Check Disk Read Only"
houzhui=`date "+%Y%m%d"`
df -Th |egrep -v -i 'tmpfs|nfs'|awk '$(NF-1)~/%/{print $NF}'|grep '^/'|sort -u|while read line;do
    echo "zabbix_test" > ${line}/zabbix_test_${houzhui}
    if [ $? -ne 0 ];then
	    /usr/local/zabbix/bin/zabbix_sender -z 54.223.210.142 -s "${ZabbixHost}" -k "is_read_only" -o "${line} read only"
        exit 1
    fi  
    \rm ${line}/zabbix_test_${houzhui}
done
if [ $? -eq 0 ];then
    /usr/local/zabbix/bin/zabbix_sender -z 54.223.210.142 -s "${ZabbixHost}" -k "is_read_only" -o "all disk is ok!"
fi
