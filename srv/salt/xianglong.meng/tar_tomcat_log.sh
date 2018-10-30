#!/bin/bash
year=`date +%Y`
dirPath="/lekan/logs/tomcat"
cd $dirPath
find . \( -name "*log.*" -o -name "*${year}*.log" \) ! -name "*.gz" |xargs gzip
