#!/bin/bash
time=$(date '+%Y-%m-%d-%H:%M')
port=(`cat /etc/ssh/sshd_config | grep  Port | grep -v Ports | grep -v -w 22 | awk '{print $2}'`)
if [ ${#port[@]} -le 0 ]
        then :
        else
                echo ${port[@]}
                sudo mv /etc/ssh/sshd_config /etc/ssh/sshd_config.$time
                sudo cp /usr/local/zabbix/bin/sshd_config.bak /etc/ssh/sshd_config
                sudo /etc/init.d/sshd restart 
fi
