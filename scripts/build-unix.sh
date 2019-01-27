#!/bin/bash
NB_CORES=`nproc`

for var in "$@"
do
    if [ $var = "--install-dependencies" ]; then
        ./install-dependencies.sh
    fi
done

if [ ! -e checkswap.sh ] ; then
    wget https://raw.githubusercontent.com/ignitioncoin/ignitioncoin/master/scripts/checkswap.sh
fi
chmod +x checkswap.sh
./checkswap.sh

cd ../src
make -j$NB_CORES -f makefile.unix &>/dev/null

for var in "$@"
do
    if [ $var = "--with-gui" ]; then
        cd ..
        qmake CONFIG+=debug
        make -j$NB_CORES
    fi
done