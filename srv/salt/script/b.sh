for i in `lsscsi | awk -F / '$0~ "SSD" {print $NF}'`;do df -TH | awk '$NF~ /'$i'/ {print $0}'|grep -v sdd;done
