#!/bin/bash
#################################################
#    监控redis状态
# author:song
#################################################
cli=/usr/local/redis/bin/redis-cli
result=$($cli ping   2>&1)
if echo $result|grep -q 'PONG';
then
	echo "1"
else
	echo "0"
fi
