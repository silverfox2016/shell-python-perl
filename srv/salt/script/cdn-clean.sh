#!/bin/bash

id=$1
Episode=$2

DR=(
600
750
900
1200
1600
2500
4000)


if [ "$3" == en  ];then

for a in ${DR[@]}
do
        for i in ${Episode}
        do
                for b in {0..100}
                do
                    curl -I -m 10 -o /dev/null -s -w '%{http_code}' -H Host:vod1.lekan.com "http://127.0.0.1:9000/purge/video1/${id:3:3}/${id:4:2}/${id:0:6}E${i}/en/video.ssm/${id:0:6}E${i}-en-${a}-${b}.ts"
                done
        done
done

else

for a in ${DR[@]}
do
        for i in `seq ${Episode}`
        do
                for b in {0..100}
                do
                    curl -I -m 10 -o /dev/null -s -w '%{http_code}' -H Host:vod1.lekan.com "http://127.0.0.1:9000/purge/video1/${id:3:3}/${id:4:2}/${id:0:6}E${i}/cn/video.ssm/${id:0:6}E${i}-cn-${a}-${b}.ts"
                done
        done
done

fi



echo $"Usage: example salt -N cdncache1 cmd.script salt://script/cdn-clean.sh args='134961E6 6 en'"
