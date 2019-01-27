#!/usr/bin/env bash
# Add swap if needed
#    grep -q "swapfile" /etc/fstab
#    # if swap doesn't exist, create it
#    if [ $? -ne 0 ]; then
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BLUE_READ=$'\e[34m'
NC='\033[0m'
NC_READ=$'\e[0m'
SWAP_FILE="$HOME/ignitioncoin-swap"
MEMORY_SIZE=`grep MemTotal /proc/meminfo | awk '{print $2}'`

if [ "$MEMORY_SIZE" -lt "1000000" ]; then
	echo -e "\n${GREEN}Adding 4G swap to compile${NC}"
	sudo fallocate -l 4G $SWAP_FILE
	chmod 600 $SWAP_FILE
	sudo mkswap $SWAP_FILE
	sudo swapon $SWAP_FILE
else
    echo "Swap of sufficient size already exists, skipping swap creation"
fi