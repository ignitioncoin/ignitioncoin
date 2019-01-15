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

function compile_node() {
 #TODO
 echo "Unfinished"
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

function update_config() {
  sed -i 's/daemon=1/daemon=0/' $CONFIGFOLDER/$CONFIG_FILE
  cat << EOF >> $CONFIGFOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=50
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
#Addnodes
EOF
}

function enable_firewall() {
  echo -e "Installing and setting up firewall to allow ingress on port ${GREEN}$COIN_PORT${NC}"
  ufw allow $COIN_PORT/tcp comment "$COIN_NAME MN port" >/dev/null
  ufw allow ssh comment "SSH" >/dev/null 2>&1
  ufw limit ssh/tcp >/dev/null 2>&1
  ufw default allow outgoing >/dev/null 2>&1
  echo "y" | ufw enable >/dev/null 2>&1
}

function get_ip() {
  declare -a NODE_IPS
  for ips in $(netstat -i | awk '!/Kernel|Iface|lo/ {print $1," "}')
  do
    NODE_IPS+=($(curl --interface $ips --connect-timeout 2 -s4 icanhazip.com))
  done

  if [ ${#NODE_IPS[@]} -gt 1 ]
    then
      echo -e "${GREEN}More than one IP. Please type 0 to use the first IP, 1 for the second and so on...${NC}"
      INDEX=0
      for ip in "${NODE_IPS[@]}"
      do
        echo ${INDEX} $ip
        let INDEX=${INDEX}+1
      done
      read -e choose_ip
      NODEIP=${NODE_IPS[$choose_ip]}
  else
    NODEIP=${NODE_IPS[0]}
  fi
}

function compile_error() {
    if [ "$?" -gt "0" ];
     then
      echo -e "${RED}Failed to compile $COIN_NAME. Please investigate.${NC}"
      exit 1
    fi
}

function checks() {
    if [[ $(lsb_release -d) != *16.04* ]]; then
      echo -e "${RED}You are not running Ubuntu 16.04. Installation is cancelled.${NC}"
      exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}$0 must be run as root.${NC}"
       exit 1
    fi

    if [ -n "$(pidof $COIN_DAEMON)" ] || [ -e "$COIN_DAEMOM" ] ; then
      echo -e "${RED}$COIN_NAME is already installed.${NC}"
      exit 1
    fi
}

function prepare_system() {
    echo -e "Preparing the VPS to setup. ${CYAN}$COIN_NAME${NC} ${RED}Masternode${NC}"
    if [ -f ./install-dependencies.sh ]; then
        echo "Install-dependencies script is already available. Will not download."
        ./install-dependencies.sh
    else
        echo "Downloading latest install-dependencies script."
        wget https://raw.githubusercontent.com/ignitioncoin/ignitioncoin/master/scripts/install-dependencies.sh
        ./install-dependencies.sh
    fi
    if [ "$?" -gt "0" ];
      then
        echo -e "${RED}Not all required packages were installed properly. Try to install them manually by running the following commands:${NC}\n"
        echo "apt-get -y update && apt-get -y install build-essential libssl-dev libdb++-dev libboost-all-dev libcrypto++-dev \
    libqrencode-dev libminiupnpc-dev libgmp-dev libgmp3-dev autoconf autogen  qt5-default qt5-qmake qtbase5-dev-tools \
    qttools5-dev-tools build-essential libboost-dev libboost-system-dev libboost-filesystem-dev libgtk2.0-dev libtool \
    libboost-program-options-dev libboost-thread-dev autopoint bison flex gperf libtool ruby scons unzip libtool-bin \
    automake git p7zip-full intltool"
     exit 1
    fi
    clear
}

function important_information() {
    echo
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${PURPLE}Windows Wallet Guide. https://github.com/ignitioncoin/ignitioncoin/tree/master/doc${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${GREEN}$COIN_NAME Masternode is up and running listening on port${NC}${PURPLE}$COIN_PORT${NC}."
    echo -e "${GREEN}Configuration file is:${NC}${RED}$CONFIGFOLDER/$CONFIG_FILE${NC}"
    echo -e "${GREEN}Start:${NC}${RED}systemctl start $COIN_NAME.service${NC}"
    echo -e "${GREEN}Stop:${NC}${RED}systemctl stop $COIN_NAME.service${NC}"
    echo -e "${GREEN}VPS_IP:${NC}${GREEN}$NODEIP:$COIN_PORT${NC}"
    echo -e "${GREEN}MASTERNODE GENKEY is:${NC}${PURPLE}$COINKEY${NC}"
    echo -e "${BLUE}================================================================================================================================"
    echo -e "${CYAN}Follow twitter to stay updated.  https://twitter.com/IgnitionCoin${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${CYAN}Ensure Node is fully SYNCED with BLOCKCHAIN before starting your Node :).${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${GREEN}Usage Commands.${NC}"
    echo -e "${GREEN}ignitiond masternode status${NC}"
    echo -e "${GREEN}ignitiond getinfo.${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
}

function setup_node() {
  get_ip
  create_config
  create_key
  update_config
  enable_firewall
  important_information
  configure_systemd
}

##### Main #####
clear

purgeOldInstallation
checks
prepare_system
compile_node
setup_node