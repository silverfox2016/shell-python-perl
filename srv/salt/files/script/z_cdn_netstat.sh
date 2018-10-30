#!/bin/bash
config=/usr/local/zabbix/etc/zabbix_agentd.conf
execfile=/usr/local/zabbix/script/ss.sh
if grep -q "cdn.port" $config;then
    sed -i '/cdn.port/d' $config
cat >>$config<<EOF
##cdnss
UserParameter=cdn.port.listen,/bin/bash /usr/local/zabbix/etc/check_port.sh
UserParameter=cdn.port.[*],ss -ln | grep -wc \$1 
EOF
grep "cdn.port" $config
/etc/init.d/zabbix_agentd restart
fi
