#!/bin/bash


url=$1


curl -sv -I -m 10 -o /dev/null -H Host:vod1.lekan.com http://127.0.0.1:9000/purge/${url:68}
