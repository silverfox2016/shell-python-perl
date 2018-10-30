#!/bin/bash
#made by xianglong.meng
#time 2015.11.12
#use install openssh and openssh 

path="/lekan/src"
ssh_rpm="openssh-6.8p1-1.x86_64.rpm"
ssl_rpm="openssl-1.0.1p-1.x86_64.rpm"
file="libcrypto.so.1.0.0"

cd $path

[ -f $ssl_rpm ] && rpm -ivh $ssl_rpm
[ -f $ssh_rpm ] && rpm -ivh $ssh_rpm --nodeps --force
[ -f /usr/lib64/$file ] || cp $path/$file /usr/lib64/$file

/usr/bin/expect  <<EOF
spawn ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key
expect "Enter*"
send "\r"
expect "Enter*"
send "\r"

spawn ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key
expect "Enter*"
send "\r"
expect "Enter*"
send "\r"
expect "*#"
exit
EOF


