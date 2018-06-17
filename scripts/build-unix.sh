#!/bin/bash
cd ../src
make -j5 -f makefile.unix
cd ..
qmake CONFIG+=debug
make -j5
