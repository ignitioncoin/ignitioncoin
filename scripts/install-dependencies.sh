#!/usr/bin/env bash
echo -e "Installing required dependencies..."
sudo apt-get -y update && apt-get -y install git build-essential libssl-dev libdb++-dev libboost-all-dev libcrypto++-dev \
    libqrencode-dev libminiupnpc-dev libgmp-dev libgmp3-dev autoconf autogen  qt5-default qt5-qmake qtbase5-dev-tools \
    qttools5-dev-tools build-essential libboost-dev libboost-system-dev libboost-filesystem-dev libgtk2.0-dev libtool \
    libboost-program-options-dev libboost-thread-dev autopoint bison flex gperf libtool ruby scons unzip libtool-bin \
    automake git p7zip-full intltool