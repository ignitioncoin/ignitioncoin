#!/bin/bash
NB_CORES=`nproc`

for var in "$@"
do
    if [ $var = "--install-dependencies" ]; then
        ./install-dependencies.sh
    fi
done

cd ../src
make -j$NB_CORES -f makefile.unix

for var in "$@"
do
    if [ $var = "--with-gui" ]; then
        cd ..
        qmake CONFIG+=debug
        make -j$NB_CORES
    fi
done