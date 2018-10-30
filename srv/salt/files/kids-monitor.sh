#!/bin/bash
#临时发现kids-new-ios 的redis错误，超过3次，重启项目
#为避免发生问题后，当天日志错误计数肯定大于3，将该日志的后500行统计
date=$(date +%F-%H:%M)
log=/home/xianglong.meng/kids-monitor.log
if [[ `tail -n 500 /lekan/logs/tomcat/jvm-kids-new-ios|grep -c "Could not get a resource from the pool"` -ge 3 ]];then
    echo "Time: $date" >> $log
    echo 'The kids-new-ios has problem, Will restart this project' >> $log
    ps aux|grep kids-new-ios|grep -v grep |awk '{system("kill -9 " $2)}' 
    sleep 3
    while true;do
	/sbin/service kids-new-ios restart
        sleep 3
    	if [ $(netstat -tnlp|grep 8084|wc -l) == 1 ];then
	     echo "kids-new-ios is start success" >>  $log
	     break
	fi
	sleep 1
    done
else
    echo "It'ok"
fi
