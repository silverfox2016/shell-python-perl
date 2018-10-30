#/bin/bash
USER=`cat /etc/passwd |grep -v nologin |awk -F':' '{if($3>=500)print $1}'`
xxx=(ec2-user mysql dale qingzhu.wang xianglong.meng qijun.song shuo.yang zabbix mogile vsftp gangliai mongodb mongo cacti)

for i in ${USER[@]}
        do
                if [[ ${xxx[@]} =~ $i ]];then
                        echo ""
                else
                        echo "$i"
                        userdel $i && echo "$i delete done" 
                fi
        done
