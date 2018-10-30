#!/bin/sh
ss=`/sbin/ip -4 -o addr show | awk '{print $4}' | awk -F/ '{print $1}' | grep -v -E "^(127|192|10)\."`
ff=`grep '^id: ' /etc/salt/minion | awk '{print $2}'`
echo "$ss $ff"
