#!/bin/bash
./install-dependencies.sh
NB_CORES=`nproc`
sudo killall -9 ignitiond
mkdir ~/ignitionbackup
rm /usr/local/bin/ignitiond
if [ -f "/usr/local/bin/ignitiond" ]; then
  rm /usr/local/bin/ignitiond
  echo "Removed ignitiond in /usr/local/bin/ - To be replaced with new version"
fi
if [ -f "../bin/ignitiond" ]; then
  rm ../bin/ignitiond
  echo "Removed Old Binary in ../bin/"
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
  cd ~/.Ignition/
  rm -r smsgStore
  rm -r smsgDB
  rm *.log
  rm smsg.ini
  rm blk*
  rm -r database
  rm -r txleveldb
  cp -r * ~/ignitionbackup
fi
echo "Upgrade Complete - You can now run ignitiond or fill out the config file in ~/Ignition - Backed up files (including wallet.dat) are in ~/ignitionbackup"
