#!/bin/bash
if [ ! -d "./test1" ]; then
  for i in {1..7}
    do
      rpcportoffset=$((33154+$i))
      portoffset=$((33132+$i))
      connectOffset=$((33133+$i))
      mkdir "test$i"
      printf "rpcuser=rpc\nrpcpassword=123\nrpcallowip=127.0.0.1\nport=$portoffset\nrpcport=$rpcportoffset\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\nconnect=127.0.0.1:$connectOffset\n" >> "test$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$rpcportoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$rpcportoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-neoscrypt.sh
      sudo chmod +x "test$i"/*.sh
    done
else
  sudo killall -9 ignitiond
  rm -r test1 && rm -r test2 && rm -r test3 && rm -r test4 && rm -r test5 && rm -r test6 && rm -r test7
  for i in {1..7}
    do
      rpcportoffset=$((33154+$i))
      portoffset=$((33132+$i))
      connectOffset=$((33133+$i))
      mkdir "test$i"
      printf "rpcuser=ICrpc\nrpcpassword=123\nrpcallowip=127.0.0.1\ntestnet=1\ndaemon=1\nserver=1\nlisten=1\nconnect=127.0.0.1:$connectOffset\n" >> "test$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$rpcportoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$rpcportoffset --userpass=rpc:123 --threads=1" >> "test$i"/mine-neoscrypt.sh
      sudo chmod +x "test$i"/*.sh
    done
fi

./ignitiond --datadir=./test1 &
./ignitiond --datadir=./test2 &
./ignitiond --datadir=./test3 &
./ignitiond --datadir=./test4 &
./ignitiond --datadir=./test5 &
./ignitiond --datadir=./test6 &
./ignitiond --datadir=./test7 &

wget https://github.com/pooler/cpuminer/releases/download/v2.5.0/pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && tar -xvf pooler-cpuminer-2.5.0-linux-x86_64.tar.gz
wget https://github.com/ghostlander/cpuminer-neoscrypt/releases/download/v2.4.3/cpuminer-neoscrypt-lin-2.4.3.tar.gz && tar -xvf cpuminer-neoscrypt-lin-2.4.3.tar.gz
cp cpuminer-neoscrypt-lin-2.4.3/64bit/minerd ./minerdn && rm pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && rm cpuminer-neoscrypt-lin-2.4.3.tar.gz && rm -r cpuminer-neoscrypt-lin-2.4.3/
