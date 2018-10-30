#!/bin/bash


ip=$(ifconfig em1 | awk -F: '/inet addr/ {print substr($2,1,15)}')

wget -SO /dev/null -e http_proxy=${ip} "$1"
