#!/usr/bin/env bash

TMP_FOLDER=$(mktemp -d)
CONFIG_FILE='Ignition.conf'
CONFIG_FOLDER='/root/.Ignition'
BACKUP_FOLDER="$HOME/IgnitionBackups"
COIN_DAEMON='ignitiond'
COIN_PATH='/usr/bin/'
COIN_REPO='https://github.com/ignitioncoin/ignitioncoin.git'
#COIN_TGZ='http://github.com/ignitioncoin/ignitioncoin/releases/XXX.zip'
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
    echo "Placing Backup Files into $BACKUP_FOLDER/$foldername"
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
    echo -e "${GREEN}* Done Backing Up and Uninstalling...${NONE}";
    #TODO? Remove systemd configuration
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
#PIDFile=$CONFIG_FOLDER/$COIN_NAME.pid
ExecStart=$COIN_PATH$COIN_DAEMON -daemon -conf=$CONFIG_FOLDER/$CONFIG_FILE -datadir=$CONFIG_FOLDER
ExecStop=-$COIN_PATH$COIN_DAEMON -conf=$CONFIG_FOLDER/$CONFIG_FILE -datadir=$CONFIG_FOLDER stop
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
  mkdir $CONFIG_FOLDER >/dev/null 2>&1
  RPCUSER=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w10 | head -n1)
  RPCPASSWORD=$(tr -cd '[:alnum:]' < /dev/urandom | fold -w22 | head -n1)
  cat << EOF > $CONFIG_FOLDER/$CONFIG_FILE
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
  COINKEY=$($COIN_DAEMON masternode genkey)
  systemctl stop ignition
  sed -i 's/daemon=1/daemon=0/' $CONFIG_FOLDER/$CONFIG_FILE
  grep -Fxq "masternode=1" $CONFIG_FOLDER/$CONFIG_FILE
  if [ $? -eq 0 ]; then
    echo "Found previous masternode configuration. Will backup file then create configuration changes"
    backup_node_data
    rm $CONFIG_FOLDER/$CONFIG_FILE
    create_config
  fi
  cat << EOF >> $CONFIG_FOLDER/$CONFIG_FILE
logintimestamps=1
maxconnections=75
#bind=$NODEIP
masternode=1
externalip=$NODEIP:$COIN_PORT
masternodeprivkey=$COINKEY
#Addnodes
EOF
systemctl start ignition
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
      echo -e "${RED}You are not running Ubuntu 16.04. Please ensure you are running Ubuntu 16.04.${NC}"
      exit 1
    fi

    if [[ $EUID -ne 0 ]]; then
       echo -e "${RED}$0 must be run as root.${NC}"
       exit 1
    fi

}

function prepare_system() {
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
}

function important_information() {
    echo
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${GREEN}Configuration file is:${NC}${RED}$CONFIG_FOLDER/$CONFIG_FILE${NC}"
    echo -e "${GREEN}Start:${NC}${RED}systemctl start $COIN_NAME.service${NC}"
    echo -e "${GREEN}Stop:${NC}${RED}systemctl stop $COIN_NAME.service${NC}"
    echo -e "${GREEN}VPS_IP:${NC}${GREEN}$NODEIP:$COIN_PORT${NC}"
    echo -e "${BLUE}================================================================================================================================"
    echo -e "${CYAN}Follow twitter to stay updated.  https://twitter.com/IgnitionCoin${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${CYAN}Ensure Node is fully SYNCED with BLOCKCHAIN before starting your Node :).${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
    echo -e "${GREEN}Usage Commands.${NC}"
    echo -e "${GREEN}ignitiond masternode status${NC}"
    echo -e "${GREEN}ignitiond getinfo${NC}"
    echo -e "${BLUE}================================================================================================================================${NC}"
}

function setup_node() {
  get_ip
  update_config
  systemctl restart ignition
}

function install_ignition() {
    echo "You chose to install the Ignition Node"
    echo "Checking for Ignition installation"
    if [ -e /usr/bin/ignitiond ] || [ -e /usr/local/bin/ignitiond ]; then
        purgeOldInstallation
    else
        echo "No installation found. Proceeding with install."
    fi
    checks
    prepare_system
    echo "Would you like to download and compile from source? y/n: "
    read compilefromsource
    if [ "$compilefromsource" = "y" ] || [ "$compilefromsource" = "Y" ] ; then
        if [ -e ../Ignition.pro ] ; then
            echo "Compiling Source Code"
            ./build-unix.sh
            mv ../bin/ignitiond /usr/bin
        else
            echo "Cloning github repository.."
            git clone https://github.com/ignitioncoin/ignitioncoin
            ./ignitioncoin/scripts/build-unix.sh
            mv ./ignitioncoin/bin/ignitiond /usr/bin
        fi
    else
        echo "Download Executable Binary For Install"
        #wget github.com/ignitioncoin/ignitioncoin/releases/EXECUTABLE
        mv ./ignitiond /usr/bin
    fi
    create_config
    enable_firewall
    configure_systemd
    important_information
}

