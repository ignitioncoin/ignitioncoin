#!/bin/bash
if [ ! -d "./test1" ]; then
  for i in {1..7}
    do
      mkdir "test$i"
      printf "rpcuser=ICrpc\nrpcpassword=123\nrpcallowip=127.0.0.1\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\n" >> "test$i"/Ignition.conf
    done
else
  rm -r test1 && rm -r test2 && rm -r test3 && rm -r test4 && rm -r test5 && rm -r test6 && rm -r test7
  for i in {1..7}
    do
      mkdir "test$i"
      printf "rpcuser=ICrpc\nrpcpassword=123\nrpcallowip=127.0.0.1\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\n" >> "test$i"/Ignition.conf
    done
fi

./ignitiond --datadir=./test1 -port=33133 -rpcport=33165 -connect=127.0.0.1:33138 &
./ignitiond --datadir=./test2 -port=33134 -rpcport=33166 -connect=127.0.0.1:33133 &
./ignitiond --datadir=./test3 -port=33135 -rpcport=33167 -connect=127.0.0.1:33134 &
./ignitiond --datadir=./test4 -port=33136 -rpcport=33168 -connect=127.0.0.1:33135 &
./ignitiond --datadir=./test5 -port=33137 -rpcport=33169 -connect=127.0.0.1:33136 &
./ignitiond --datadir=./test6 -port=33138 -rpcport=33170 -connect=127.0.0.1:33137 &
./ignitiond --datadir=./test7 -port=33139 -rpcport=33171 -connect=127.0.0.1:33138 &