#!/usr/bin/env bash
# Add swap if needed
#    grep -q "swapfile" /etc/fstab
#    # if swap doesn't exist, create it
#    if [ $? -ne 0 ]; then
if [ "$MEMORY_SIZE" -lt "2000000" ]; then
	echo -e "\n${GREEN}Adding 4G swap to compile${NC}"
	sudo fallocate -l 4G $SWAP_FILE
	chmod 600 /swapfile
	sudo mkswap $SWAP_FILE
	sudo swapon $SWAP_FILE
else
    echo "Swap of sufficient size already exists, skipping swap creation"
fi