#!/bin/bash
####################################
#		resin监控
#song
####################################

fond_red="\033[31m"
fond_end="\033[0m"
fond_green="\033[32m"
portlist=(
8084:kids-new-ios
8081:lekan-api
9301:lekan-huashu
8093:kids-ebook
8089:kids-mac
8094:kids-new-upgrade
8087:kids-pc
8091:kids-win8
8085:lekan-book
8097:lekan-diy
8088:lekan-ebook-api
8082:lekan-film
8095:lekan-game
8086:lekan-mv
8096:pay-site
8080:web
)

hosts=(
#bgp-rein
58.68.240.34
58.68.240.35
58.68.240.36
58.68.228.37
58.68.240.40
58.68.240.42
58.68.240.43
#bgp-nginx
#ali
)
ip=58.68.240.35
port=8084
project=kids-new-ios
json_decode(){
	local var=$1
	local item=$2
	#echo $var| sed -e 's/"//g' -e 's/{//g' -e 's/}//g'  -e 's/:/=/g'
	echo $var|sed -e 's/.*'$item'"://' -e 's/,.*//' -e 's/["}]//g'
}

check(){
	local port=$1
	local project=$2
	result=$(curl -s -m 10 -w  %{http_code} http://${ip}:$port/monitoringInterface.action )
	http_code=${result:$((${#result}-3))}
	if [  $http_code -eq 200 ] && ! echo $result|grep -q "404";then
		#str=$(json_decode "${result:0:$((${#result}-3))}")
		jstr=${result:0:$((${#result}-3))}
		redisConnect=$(json_decode "$jstr" "redisConnect")
		dbConnect=$(json_decode "$jstr" "dbConnect")
		version=$(json_decode "$jstr" "version")
		status=$(json_decode "$jstr" "status")
		echo -n "host:$ip |"
		echo -n "$project $port:"
		if [ ${redisConnect#*=} -eq 0 ]; then echo -n -e "$fond_green redis连接 成功 $fond_end";else echo -n -e "$fond_red redis连接 失败 $fond_end";fi
		if [ ${dbConnect#*=} -eq 0 ]; then echo -n -e "$fond_green mysql连接 成功 $fond_end";else echo -n -e "$fond_red mysql连接 失败 $fond_end";fi
		echo -n "项目版本号：${version#*=}"
		echo  "status=${status#*=}"
	else
		if [ $http_code -ne 000 ] && [ $http_code -ne 200 ] && [ $http_code -ne 404 ]
		then
			echo -e "host:$ip |$project $port: $fond_red  端口连接 失败 $fond_end http_code=$http_code"
		fi

	fi
}
for ip in ${hosts[@]}
do
	[ $ip == "58.68.228.38" ] && echo "nginx 代理"
	for line in ${portlist[@]}
	do
		check "${line%:*}" "${line#*:}"
	done
	echo ""
done
