#!/bin/bash
#made by yangshuo
#date 2016/11/09
#install mogilefs-server
cd /root
if [ -f MogileFS-Server-2.59.tar.gz ];then
        tar zxf MogileFS-Server-2.59.tar.gz
fi

moudel=(
YAML
Danga::Socket
IO::AIO
MogileFS::Client
Net::Netmask
Perlbal
Sys::Syscall)

for i in ${moudel[@]}
    do
            yes | cpan $i
    done

cd MogileFS-Server-2.59
perl Makefile.PL
make
make install

if [ $? == 0 ];then
    echo "MogileFS-Server is installed"
else
    echo "MogileFS-Server is not install"
fi

