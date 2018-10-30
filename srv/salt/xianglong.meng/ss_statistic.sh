#!/bin/bash
#统计每个项目连接mysql主从及redis主从的数量
source /etc/profile

path=/lekan/logs/ss_statistic
DateTime=$(date +%F-%H-%M-%S)
Day=$(date +%F)
ss_tmp=/tmp/ss_tmp.txt
ps_tmp=/tmp/ps_tmp.txt
#获取java项目的项目名及PID
#全部项目太多，只提取了主要项目
#ps aux|awk '{if (($(NF-8) ~ "root-directory") && ($11 ~ java)) print "ProjectName:"$(NF-1),"PID:"$2}' > $ps_tmp

ps aux|grep tomcat |grep -v grep |awk '{sub(".*/","",$(NF-3))}{print "ProjectName:"$(NF-3),"PID:"$2}'|grep -E 'lekan-api|lekan-huashu|kids-new-ios|kids-new-upgrade' > $ps_tmp
PID=($(awk -F' |:' '{print $4}' $ps_tmp))
Project=($(awk -F' |:' '{print $2}' $ps_tmp))
[ -f $path/${Day}.txt ] || touch $path/${Day}.txt
ss -anp > $ss_tmp
echo -e "====================$DateTime====================\n" >> $path/${Day}.txt
total=`cat $ss_tmp|wc -l`
mysql_master=`grep -c '44:3306' $ss_tmp`
mysql_slave=`grep -c '63:3306' $ss_tmp`
redis_master=`grep '63:6379' $ss_tmp|grep -c java`
redis_slave=`grep '1:6379' $ss_tmp|grep -c java`

echo -e "SS Total: \t $total\n" >> $path/${Day}.txt
echo -e "Mysql master: \t $mysql_master\n" >> $path/${Day}.txt
echo -e "Mysql slave: \t $mysql_slave\n" >> $path/${Day}.txt
echo -e "Redis slave: \t $redis_master\n" >> $path/${Day}.txt
echo -e "Redis slave: \t $redis_slave\n" >> $path/${Day}.txt

for i in `seq 0  3`
    do 
        echo -e "-----------------${Project[$i]}----------------\n" >> $path/${Day}.txt
        #mysql 统计
        echo -e "Mysql connects:\n" >> $path/${Day}.txt
        awk -v P=${PID[$i]} '{if (($5 ~ 3306) && ($6 ~ P)) count[$5]++}END{for (i in count) {if (i ~ "253.44") {printf ("Total:\t%d\nType:\t%s\n",count[i],"MysqlMaster 253.44")} else {printf ("Total:\t%d\nType:\t%s\n",count[i],"MysqlSlave 253.63")}}}' $ss_tmp >> $path/${Day}.txt
        #redis 统计
        echo -e "\nRedis connects:\n" >> $path/${Day}.txt
        awk -v P=${PID[$i]} '{if (($5 ~ 6379) && ($6 ~ P)) count[$5]++}END{for (i in count) {if (i ~ "253.63") {printf ("Total:\t%d\nType:\t%s\n",count[i],"RedisMaster 253.63")} else {printf ("Total:\t%d\nType:\t%s\n",count[i],"RedisSlave 127.0.0.1")}}}' $ss_tmp >> $path/${Day}.txt

    done
