#!/bin/bash
if [ ! -d "./node1" ]; then
  for i in {1..7}
    do
      rpcportoffset=$((44155+$i))
      portoffset=$((44144+$i))
      #connectOffset=$((33133+$i))
      mkdir "node$i"
      printf "rpcuser=rpc\nrpcpassword=12410516051fd5fsd4rsd3\nrpcallowip=127.0.0.1\nmaxconnections=125\nport=$portoffset\nrpcport=$rpcportoffset\ndaemon=1\nserver=1\nlisten=1\n" >> "node$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$rpcportoffset --userpass=rpc:12410516051fd5fsd4rsd3 --threads=1" >> "node$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$rpcportoffset --userpass=rpc:12410516051fd5fsd4rsd3 --threads=1" >> "node$i"/mine-neoscrypt.sh
      sudo chmod +x "node$i"/*.sh
    done
else
  sudo killall -9 ignitiond
  rm -r node1 && rm -r node2 && rm -r node3 && rm -r node4 && rm -r node5 && rm -r node6 && rm -r node7
  for i in {1..7}
    do
      rpcportoffset=$((44155+$i))
      portoffset=$((44144+$i))
      #connectOffset=$((33133+$i))
      mkdir "node$i"
      printf "rpcuser=ICrpc\nrpcpassword=12410516051fd5fsd4rsd3\nrpcallowip=127.0.0.1\nmaxconnections=125\ndaemon=1\nserver=1\nlisten=1\n" >> "node$i"/Ignition.conf
      printf "cd ../ && ./minerd --algo=scrypt --url=127.0.0.1:$rpcportoffset --userpass=rpc:12410516051fd5fsd4rsd3 --threads=1" >> "node$i"/mine-scrypt.sh
      printf "cd ../ && ./minerdn --no-gbt --url=127.0.0.1:$rpcportoffset --userpass=rpc:12410516051fd5fsd4rsd3 --threads=1" >> "node$i"/mine-neoscrypt.sh
      sudo chmod +x "node$i"/*.sh
    done
fi

./ignitiond --datadir=./node1 &
./ignitiond --datadir=./node2 &
./ignitiond --datadir=./node3 &
./ignitiond --datadir=./node4 &
./ignitiond --datadir=./node5 &
./ignitiond --datadir=./node6 &
./ignitiond --datadir=./node7 &

wget https://github.com/pooler/cpuminer/releases/download/v2.5.0/pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && tar -xvf pooler-cpuminer-2.5.0-linux-x86_64.tar.gz
wget https://github.com/ghostlander/cpuminer-neoscrypt/releases/download/v2.4.3/cpuminer-neoscrypt-lin-2.4.3.tar.gz && tar -xvf cpuminer-neoscrypt-lin-2.4.3.tar.gz
cp cpuminer-neoscrypt-lin-2.4.3/64bit/minerd ./minerdn && rm pooler-cpuminer-2.5.0-linux-x86_64.tar.gz && rm cpuminer-neoscrypt-lin-2.4.3.tar.gz && rm -r cpuminer-neoscrypt-lin-2.4.3/
