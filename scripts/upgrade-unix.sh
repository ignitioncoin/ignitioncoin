#!/bin/bash

# Functions
readYesNo()
{
	PROMPT=$1
	DEFAULT=$2
	while true; do
		read -p "$PROMPT [$DEFAULT]: " ANSWER
		ANSWER="${ANSWER:-$DEFAULT}"
		case $ANSWER in
			[Yy]* ) return 1;;
			[Nn]* ) return 0;;
			* ) echo "Please answer yes or no.";;
		esac
	done
}

# Options
SOURCES_PATH_DEFAULT=$HOME/ignitioncoin
SOURCES_PATH=$SOURCES_PATH_DEFAULT

# Useful variables
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
NB_CORES=`nproc`

# Install Git
sudo apt-get install git

# Clone / update repo if executing the script as a standalone script
if [ -d .git ]; then
	# Script is executed from repo
	echo -e "\n${GREEN}Script executed from the repository${NC}"
	SOURCES_PATH="$(dirname "$(pwd)")"
else
	# Standalone mode
	echo -e "\n${GREEN}Standalone mode${NC}"

	# Ask for the install path
	read -p "Sources destination [$SOURCES_PATH_DEFAULT]: " SOURCES_PATH
	SOURCES_PATH="${SOURCES_PATH:-$SOURCES_PATH_DEFAULT}"

	# Clone / update the repo
	if [ -d $SOURCES_PATH ]; then
		cd $SOURCES_PATH
		git checkout master
		git pull
	else
		mkdir -p $SOURCES_PATH
		git clone https://github.com/ignitioncoin/ignitioncoin $SOURCES_PATH
	fi
fi

# Kill and remove existing daemons
echo -e "\n${GREEN}Removing existing daemons${NC}"
sudo killall -9 ignitiond
if [ -f "/usr/local/bin/ignitiond" ]; then
  rm /usr/local/bin/ignitiond
  echo "Removed ignitiond in /usr/local/bin/ - To be replaced with new version"
fi
if [ -f "$SOURCES_PATH/bin/ignitiond" ]; then
  rm $SOURCES_PATH/bin/ignitiond
  echo "Removed old binary in $SOURCES_PATH/bin/"
fi

# Go to the scripts directory
cd $SOURCES_PATH/scripts

# Install dependencies
echo -e "\n${GREEN}Installing dependencies${NC}"
./install-dependencies.sh

# Cleaning repo
echo -e "\n${GREEN}Cleaning repo${NC}"
./clean.sh

# Build daemon
echo -e "\n${GREEN}Building daemon${NC}"
cd $SOURCES_PATH/src
make -j$NB_CORES -f makefile.unix

# Build QT GUI
readYesNo "Build GUI" "N"
BUILD_GUI=$?
if [ "$BUILD_GUI" = 1 ]; then
	echo -e "\n${GREEN}Building GUI${NC}"
	cd $SOURCES_PATH
	qmake CONFIG+=debug
	make -j$NB_CORES
fi

# Install
echo -e "\n${GREEN}Installing daemon in /usr/local/bin/${NC}"
sudo cp $SOURCES_PATH/bin/ignitiond /usr/local/bin/

# Backup data dir
if [ -d "$HOME/.Ignition/" ]; then
	echo -e "\n${GREEN}Backing up ~/Ignition (including wallet.dat) in ~/ignitionbackup${NC}"
	mkdir $HOME/ignitionbackup
	cd $HOME/.Ignition/
	rm -rf smsgStore
	rm -rf smsgDB
	rm -f *.log
	rm -f smsg.ini
	rm -f blk*
	rm -rf database
	rm -rf txleveldb
	cp -r * $HOME/ignitionbackup
fi

# Done
echo -e "\n${GREEN}Upgrade Complete - You can now run ignitiond or fill out the config file in ~/Ignition${NC}"

