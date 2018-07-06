Copyright (c) 2009-2012 Bitcoin Developers
Copyright (c) 2017-2018 Ignition Developers
Distributed under the MIT/X11 software license, see the accompanying
file license.txt or http://www.opensource.org/licenses/mit-license.php.
This product includes software developed by the OpenSSL Project for use in
the OpenSSL Toolkit (http://www.openssl.org/).  This product includes
cryptographic software written by Eric Young (eay@cryptsoft.com) and UPnP
software written by Thomas Bernard.


RASPBERRY PI BUILD NOTES
================
The following steps have been tested on Raspbian stretch, they should work on jessie as well.
You can check the release codename with `lsb_release -a`

## Set up swap
Check if you have enough swap (should be around 1024 mb): `free -m`
If not, change it: `sudo nano /etc/dphys-swapfile`
CONF_SWAPSIZE=1024

Turn on swap:
`sudo dphys-swapfile swapon`
if you get the error swapon: /var/swap: swapon failed: Device or resource busy
then run `sudo dphys-swapfile swapoff && sudo dphys-swapfile swapon`

Reboot, check `free -m`
You should see 1024 mb

## Install dependencies
```
sudo apt-get update
sudo apt-get install git automake build-essential libtool autotools-dev autoconf pkg-config libboost-all-dev libminiupnpc-dev libgmp-dev libgmp3-dev libcrypto++-dev
```
If you run Raspbian stretch you must do the following steps, if running Raspbian jessie just run sudo apt-get install libssl-dev
______
Remove current libssl-dev if you have it installed
`sudo apt-get remove libssl-dev`
Replace stretch with jessie in the config
`sudo nano /etc/apt/sources.list`
Run update to receive jessie package list
`sudo apt update`
Check if you have the correct library version available, it should display something like this:
`sudo apt-cache policy libssl-dev`
```
libssl-dev:
  Installed: (none)
  Candidate: 1.0.1t-1+deb8u6
  Version table:
  1.0.1t-1+deb8u6 500
        500 http://mirrordirector.raspbian.org/raspbian jessie/main armhf Packages
```
Install package, lock it and replace jessie with stretch in sources.list:
```
sudo apt install libssl-dev
sudo apt-mark hold libssl-dev
sudo nano /etc/apt/sources.list
sudo apt update
```
______

**Install BerkeleyDB-4.8**
Download and compile BDB 4.8 from Oracle
wget http://download.oracle.com/berkeley-db/db-4.8.30.NC.tar.gz
tar xzvf db-4.8.30.NC.tar.gz
cd db-4.8.30.NC/build_unix/
../dist/configure --enable-cxx
make
sudo make install

Export paths
export BDB_INCLUDE_PATH="/usr/local/BerkeleyDB.4.8/include"
export BDB_LIB_PATH="/usr/local/BerkeleyDB.4.8/lib"

Create symlinks
sudo ln -s /usr/local/BerkeleyDB.4.8/lib/libdb-4.8.so /usr/lib/libdb-4.8.so
sudo ln -s /usr/local/BerkeleyDB.4.8/lib/libdb_cxx-4.8.so /usr/lib/libdb_cxx-4.8.so

## Build daemon
git clone https://github.com/ignitioncoin/ignitioncoin
cd src
make -j2 -f makefile.unix CPPFLAGS="-I/usr/local/BerkeleyDB.4.8/include -O2" LDFLAGS="-L/usr/local/BerkeleyDB.4.8/lib" xCPUARCH=arm

After compilation, the swapfile will not be needed anymore, so you can disable it. Leaving it on is not recommended, since successive read/writes can eventually corrupt your SD card.
`sudo swapoff -a`
`sudo reboot`