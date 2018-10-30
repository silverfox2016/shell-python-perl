#!/bin/bash
if ss -l|head -1|grep -q State;then
    portarray=($(ss -ln|tail -n +2|awk '{print $4}'|grep -v 127|awk -F':' '{print $NF}'|sort -n |uniq))
else
    portarray=($(ss -ln|tail -n +2|awk '{print $3}'|grep -v 127|awk -F':' '{print $NF}'|sort -n |uniq))
fi
length=${#portarray[@]}
printf "{\n"
printf  '\t'"\"data\":["
for ((i=0;i<$length;i++))
do
        printf '\n\t\t{'
        printf "\"{#TCP_PORT}\":\"${portarray[$i]}\"}"
        if [ $i -lt $[$length-1] ];then
                printf ','
        fi
done
printf  "\n\t]\n"
printf "}\n"
