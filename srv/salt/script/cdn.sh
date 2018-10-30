#!/bin/bash


for i in {1..52}
        do 
          curl /dev/null -s -w '%{http_code}' -H Host:vod1.lekan.com 'http://127.0.0.1:9000/purge/video1/949/49/134949E'$i'/cn/video.ssm/134949E'$i'-cn-600-0.ts'
        done
