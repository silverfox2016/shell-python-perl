#df -TH | awk '$1 ~ /dev/ { count[substr($1,0,8)]++}END{for ( i in count ) print count[i],i}' | wc -l
#for i in $(find /usr/local/webserver/squid* -name '*.log');do > $i;done
#find /usr/local/webserver/squid* -name '*squid.conf*' | xargs grep -E "cache.log|sorte.log"
#for i in `ls /usr/local/webserver/| grep squid` ;do /usr/local/webserver/$i/sbin/squid -k reconfigure; done
#!/bin/bash
#nowproject=$(ps -ef | grep java | grep -v grep | awk -F "=" '{print $NF}' | cut -d "/" -f 6)
#nowproject=$(ps -ef |grep resin | grep -v grep |  awk '{print $(NF-1)}')
#project=$(ls -l /lekan/project/|awk '/^d/ {print $NF}')
#
#for i in ${project[@]}
#do
#        for a in ${nowproject[@]}
#        do
#
#if [ ${i} = ${a} ] ; then
#        chkconfig ${i} on
#        else
#        chkconfig ${i} off
#fi
#done
#done

for i in `ps -ef | grep tomcat | grep -v grep | awk -F "=" '{print $NF}' | cut -d "/" -f 6`
do 
        chkconfig --list | grep '$i'
done
