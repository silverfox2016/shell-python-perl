#!/bin/bash

ip_CDN_forCustomer=( 221.203.3.96 221.203.3.97 221.203.3.98 60.2.61.123 61.163.51.146 60.209.4.39 112.245.17.194 112.245.17.195 183.95.81.2 123.162.189.124 118.123.114.58 61.183.42.201 61.155.137.200 61.155.137.201 61.155.137.202 115.238.145.84 119.145.147.90 119.147.152.130 119.147.152.133 218.16.119.242 117.27.146.93 112.245.17.200 112.245.17.199)
ip_CDN_SourceSite=( 113.105.147.130 113.105.147.131 113.105.147.132 112.245.17.196 112.245.17.201 112.245.17.202 )
ip_RES_SourceSite=( 119.147.152.132 58.68.228.46 112.245.17.198 )
ip_Copyrightaudit=( 182.92.160.53 )
ip_Entrance=( 58.68.228.37 58.68.228.38 58.68.240.41 )
ip_Ipadapter=( 54.223.173.51)
ip_NS_DNS=( 58.68.228.43 )
ip_appLogicService_core=( 58.68.240.34 58.68.240.35 58.68.240.36 58.68.240.40 58.68.240.42 58.68.240.43 )
ip_appLogicService_distributed=( 54.223.167.183 )
ip_appLogicService_AD=( 58.68.240.44 58.68.240.47 54.223.167.183 )
ip_MQ_active=( 58.68.228.43 182.92.160.53 )
ip_DBmysql_core=( 58.68.240.37 )
ip_DBmysql_distributed=( 54.223.188.236 58.68.240.45 )
ip_DBmongo_distributed=( 54.223.173.51 115.29.173.218 182.92.160.53 )
ip_DBmysql_bak=( 58.68.228.39 )
ip_MoniAutomana=( 115.29.173.218 218.241.129.62 )
ip_StepTread=( 113.105.147.134 58.68.228.43 )
ip_Log_Statistic=( 115.29.210.215 54.223.144.24 )
ip_GrayScaleRelease=( 182.92.160.53 )
ip_AppleTest=( 54.223.188.47 )
ip_Thirdparty=( 61.240.137.201)
#注意这里由于掩码是16，所以192.168.168.253.0 192.168.0.0是重复，会报错：
#ipset v6.11: Element cannot be added to the set: it's already added
#192.168.253.0  192.168.0.0  10.100.0.0  172.31.0.0，所以应该写如：
ip_Intranet=(192.168.0.0  10.100.0.0  172.31.0.0)
role_host=(CDN_forCustomer CDN_SourceSite RES_SourceSite Copyrightaudit Entrance Ipadapter NS_DNS appLogicService_core appLogicService_distributed appLogicService_AD MQ_active DBmysql_core DBmysql_distributed DBmongo_distributed DBmysql_bak MoniAutomana StepTread Log_Statistic GrayScaleRelease AppleTest Thirdparty Intranet)

#保存上次
ipset save > /opt/data/scripts/ipset.scripts.last
#清空列表
ipset -X
#创建分组
for j in ${role_host[@]}
do
ipset -N $j nethash
done
#为每个分组添加IP成员
for i in ${ip_CDN_forCustomer[@]}
do
ipset -A CDN_forCustomer "$i/32"
done


for i in ${ip_CDN_SourceSite[@]}
do
ipset -A CDN_SourceSite "$i/32"
done


for i in ${ip_RES_SourceSite[@]}
do
ipset -A RES_SourceSite "$i/32"
done


for i in ${ip_Copyrightaudit[@]}
do
ipset -A Copyrightaudit "$i/32"
done

for i in ${ip_Entrance[@]}
do
ipset -A Entrance "$i/32"
done

for i in ${ip_Ipadapter[@]}
do
ipset -A Ipadapter "$i/32"
done

for i in ${ip_NS_DNS[@]}
do
ipset -A NS_DNS "$i/32"
done

for i in ${ip_appLogicService_core[@]}
do
ipset -A appLogicService_core "$i/32"
done

for i in ${ip_appLogicService_distributed[@]}
do
ipset -A appLogicService_distributed "$i/32"
done

for i in ${ip_appLogicService_AD[@]}
do
ipset -A appLogicService_AD "$i/32"
done

for i in ${ip_MQ_active[@]}
do
ipset -A MQ_active "$i/32"
done

for i in ${ip_DBmysql_core[@]}
do
ipset -A DBmysql_core "$i/32"
done


for i in ${ip_DBmysql_distributed[@]}
do
ipset -A DBmysql_distributed "$i/32"
done

for i in ${ip_DBmongo_distributed[@]}
do
ipset -A DBmongo_distributed "$i/32"
done

for i in ${ip_DBmysql_bak[@]}
do
ipset -A DBmysql_bak "$i/32"
done


for i in ${ip_MoniAutomana[@]}
do
ipset -A MoniAutomana "$i/32"
done

for i in ${ip_StepTread[@]}
do
ipset -A StepTread "$i/32"
done

for i in ${ip_Log_Statistic[@]}
do
ipset -A Log_Statistic "$i/32"
done

for i in ${ip_GrayScaleRelease[@]}
do
ipset -A GrayScaleRelease "$i/32"
done


for i in ${ip_AppleTest[@]}
do
ipset -A AppleTest "$i/32"
done


for i in ${ip_Thirdparty[@]}
do
ipset -A Thirdparty "$i/32"
done


for i in ${ip_Intranet[@]}
do
ipset -A Intranet "$i/16"
done


ipset save > /opt/data/scripts/ipset.scripts
#me end
