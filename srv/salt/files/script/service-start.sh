#!/bin/sh

projectlist=(
kids-new-ios
lekan-api
lekan-huashu
kids-ebook
kids-mac
kids-new-upgrade
kids-pc
kids-win8
lekan-book
lekan-diy
lekan-ebook-api
lekan-film
lekan-game
lekan-mv
pay-site
web
)
num=$(ps aux|grep java|grep -v grep |awk '{print $(NF-1)}' |sort |uniq |wc -l)
for i in ${projectlist[@]}
do
	service $i restart &
done
wait
sleep 10
[ $num == 16 ] && echo "all is started" || echo "project start have some wrong"
echo "`ps aux|grep java|grep -v grep |awk '{print $(NF-1)}' |sort |uniq -c|awk '$1 != 2 {print $2}'`"
