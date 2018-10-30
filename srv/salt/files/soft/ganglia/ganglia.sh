#!/bin/bash
#made by xianglong.meng
#time : 2015.11.11
#install ganglia-3.6.1
path=/lekan
cd $path
if [ -f ganglia-3.6.1.tar.gz ];then
	tar zxf ganglia-3.6.1.tar.gz
fi
yum -y install gcc gcc-c++ libpng freetype zlib libdbi libxml2 libxml2-devel pkg-config glib pixman pango pango-devel freetye-devel fontconfig cairo cairo-devel libart_lgpl libart_lgpl-devel apr-devel apr-util-devel libconfuse libconfuse-devel pcre-devel 
cd ganglia-3.6.1
./configure --prefix=/usr/local/ganglia  && make && make install

if [ $? == 0 ];then
	echo "ganglia is install success"
else 
	echo "ganglia is install failed"
fi

