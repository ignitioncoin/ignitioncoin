#!/bin/bash

# MXE env path
MXE_BASEPATH=/mnt/mxe-build

# Useful variables
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Install dependencies
echo -e "\n${GREEN}Installing dependencies${NC}"
sudo chmod +x install-dependencies.sh
./install-dependencies.sh

# Prepare the folders
sudo mkdir $MXE_BASEPATH
sudo chmod ogu+rw $MXE_BASEPATH

# # Clone MXE repo
echo -e "\n${GREEN}Cloning MXE${NC}"
git clone -b build-ic https://github.com/ignitioncoin/mxe.git $MXE_BASEPATH/mxe

# Number of cores
NB_CORES=`nproc`

# Build boost and QT5
cd $MXE_BASEPATH/mxe
echo -e "\n${GREEN}Building Boost${NC}"
make -j$NB_CORES MXE_TARGETS="i686-w64-mingw32.static" boost
echo -e "\n${GREEN}Building QT5${NC}"
make -j$NB_CORES MXE_TARGETS="i686-w64-mingw32.static" qttools

# Build Berkeley db
echo -e "\n${GREEN}Building Berkeley DB${NC}"
cd $MXE_BASEPATH
wget http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz
tar zxvf db-5.3.28.tar.gz
rm -f db-5.3.28.tar.gz
cd $MXE_BASEPATH/db-5.3.28
echo "" > compile-db.sh
chmod ugo+x compile-db.sh

cat << EOT >> compile-db.sh
#!/bin/bash
MXE_PATH=$MXE_BASEPATH/mxe
sed -i "s/WinIoCtl.h/winioctl.h/g" src/dbinc/win_db.h
mkdir build_mxe
cd build_mxe

CC=\$MXE_PATH/usr/bin/i686-w64-mingw32.static-gcc \\
CXX=\$MXE_PATH/usr/bin/i686-w64-mingw32.static-g++ \\
../dist/configure \\
	--disable-replication \\
	--enable-mingw \\
	--enable-cxx \\
	--host x86 \\
	--prefix=\$MXE_PATH/usr/i686-w64-mingw32.static

make -j$NB_CORES

make install
EOT

./compile-db.sh

# Build miniupnpc
echo -e "\n${GREEN}Building miniupnpc${NC}"
cd $MXE_BASEPATH
wget http://miniupnp.free.fr/files/miniupnpc-1.6.20120509.tar.gz
tar zxvf miniupnpc-1.6.20120509.tar.gz
rm -f miniupnpc-1.6.20120509.tar.gz
cd $MXE_BASEPATH/miniupnpc-1.6.20120509
echo "" > compile-m.sh
chmod ugo+x compile-m.sh

cat << EOT >> compile-m.sh
#!/bin/bash
MXE_PATH=$MXE_BASEPATH/mxe

CC=\$MXE_PATH/usr/bin/i686-w64-mingw32.static-gcc \\
AR=\$MXE_PATH/usr/bin/i686-w64-mingw32.static-ar \\
CFLAGS="-DSTATICLIB -I\$MXE_PATH/usr/i686-w64-mingw32.static/include" \\
LDFLAGS="-L\$MXE_PATH/usr/i686-w64-mingw32.static/lib" \\
make -j$NB_CORES libminiupnpc.a

mkdir \$MXE_PATH/usr/i686-w64-mingw32.static/include/miniupnpc
cp *.h \$MXE_PATH/usr/i686-w64-mingw32.static/include/miniupnpc
cp libminiupnpc.a \$MXE_PATH/usr/i686-w64-mingw32.static/lib
EOT

./compile-m.sh

# Done!
echo -e "\n${GREEN}MXE environment successfully set up!${NC}"
