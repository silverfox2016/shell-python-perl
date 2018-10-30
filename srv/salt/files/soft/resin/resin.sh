#!/bin/bash
#made by xianglong.meng
#time : 2015.11.11
#install resin-3.11
path=/lekan
cd $path
if [ -f resin-3.1.11.tar.gz ];then
	tar zxf resin-3.1.11.tar.gz
else
	wget http://www.caucho.com/download/resin-3.1.11.tar.gz
	tar zxf resin-3.1.11.tar.gz
fi
cd resin-3.1.11
./configure --prefix=/usr/local/resin  --enable-64bit && make && make install

if [ $? == 0 ];then
	echo "resin is install success"
else 
	echo "resin is install failed"
fi

if [ -f resin_conf.tar.gz ];then
	tar zxf resin_conf.tar.gz -C /usr/local/resin/
fi
