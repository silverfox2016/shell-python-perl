#!/bin/bash
#made by xianglong.meng
#time : 2015.11.11
path=/lekan
file=java-1.8.0_05_240.34_2015-01-06.tar.bz2
java_home=/usr/local/java

cd $path
tar jxf $file
mv java $java_home

echo "export JAVA_HOME=/usr/local/java" >> /etc/profile.d/java.sh
echo "export CLASSPATH=.:\${JAVA_HOME}/lib:\${JRE_HOME}/jre/lib" >> /etc/profile.d/java.sh 
echo "export PATH=.:\$PATH:\$JAVA_HOME/bin" >> /etc/profile.d/java.sh

source  /etc/profile.d/java.sh

if [ -h /usr/bin/java ];then
	rm -f /usr/bin/java
	ln -sv /usr/local/java/bin/java /usr/bin/java
fi

java -version
