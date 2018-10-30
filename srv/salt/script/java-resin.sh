#!/bin/bash

PID=$(netstat -lntp | awk '$4~ ":::(6|8|9)" {print $NF}'  | awk -F "/" '{print $1}')
JAVAPORT=$(netstat -lntp | grep -oP ':{3}(8|9)\d{3}' | awk -F ":" '{print $4}')


for pid in ${PID[@]}
    do
        for javaport in ${JAVAPORT[@]}
            do
               if [ ${pid}x = ${pid}x ] ; then
                   if [ ${javaport}x = ${javaport}x ] ; then
                PROJECT=$(ps -e -opid -ocmd | grep ${pid} | grep -v grep | grep resin | awk '{print $(NF-1)}')
                PROJECT_CONFIG_PATH=$(ps -e -opid -ocmd | grep ${pid} | grep -oP '/usr/local/resin/conf/resin-.*.conf')
                CONFIG_PORT=$(grep -oP '<http.*port="\d{4}"' /usr/local/resin/conf/resin-"${PROJECT}".conf | grep -oP '\d{4}')
                      echo "PROJECT:${PROJECT} PORT:${CONFIG_PORT} " | grep -oP 'PROJECT.*:\d+' | sort -u >>resin-PROJECT.TXT
                  else
                    continue;
                   fi
               fi
            done
    done
