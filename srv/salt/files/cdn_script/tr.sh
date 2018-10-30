#!/bin/bash
count(){
local dev=em1
[ -f /etc/sysconfig/network-scripts/ifcfg-em1 ] || dev=eth0
rx=$(grep "${dev}" /proc/net/dev|awk '{print $2}')
tx=$(grep "${dev}" /proc/net/dev|awk '{print $10}')
let tx=$tx/1024/1024
let rx=$rx/1024/1024
echo "$rx $tx"
}
count
