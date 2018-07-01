#!/bin/bash

# Useful variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

# Backup data dir
echo -e "${GREEN}Wiping cache in ~/Ignition${NC}"
if [ -d "$HOME/.Ignition/" ]; then
	cd $HOME/.Ignition/  
	rm -rf smsgStore
	rm -rf smsgDB
	rm -f *.log
	rm -f smsg.ini
	rm -f blk*
	rm -rf database
	rm -rf txleveldb
	rm -f peers.dat
	rm -f mncache.dat
	echo -e "${BLUE}Done!${NC}"
else
	echo -e "\n${RED}~/Ignition does not exist!${NC}"
fi

