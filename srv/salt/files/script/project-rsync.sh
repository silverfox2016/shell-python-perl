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

	rsync -arzP --delete-after 192.168.253.137::project /lekan/project/ > /dev/null 2>&1  && [ $? == 0 ] && echo "init is ok"
	rsync -arzP --delete-after 192.168.253.137::conf /usr/local/resin/conf/ > /dev/null 2>&1 && [ $? == 0 ] && echo "conf is ok"
#	rsync -arzP --delete-after 192.168.253.137::auto /lekan/auto_develop/ > /dev/null 2>&1 && [ $? == 0 ] && echo "auto is ok"
#	rsync -arzP --delete-after 192.168.253.137::server /lekan/server_develop_pl/ > /dev/null 2>&1 && [ $? == 0 ] && echo "server is ok"
	rsync -arzP 192.168.253.137::init /etc/init.d/  && [ $? == 0 ] && echo "init is ok"


