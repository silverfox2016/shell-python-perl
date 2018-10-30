#!/bin/bash 
  
watch_mem() 
{ 
  memtotal=`cat /proc/meminfo |grep "MemTotal"|awk '{print $2}'` 
  memfree=`cat /proc/meminfo |grep "MemFree"|awk '{print $2}'` 
  cached=`cat /proc/meminfo |grep "^Cached"|awk '{print $2}'` 
  buffers=`cat /proc/meminfo |grep "Buffers"|awk '{print $2}'` 
 
  mem_usage=$((100-memfree*100/memtotal-buffers*100/memtotal-cached*100/memtotal))
   #echo "---------------------------------"
   #echo -e  "\tMemory Utilization"
   #echo "---------------------------------"
   echo -e "\033[0;31mMemory_used  $mem_usage%\033[0m "
}

watch_mem
watch_hd() 
{ 
   disk_usage=`df | sed 1d | awk '{print $2,$3}' | awk ' {size+=$1;user+=$2;}END{print user*100/size}'`
   #echo "--------------------------------"
   #echo -e "\tHard Utilization" 
   #echo "--------------------------------"
   echo -e "\033[0;31mHard_disk_used $disk_usage%\033[0m"

}
watch_hd
get_cpu_info() 
{ 
  cat /proc/stat|grep '^cpu[0-12]'|awk '{used+=$2+$3+$4;unused+=$5+$6+$7+$8} END{print used,unused}' 
} 

watch_cpu() 
{ 
  time_point_1=`get_cpu_info` 
  sleep 5 
  time_point_2=`get_cpu_info` 
  cpu_usage=`echo $time_point_1 $time_point_2|awk '{used=$3-$1;total=$3+$4-$1-$2;print used*100/total}'` 
  # echo "---------------------------------"
  # echo -e "\tCPU Utilization"
  # echo "---------------------------------"
   echo -e "\033[0;31mCPU_used $cpu_usage%\033[0m" 
  # echo "---------------------------------"
} 
watch_cpu
path=/usr/local/script/log
mkdir -p $path
report=$path/$(date +%F)_report.log 
#date >> $report
watch_mem >> $report
watch_hd >> $report
watch_cpu >> $report


