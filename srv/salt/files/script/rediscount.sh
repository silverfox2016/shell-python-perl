#! /bin/bash
#Name: redismontior.sh
#From: zhangm412@126.com <2014/08/06>
#Action: Zabbix monitoring redis plug-in

REDISCLI="/usr/local/redis/bin/redis-cli"
HOST="127.0.0.1"
PORT=6379

if [[ $# == 1 ]];then
    case $1 in
		hit)
			key_hit=`$REDISCLI -h $HOST -p $PORT info | grep "keyspace_hits"|cut -d : -f2|dos2unix`
			key_miss=`$REDISCLI -h $HOST -p $PORT info | grep "keyspace_misses"|cut -d : -f2|dos2unix`
			let sum=key_hit+key_miss
			result=$(echo "scale=2;${key_hit}/$sum"|bc)
			echo "${result}"|cut -d . -f 2
		;;
        version)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "redis_version" | awk -F':' '{print $2}'`
            echo ${result}
        ;;
        uptime)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "uptime_in_seconds" | awk -F':' '{print $2}'`
            echo $result
        ;;
        master_link_status)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "master_link_status" | awk -F':' '{print $2}'`
            if echo $result|grep -q up;then echo 0;else echo 1;fi
        ;;
        connected_clients)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "connected_clients" | awk -F':' '{print $2}'`
            echo $result
        ;;
        blocked_clients)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "blocked_clients" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_memory)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_memory" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_memory_rss)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_memory_rss" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_memory_peak)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_memory_peak" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_memory_lua)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_memory_lua" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_cpu_sys)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_cpu_sys" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_cpu_user)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_cpu_user" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_cpu_sys_children)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_cpu_sys_children" | awk -F':' '{print $2}'`
            echo $result
        ;;
        used_cpu_user_children)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "used_cpu_user_children" | awk -F':' '{print $2}'`
            echo $result
        ;;
        rdb_last_bgsave_status)
            result=`$REDISCLI -h $HOST -p $PORT info  | grep -w "rdb_last_bgsave_status" | awk -F':' '{print $2}' | grep -c ok`
            echo $result
        ;;
        aof_last_bgrewrite_status)
            result=`$REDISCLI -h $HOST -p $PORT info  | grep -w "aof_last_bgrewrite_status" | awk -F':' '{print $2}' | grep -c ok`
            echo $result
        ;;
        aof_last_write_status)
            result=`$REDISCLI -h $HOST -p $PORT info  | grep -w "aof_last_write_status" | awk -F':' '{print $2}' | grep -c ok`
            echo $result
        ;;
	instantaneous_ops_per_sec)
	    result=`$REDISCLI -h $HOST -p $PORT info  | grep -w "instantaneous_ops_per_sec" | awk -F':' '{print $2}'`
            echo $result
	;;

	total_commands_processed)
	    result=`$REDISCLI -h $HOST -p $PORT info  | grep -w "total_commands_processed" | awk -F':' '{print $2}'`
            echo $result
	;;
        *)
            echo -e "\033[33mUsage: $0 {connected_clients|blocked_clients|used_memory|used_memory_rss|used_memory_peak|used_memory_lua|used_cpu_sys|used_cpu_user|used_cpu_sys_children|used_cpu_user_children|rdb_last_bgsave_status|aof_last_bgrewrite_status|aof_last_write_status|instantaneous_ops_per_sec}\033[0m" 
        ;;
    esac
elif [[ $# == 2 ]];then
    case $2 in
        keys)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "$1" | grep -w "keys" | awk -F'=|,' '{print $2}'`
            echo $result
        ;;
        expires)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "$1" | grep -w "keys" | awk -F'=|,' '{print $4}'`
            echo $result
        ;;
        avg_ttl)
            result=`$REDISCLI -h $HOST -p $PORT info | grep -w "$1" | grep -w "avg_ttl" | awk -F'=|,' '{print $6}'`
            echo $result
        ;;
        *)
            echo -e "\033[33mUsage: $0 {db0 keys|db0 expires|db0 avg_ttl}\033[0m" 
        ;;
    esac
fi