function compile_linux_daemon() {
    echo "You chose to compile the Ignition CLI Daemon/Wallet"
    checks
    prepare_system
    if [ ! -e ../Ignition.pro ] ; then
        echo "Cloning Ignition Coin Github Repository"
        git clone https://github.com/ignitioncoin/ignitioncoin
        ./ignitioncoin/scripts/build-unix.sh
        clear
        echo "Compile is complete, you can find the binary file in ./ignitioncoin/bin/"
    else
        echo "Compiling Source Code"
        ./build-unix.sh
        clear
        echo "Compile is complete, you can find the binary file in ../bin/"
    fi
}

function compile_linux_gui() {
    echo "You chose to compile the linux GUI wallet"
    checks
    prepare_system
    if [ ! -e ../Ignition.pro ] ; then
        echo "Cloning Ignition Coin Github Repository"
        git clone https://github.com/ignitioncoin/ignitioncoin
        ./ignitioncoin/scripts/build-unix.sh --with-gui
        clear
        echo "Compile is complete, you can find the binary file in ./ignitioncoin/bin/"
    else
        echo "Compiling Source Code"
        ./build-unix.sh --with-gui
        clear
        echo "Compile is complete, you can find the binary file in ../bin/"
    fi
}

function compile_windows_exe() {
    echo "You chose to compile windows executables"
    checks
    prepare_system
    if [ ! -e ../Ignition.pro ] ; then
        echo "Cloning Ignition Coin Github Repository"
        git clone https://github.com/ignitioncoin/ignitioncoin
        ./ignitioncoin/scripts/clean.sh
        ./ignitioncoin/scripts/configure-mxe.sh
        ./ignitioncoin/scripts/build-win-mxe.sh
    else
        echo "Compiling Source Code"
        ./clean.sh
        ./configure-mxe.sh
        ./build-win-mxe.sh
    fi
}

function setup_masternode() {
    echo "You chose to setup a masternode"
    if [ -e /usr/bin/ignitiond ] || [ -e /usr/local/bin/ignitiond ]; then
        read -p "There is already an installation of Ignition Coin. Did you want to use the currently installed software, or install the latest software? Y/n:" yn
        case $yn in
            [Yy]* ) install_ignition; setup_node; echo -e "${GREEN}MASTERNODE GENKEY is:${NC}${PURPLE}$COINKEY${NC}"; echo -e "${BLUE}================================================================================================================================"; echo -e "${GREEN}Ignition Masternode is up and running listening on port ${NC}${PURPLE}$COIN_PORT${NC}."; echo -e "${BLUE}================================================================================================================================${NC}"; echo -e "${PURPLE}Windows Wallet Guide. https://github.com/ignitioncoin/ignitioncoin/tree/master/doc${NC}"; echo -e "${BLUE}================================================================================================================================${NC}";;
            [Nn]* ) setup_node;;
            * ) echo "Sorry, did not understand your command, please enter Y/n";;
        esac
    fi
}

function install_dependencies_only() {
    echo "You chose to install Ignition dependencies only"
    prepare_system
}

function backup_node_data() {
    echo "You chose to backup your wallet and settings files"
    today="$( date +"%Y%m%d" )"
    #Create a backups folder inside users home directory
    test -d ~/IgnitionBackups && echo "Backups folder exists" || mkdir ~/IgnitionBackups
    iteration=0
    while test -d "$BACKUP_FOLDER/$today$suffix"; do
        (( ++iteration ))
        suffix="$( printf -- '-%02d' "$iteration" )"
    done
    foldername="$today$suffix"
    echo "Placing Backup Files into $BACKUP_FOLDER/$foldername"
    mkdir $BACKUP_FOLDER/$foldername
    cp $CONFIG_FOLDER/masternode.conf $BACKUP_FOLDER/$foldername
    cp $CONFIG_FOLDER/Ignition.conf $BACKUP_FOLDER/$foldername
    cp $CONFIG_FOLDER/wallet.dat $BACKUP_FOLDER/$foldername
}

function uninstall() {
    read -p "You chose to uninstall Ignition, would you like to continue? y/n:" yn
    case $yn in
        [Yy]* ) purgeOldInstallation;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y/n";;
    esac
}

##### Main #####
clear

if [ $# > 0 ] ; then
    if [ $1 = "--backup" ] ; then
        backup_node_data
        exit 1
    fi
fi

echo "Welcome to the interactive setup manager. Please select an option:"
echo "Install Ignition node (will uninstall/upgrade existing installation) - [1]"
echo "Compile GUI wallet - [2]"
echo "Compile windows executables - [3]"
echo "Prepare masternode (will install Ignition Node if needed) - [4]"
echo "Install dependencies only - [5]"
echo "Backup Ignition wallet and settings - [6]"
echo "Compile linux CLI binary (will not install) - [7]"
echo "Uninstall Ignition - [8]"

read choice1

case $choice1 in
    "1") install_ignition;;
    "2") compile_linux_gui;;
    "3") compile_windows_exe;;
    "4") setup_masternode;;
    "5") install_dependencies_only;;
    "6") backup_node_data;;
    "7") compile_linux_daemon;;
    "8") uninstall;;
esac