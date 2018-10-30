#!/bin/bash
year=`date +%Y`
dirPath="/usr/local/resin/log"
cd $dirPath
find . \( -name "*log.*" -o -name "*${year}*.log" \) ! -name "*.gz" |xargs gzip
