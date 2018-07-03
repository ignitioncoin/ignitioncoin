FROM debian:9.4-slim

RUN apt-get update && apt-get install -y p7zip-full autoconf automake autopoint bash bison bzip2 cmake flex gettext \
 git g++ gperf intltool libffi-dev libtool libtool-bin libltdl-dev libssl1.0-dev libgtk2.0-dev \
 libxml-parser-perl make openssl patch perl pkg-config python ruby scons sed unzip wget xz-utils g++-multilib libc6-dev-i386

ARG nbcores=`nbproc`

ARG MXE_BASEPATH=/mnt/mxe-build
RUN mkdir $MXE_BASEPATH && chmod ogu+rw $MXE_BASEPATH

RUN git clone -b build-ic https://github.com/ignitioncoin/mxe.git $MXE_BASEPATH/mxe

# build boost & qt
RUN cd $MXE_BASEPATH/mxe && echo -e "\nBuilding Boost" && make -j$NB_CORES MXE_TARGETS="i686-w64-mingw32.static" boost && make -j$NB_CORES MXE_TARGETS="i686-w64-mingw32.static" qttools

# Build Berkeley db
RUN cd $MXE_BASEPATH \
&& wget http://download.oracle.com/berkeley-db/db-5.3.28.tar.gz \
&& tar zxvf db-5.3.28.tar.gz \
&& rm -f db-5.3.28.tar.gz \
&& cd $MXE_BASEPATH/db-5.3.28 \
&& sed -i "s/WinIoCtl.h/winioctl.h/g" src/dbinc/win_db.h \
&& mkdir build_mxe && cd build_mxe \
&& CC=/mnt/mxe-build/mxe/usr/bin/i686-w64-mingw32.static-gcc CXX=/mnt/mxe-build/mxe/usr/bin/i686-w64-mingw32.static-g++ ../dist/configure --disable-replication --enable-mingw --enable-cxx --host x86 --prefix=/mnt/mxe-build/mxe/usr/i686-w64-mingw32.static \
&& make -j$NB_CORES \
&& make install


# Build miniupnpc
ARG MXE_PATH=$MXE_BASEPATH/mxe

RUN cd $MXE_BASEPATH \
&& wget http://miniupnp.free.fr/files/miniupnpc-1.6.20120509.tar.gz \
&& tar zxvf miniupnpc-1.6.20120509.tar.gz \
&& rm -f miniupnpc-1.6.20120509.tar.gz \
&& cd $MXE_BASEPATH/miniupnpc-1.6.20120509 \
&& CC=$MXE_PATH/usr/bin/i686-w64-mingw32.static-gcc AR=$MXE_PATH/usr/bin/i686-w64-mingw32.static-ar CFLAGS="-DSTATICLIB -I $MXE_PATH/usr/i686-w64-mingw32.static/include" LDFLAGS="-L $MXE_PATH/usr/i686-w64-mingw32.static/lib" make -j$NB_CORES libminiupnpc.a \
&& mkdir $MXE_BASEPATH/mxe/usr/i686-w64-mingw32.static/include/miniupnpc \
&& cp *.h $MXE_BASEPATH/mxe/usr/i686-w64-mingw32.static/include/miniupnpc \
&& cp libminiupnpc.a $MXE_BASEPATH/mxe/usr/i686-w64-mingw32.static/lib


### build IC
VOLUME /project

ENV PATH "$PATH:/mnt/mxe-build/mxe:/mnt/mxe-build/mxe/usr/bin"
WORKDIR project

ARG MXE_INCLUDE_PATH=$MXE_PATH/usr/i686-w64-mingw32.static/include
ARG MXE_LIB_PATH=$MXE_PATH/usr/MXE_LIB_PATH=$MXE_PATH/usr/i686-w64-mingw32.static/lib

RUN mkdir /scripts
WORKDIR /scripts

RUN touch scripts.sh && echo "chmod 777 /project/src/leveldb/build_detect_platform /project/src/secp256k1/autogen.sh" >> scripts.sh
RUN echo "i686-w64-mingw32.static-qmake-qt5 BOOST_LIB_SUFFIX=-mt BOOST_THREAD_LIB_SUFFIX=_win32-mt BOOST_INCLUDE_PATH=$MXE_INCLUDE_PATH/boost BOOST_LIB_PATH=$MXE_LIB_PATH OPENSSL_INCLUDE_PATH=$MXE_INCLUDE_PATH/openssl OPENSSL_LIB_PATH=$MXE_LIB_PATH	BDB_INCLUDE_PATH=$MXE_INCLUDE_PATH	BDB_LIB_PATH=$MXE_LIB_PATH MINIUPNPC_INCLUDE_PATH=$MXE_INCLUDE_PATH MINIUPNPC_LIB_PATH=$MXE_LIB_PATH QMAKE_LRELEASE=$MXE_PATH/usr/i686-w64-mingw32.static/qt5/bin/lrelease Ignition.pro" >> scripts.sh
RUN echo "make -f Makefile.Release" >> scripts.sh
RUN chmod 777 scripts.sh

WORKDIR /project

CMD /scripts/scripts.sh
