#!/bin/sh

proc=`ps aux 2>/dev/null |grep 'cts_screenshots.pl' |grep -v grep |wc -l`
time=`date`;

if [[ $proc -eq '0' ]]; then
    echo "$time: proc not exists."
    cd /lekan/xing/CtsVideoScreenshot/
	perl cts_screenshots.pl 2>&1 1>screenshots_work.log
else
    echo "$time: proc alive."
fi

