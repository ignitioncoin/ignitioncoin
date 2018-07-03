FROM debian:9.4-slim

VOLUME /project

RUN apt-get update && apt-get install -y git build-essential libssl1.0-dev libdb++-dev libboost-all-dev libcrypto++-dev libqrencode-dev libminiupnpc-dev libgmp-dev libgmp3-dev autoconf autogen automake libtool qt5-default qt5-qmake qtbase5-dev-tools qttools5-dev-tools libboost-dev libboost-system-dev libboost-filesystem-dev libboost-program-options-dev libboost-thread-dev libdb++-dev zlib1g-dev && mkdir /scripts

WORKDIR /scripts

RUN touch scripts.sh && echo "#!/bin/bash" >> scripts.sh \
&& echo "qmake CONFIG+=debug;" >> scripts.sh \
&& echo "chmod 777 /project/src/leveldb/build_detect_platform /project/src/secp256k1/autogen.sh" >> scripts.sh \
&& echo "make -j3" >> scripts.sh \
&& echo "/project/Ignition-qt" >> scripts.sh

RUN chmod 777 scripts.sh

WORKDIR /project

CMD /scripts/scripts.sh
