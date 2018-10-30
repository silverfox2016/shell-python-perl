#!/bin/bash

rm -rf /home/shuo.yang/PROJECT.TXT

PID=$(netstat -lntp | awk '$0~ ":(6|8|9)[^3]" {print $NF}' | awk -F "/" '/java/ {print $1}'|sort -u)

IP=$(ip r| awk '/192.*253/ {print $NF}')

for pid in ${PID[@]}
	do
		javaport=$(netstat -lntp | grep -oP '(6|8|9)\d{3}.'*${pid}''| awk '{print $1}')
		PROJECT=$(ps -e -opid -ocmd | grep ${pid} | grep -oP '.*(?<=Dcatalina.base=).*?(?= )'|awk -F "/" '{print $NF}' )
		TOMCAT_HOME=$(ps -e -opid -ocmd | grep ${pid} | grep -v grep | grep -oP '(?<=Dcatalina.base=).*?(?= )')
		PROJECT_CONFIG_PATH=${TOMCAT_HOME}/conf/server.xml
		for port in ${javaport[@]}
do	
#		CONFIG_PORT=$(grep -oP '<C.*port="'${port}'"' /usr/local/tomcat/tomcat-instance/"${PROJECT}"/conf/server.xml | grep  -oP '\d{4}')
		CONFIG_PORT=$( awk -F "\"" '/<C.*'${port}'/ {print $6,$2}' /usr/local/tomcat/tomcat-instance/"${PROJECT}"/conf/server.xml )

		echo "PROJECT ${PROJECT} ${CONFIG_PORT% *} PORT ${CONFIG_PORT:0-4} "  >>/home/shuo.yang/PROJECT.TXT
done
done

