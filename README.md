Ignition development tree

Ignition is a POW/PoS-based cryptocurrency.

IC is dependent upon libsecp256k1 by sipa, the sources for which can be found here:
https://github.com/bitcoin/secp256k1


Block Spacing: 120 Seconds
Diff Retarget: every Blocks
Maturity: 30 Blocks
Stake Minimum Age: 1/2 Hours

30 MegaByte Maximum Block Size (40X Bitcoin Core)

Port: 44144
RPC Port: 44155


IC includes an Address Index feature, based on the address index API (searchrawtransactions RPC command) implemented in Bitcoin Core but modified implementation to work with the IC codebase (PoS coins maintain a txindex by default for instance).

Initialize the Address Index By Running with -reindexaddr Command Line Argument.  It may take 10-15 minutes to build the initial index.
