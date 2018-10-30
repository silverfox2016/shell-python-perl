    #!/bin/bash
    #初始化配置：
     /sbin/iptables-save > /etc/sysconfig/iptables.last
     /sbin/iptables-save > /opt/data/scripts/iptables.scripts.last
	 /sbin/iptables -F
	 /sbin/iptables -X
	 /sbin/iptables -P INPUT DROP
	 /sbin/iptables -P OUTPUT ACCEPT
	 /sbin/iptables -P FORWARD ACCEPT
    #应用conntrack表
	 /sbin/iptables -A INPUT -m conntrack --ctstate ESTABLISHED -j ACCEPT 
    #允许全网用户访问本机80端口
	 /sbin/iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
    #源站主机授信
     /sbin/iptables -A INPUT -m set --match-set CDN_SourceSite src  -m conntrack --ctstate NEW -j ACCEPT
    #管理机，跳板机，监控机授信
     /sbin/iptables -A INPUT -m set --match-set MoniAutomana  src -m conntrack --ctstate NEW -j ACCEPT
     /sbin/iptables -A INPUT -m set --match-set StepTread src -m conntrack --ctstate NEW -j ACCEPT
    #ganglia Multicast
	 /sbin/iptables -A INPUT  -d 239.2.11.71 -j ACCEPT  
    #内网授信
     /sbin/iptables -A INPUT -m set --match-set Intranet src -m conntrack --ctstate NEW -j ACCEPT 
    #本地环回
     /sbin/iptables -A INPUT -i lo -j ACCEPT   
    #Ipadapter/DBmongo_distributed授信
     /sbin/iptables -A INPUT -m set --match-set Ipadapter src -m conntrack --ctstate NEW -j ACCEPT
     /sbin/iptables -A INPUT -m set --match-set DBmongo_distributed src -m conntrack --ctstate NEW -j ACCEPT  
    #ping和OUTPUT链上应用conntrack表 
#    /sbin/iptables -A INPUT -p icmp -m state --state RELATED,ESTABLISHED -j ACCEPT
#    /sbin/iptables -A OUTPUT -p icmp -m state --state NEW,RELATED,ESTABLISHED -j ACCEPT
	 /sbin/iptables -A OUTPUT -m conntrack --ctstate NEW -j ACCEPT

    #保存最新配置
	 /sbin/iptables-save > /etc/sysconfig/iptables
	 /sbin/iptables-save > /opt/data/scripts/iptables.scripts 
	 /sbin/chkconfig iptables on
