#!/bin/bash
w | egrep -v "USER|user|tty" | awk '{print $1,$2,$3,$4}' > /tmp/w-ip
n=()
while read line
do
array=($line)
    if [ ${array[2]} == 106.120.246.26 ] || [ ${array[2]} == 111.207.177.88 ]
        then
                continue
        else
                n=(${n[@]}#${array[0]}-${array[1]}-${array[2]}-${array[3]})
                sudo skill -9 ${array[1]}
    fi
done < /tmp/w-ip
n=($(awk -v RS=' ' '!a[$1]++' <<< ${n[@]}))
echo ${n[@]}
