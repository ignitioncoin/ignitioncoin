#!/bin/bash
if [ ! -d "./test1" ]; then
  mkdir test1 && mkdir test2 && mkdir test3 && mkdir test4 && mkdir test5 && mkdir test6 && mkdir test7
else
  rm -r test1 && rm -r test2 && rm -r test3 && rm -r test4 && rm -r test5 && rm -r test6 && rm -r test7
  mkdir test1 && mkdir test2 && mkdir test3 && mkdir test4 && mkdir test5 && mkdir test6 && mkdir test7
fi
./ignitiond --datadir=./test1 --daemon=1 -port=33133 -rpcport=33165 -testnet=1 -connect=127.0.0.1:33138 &
./ignitiond --datadir=./test2 --daemon=1 -port=33134 -rpcport=33166 -testnet=1 -connect=127.0.0.1:33133 &
./ignitiond --datadir=./test3 --daemon=1 -port=33135 -rpcport=33167 -testnet=1 -connect=127.0.0.1:33134 &
./ignitiond --datadir=./test4 --daemon=1 -port=33136 -rpcport=33168 -testnet=1 -connect=127.0.0.1:33135 &
./ignitiond --datadir=./test5 --daemon=1 -port=33137 -rpcport=33169 -testnet=1 -connect=127.0.0.1:33136 &
./ignitiond --datadir=./test6 --daemon=1 -port=33138 -rpcport=33170 -testnet=1 -connect=127.0.0.1:33137 &
./ignitiond --datadir=./test7 --daemon=1 -port=33139 -rpcport=33171 -testnet=1 -connect=127.0.0.1:33138 &