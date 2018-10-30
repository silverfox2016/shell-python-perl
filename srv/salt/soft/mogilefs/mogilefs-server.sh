#!/bin/bash
#made by yangshuo
#date 2017/9/5
#install mogilefs-server
moudel=(
YAML
CPAN::SQLite
Module::Signature
IO::AIO
MogileFS::Utils
DBD:mysql
MogileFS::Network
MogileFS::Server)


for i in ${moudel[@]}
    do
            yes | cpan $i
    done

if [ $? == 0 ];then
    echo "MogileFS-Server is installed"
else
    echo "MogileFS-Server is not install"
fi

