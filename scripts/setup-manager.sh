#!/usr/bin/env bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='Ignition.conf'
CONFIG_FOLDER='/root/.Ignition'
BACKUP_FOLDER="$HOME/IgnitionBackups"
COIN_DAEMON='ignitiond'
COIN_PATH='/usr/local/bin/'
COIN_REPO='https://github.com/ignitioncoin/ignitioncoin.git'
#COIN_TGZ='http://www.mastermasternode.com/ignitioncoin/XXX.zip'
#COIN_ZIP=$(echo $COIN_TGZ | awk -F'/' '{print $NF}')
COIN_NAME='Ignition'
COIN_PORT=44144
RPC_PORT=44155
NODEIP=$(curl -s4 icanhazip.com)

BLUE="\033[0;34m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
PURPLE="\033[0;35m"
RED='\033[0;31m'
GREEN="\033[0;32m"
NC='\033[0m'
MAG='\e[1;35m'

purgeOldInstallation() {
    echo -e "${GREEN}Searching for and backing up any wallet and config files, and removing old $COIN_NAME files${NC}"
    #kill wallet daemon
    systemctl stop $COIN_NAME.service > /dev/null 2>&1
    sudo killall $COIN_DAEMON > /dev/null 2>&1
    today="$( date +"%Y%m%d" )"
    #Create a backups folder inside users home directory
    test -d ~/IgnitionBackups && echo "Backups folder exists" || mkdir ~/IgnitionBackups
    iteration=0
    while test -d "$BACKUP_FOLDER/$today$suffix"; do
        (( ++iteration ))
        suffix="$( printf -- '-%02d' "$iteration" )"
    done
    foldername="$today$suffix"
    mkdir $BACKUP_FOLDER/$foldername
    mv $CONFIG_FOLDER/masternode.conf $BACKUP_FOLDER/$foldername
    mv $CONFIG_FOLDER/Ignition.conf $BACKUP_FOLDER/$foldername
    mv $CONFIG_FOLDER/wallet.dat $BACKUP_FOLDER/$foldername
    #remove old ufw port allow
    sudo ufw delete allow $COIN_PORT/tcp > /dev/null 2>&1
    #remove old files
    sudo rm -rf $CONFIG_FOLDER > /dev/null 2>&1
    sudo rm -rf /usr/local/bin/$COIN_DAEMON > /dev/null 2>&1
    sudo rm -rf /usr/bin/$COIN_DAEMON > /dev/null 2>&1
    sudo rm -rf /tmp/*
    echo -e "${GREEN}* Done${NONE}";
}

function configure_systemd() {
  cat << EOF > /etc/systemd/system/$COIN_NAME.service
[Unit]
Description=$COIN_NAME service
After=network.target
[Service]
User=root
Group=root
Type=forking
#PIDFile=$CONFIGFOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER
ExecStop=-$COIN_PATH$COIN_CLI -conf=$CONFIGFOLDER/$CONFIG_FILE -datadir=$CONFIGFOLDER stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  sleep 3
  systemctl start $COIN_NAME.service
  systemctl enable $COIN_NAME.service >/dev/null 2>&1

  if [[ -z "$(ps axo cmd:100 | egrep $COIN_DAEMON)" ]]; then
    echo -e "${RED}$COIN_NAME is not running${NC}, please investigate. You should start by running the following commands as root:"
    echo -e "${GREEN}systemctl start $COIN_NAME.service"
    echo -e "systemctl status $COIN_NAME.service"
    echo -e "less /var/log/syslog${NC}"
    exit 1
  fi
}

function create_config() {
  mkdir $CONFIGFOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIGFOLDER/$CONFIG_FILE
rpcuser=$RPCUSER
rpcpassword=$RPCPASSWORD
rpcport=$RPC_PORT
rpcallowip=127.0.0.1
listen=1
server=1
daemon=1
maxconnections=50
port=$COIN_PORT
EOF
}

