#!/bin/bash
config=/usr/local/zabbix/etc/zabbix_agentd.conf
execfile=/usr/local/zabbix/script/ss.sh
if grep -v discovery $config|grep app.port;then
    sed -i '/app.port/d' $config
cat >>$config<<EOF
##appss
UserParameter=app.port.listen,/bin/bash /usr/local/zabbix/etc/check_port.sh
UserParameter=app.port.[*],ss -ln | grep -wc \$1 
EOF
grep "app.port" $config
/etc/init.d/zabbix_agentd restart
fi
