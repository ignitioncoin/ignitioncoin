#!/bin/bash
NB_CORES=`nproc`

cd ../src
make -j$NB_CORES -f makefile.unix
cd ..
qmake CONFIG+=debug
make -j$NB_CORES
