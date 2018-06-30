#!/bin/bash

# Functions
readYesNo()
{
	PROMPT=$1
	DEFAULT=$2
	while true; do
		read -p "${BLUE_READ}$PROMPT [$DEFAULT]: ${NC_READ}" ANSWER
		ANSWER="${ANSWER:-$DEFAULT}"
		case $ANSWER in
			[Yy]* ) return 1;;
			[Nn]* ) return 0;;
			* ) echo -e "${BLUE}Please answer Y or N.${NC}";;
		esac
	done
}

# Options
SOURCES_PATH_DEFAULT=$HOME
SOURCES_PATH="$SOURCES_PATH_DEFAULT/ignitioncoin"
REPO="https://github.com/TechniumUnlimited/ignitioncoin"
BRANCH="v1.1"
#REPO="https://github.com/ignitioncoin/ignitioncoin"
#BRANCH="master"
SWAP_FILE="$HOME/ignitioncoin-swap"

# Useful variables
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BLUE_READ=$'\e[34m'
NC='\033[0m'
NC_READ=$'\e[0m'

# System specs
NB_CORES=`nproc`
MEMORY_SIZE=`grep MemTotal /proc/meminfo | awk '{print $2}'`

# Install Git
echo -e "\n${GREEN}Installing git${NC}"
if [ -n "$(command -v yum)" ]; then
    sudo yum install git
elif [ -n "$(command -v apt-get)" ]; then
    sudo apt-get install git
fi

# Clone / update repo if executing the script as a standalone script
if [ -d "../.git" ]; then
	# Script is executed from repo
	echo -e "\n${GREEN}Script executed from the repository${NC}"
	SOURCES_PATH="$(dirname "$(pwd)")"
	# Delete previous binary
	if [ -f "$SOURCES_PATH/bin/ignitiond" ]; then
		rm -f $SOURCES_PATH/bin/ignitiond
		echo -e "${BLUE}Removed old binary in $SOURCES_PATH/bin/${NC}"
	fi
	if [ -f "../bin/ignitiond" ]; then
      rm ../bin/ignitiond
      echo "Removed old binary in ../bin/"
    fi
else
	# Standalone mode
	echo -e "\n${GREEN}Standalone mode${NC}"

	# Ask for the install path
	read -e -p "${BLUE_READ}Install to directory [$SOURCES_PATH_DEFAULT]: ${NC_READ}" SOURCES_PATH
	SOURCES_PATH="${SOURCES_PATH:-$SOURCES_PATH_DEFAULT}/ignitioncoin"
	# Replace ~ with $HOME if needed
	SOURCES_PATH="${SOURCES_PATH/[~]/$HOME}"

	# Clone / update the repo
	if [ -d $SOURCES_PATH ]; then
		cd $SOURCES_PATH
		git checkout $BRANCH
		git pull
	else
		mkdir -p $SOURCES_PATH
		git clone -b $BRANCH $REPO $SOURCES_PATH
	fi
fi

# Kill and remove existing daemons
echo -e "\n${GREEN}Removing existing daemons${NC}"
sudo killall -9 ignitiond
if [ -f "/usr/local/bin/ignitiond" ]; then
  sudo rm -f /usr/local/bin/ignitiond
  echo -e "${BLUE}Removed ignitiond in /usr/local/bin/ - To be replaced with new version${NC}"
fi

# Go to the scripts directory
cd $SOURCES_PATH/scripts

# Install dependencies
read -p "Install Dependencies for Ubuntu? This will NOT install any dependencies if you say no! - Y/n: " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${GREEN}Installing dependencies${NC}"
    ./install-dependencies.sh
fi

# Cleaning repo
echo -e "\n${GREEN}Cleaning repo${NC}"
./clean.sh

# Add swap if needed
if [ "$MEMORY_SIZE" -lt "2000000" ]; then
	echo -e "\n${GREEN}Adding 1G swap to compile${NC}"
	sudo fallocate -l 1G $SWAP_FILE
	sudo mkswap $SWAP_FILE
	sudo swapon $SWAP_FILE
fi

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

# Remove swap
if [ -f "$SWAP_FILE" ]; then
	sudo swapoff $SWAP_FILE
	sudo rm -f $SWAP_FILE
fi

# Install
echo -e "\n${GREEN}Installing daemon in /usr/local/bin/${NC}"
sudo cp $SOURCES_PATH/bin/ignitiond /usr/local/bin/
sudo strip /usr/local/bin/ignitiond

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
	rm -f peers.dat
	rm -f mncache.dat
	cp -r * $HOME/ignitionbackup
fi

# Done
echo -e "\n${GREEN}Upgrade Complete - You can now run ignitiond or fill out the config file in ~/Ignition${NC}"

