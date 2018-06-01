Ignition Release Tree

Ignition is a POW/PoS-based cryptocurrency.

Ignition is a PoW (Scrypt) / PoS / Master Node hybrid cryptocurrency, with a 5 million coin maximum supply, which is generated at a slower rate every 1 Million IC, until it's limit is reached. Master Node cost 3000IC, block size is 20MB, and block time is ~2Minutes.

50% of Blocks are PoW , and 50% are PoS, of which each PoS block is split between Masternode and Staker.

Block Spacing: 120 Seconds
Diff Retarget: every Blocks
Maturity: 30 Blocks
Stake Minimum Age: 1/2 Hours

Default Network Ports:
Port: 44144
RPC Port: 44155

Website: https://IgnitionCoin.org

LiveNet Explorer: http://explorer.ignitioncoin.org/

BitcoinTalk Announcement: https://bitcointalk.org/index.php?topic=2612608.0

White Paper: https://ignitioncoin.org/wp-content/uploads/2018/01/Ignition-Coin-White-Paper.pdf

For compiling on different architectures, see the docs/build-*os* documents. Otherwise, view releases page for windows qt-wallets.

****
IC includes an Address Index feature, based on the address index API (searchrawtransactions RPC command) implemented in Bitcoin Core but modified the implementation to work with the IC codebase (PoS coins maintain a txindex by default for instance).

Initialize the Address Index By Running with -reindexaddr Command Line Argument.  It may take 10-15 minutes to build the initial index.

IC is dependent upon libsecp256k1 by sipa, the sources for which can be found here:
https://github.com/bitcoin/secp256k1
****
