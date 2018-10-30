network(){
   port=(`sudo awk  '{print $1}' /proc/net/dev| grep -Ev 'face|Inter|lo|he-ipv|sit'|awk -F':' '{print $1}'` )
    max_index=$[${#port[@]}-1]
    printf '{\n'
    printf '\t"data":['
    for key in ${!port[@]}
    do
        printf '\n\t\t{'
        printf "\"{#NETWORKTOCAL}\":\"${port[${key}]}\"}"
    if [ $key -ne $max_index ];then
            printf ","
        fi
    done
    printf '\n\t]\n'
    printf '}\n'
}

case "$1" in
    network)
        "$1"
        ;;
    *)
        echo "Bad Parameter."
        echo "Usage: $0 network"
        exit 1
        ;;
esac
