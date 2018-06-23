#!/bin/bash
if [ ! -d "./test1" ]; then
  for i in {1..7}
    do
      portoffset=$((33154+$i))
      connectOffset=$((33133+$i))
      mkdir "test$i"
      printf "rpcuser=ICrpc\nrpcpassword=123\nrpcallowip=127.0.0.1\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\nconnect=127.0.0.1:$connectOffset\n" >> "test$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$portoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$portoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-neoscrypt.sh
      sudo chmod +x "test$i"/*.sh
    done
else
  rm -r test1 && rm -r test2 && rm -r test3 && rm -r test4 && rm -r test5 && rm -r test6 && rm -r test7
  for i in {1..7}
    do
      portoffset=$((33154+$i))
      connectOffset=$((33133+$i))
      mkdir "test$i"
      printf "rpcuser=ICrpc\nrpcpassword=123\nrpcallowip=127.0.0.1\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\nconnect=127.0.0.1:$connectOffset\n" >> "test$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$portoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$portoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-neoscrypt.sh
      sudo chmod +x "test$i"/*.sh
    done
fi

./ignitiond --datadir=./test1 -port=33133 -rpcport=33155 &
./ignitiond --datadir=./test2 -port=33134 -rpcport=33156 &
./ignitiond --datadir=./test3 -port=33135 -rpcport=33157 &
./ignitiond --datadir=./test4 -port=33136 -rpcport=33158 &
./ignitiond --datadir=./test5 -port=33137 -rpcport=33159 &
./ignitiond --datadir=./test6 -port=33138 -rpcport=33160 &
./ignitiond --datadir=./test7 -port=33139 -rpcport=33161 &

wget https://github.com/pooler/cpuminer/releases/download/v2.5.0/pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && tar -xvf pooler-cpuminer-2.5.0-linux-x86_64.tar.gz
wget https://github.com/ghostlander/cpuminer-neoscrypt/releases/download/v2.4.3/cpuminer-neoscrypt-lin-2.4.3.tar.gz && tar -xvf cpuminer-neoscrypt-lin-2.4.3.tar.gz
cp cpuminer-neoscrypt-lin-2.4.3/64bit/minerd ./minerdn && rm pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && rm cpuminer-neoscrypt-lin-2.4.3.tar.gz && rm -r cpuminer-neoscrypt-lin-2.4.3/
