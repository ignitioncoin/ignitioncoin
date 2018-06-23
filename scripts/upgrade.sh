#!/bin/bash
sudo apt-get install -y p7zip-full autoconf automake autopoint bash bison bzip2 cmake flex gettext git g++ gperf intltool libffi-dev libtool libltdl-dev libssl-dev libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386 qt5-default qt5-qmake qtbase5-dev-tools qttools5-dev-tools build-essential libboost-dev libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev libdb++-dev libminiupnpc-dev

NB_CORES=`nproc`
sudo killall -9 ignitiond
mkdir ~/ignitionbackup
rm /usr/local/bin/ignitiond
if [ -f "/usr/local/bin/ignitiond" ]; then
  rm /usr/local/bin/ignitiond
fi
if [ -f "../bin/ignitiond" ]; then
  rm /usr/local/bin/ignitiond
fi

if [ ! -d "../../ignitioncoin" ]; then
  mkdir ~/ignitioncoin-autoinstaller
  cd ~/ignitioncoin-autoinstaller
  git clone https://github.com/ignitioncoin/ignitioncoin
  cd ignitioncoin/src/
fi

make -j$NB_CORES -f ../src/makefile.unix
cd ..
qmake CONFIG+=debug
make -j$NB_CORES
cp bin/ignitiond /usr/local/bin/

if [ -d "~/.Ignition/" ]; then
  cd ~/.Ignition/ && rm -r smsgStore && rm -r smsgDB && rm *.log && rm smsg.ini && rm blk* && rm -r database && rm -r txleveldb
  cp -r * ~/ignitionbackup
fi