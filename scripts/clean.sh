cd ..
make clean
cd src
make -f makefile.unix clean
cd secp256k1
./autogen.sh
make clean
cd ../leveldb
make clean
