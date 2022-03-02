// Copyright (c) 2010 Satoshi Nakamoto
// Copyright (c) 2009-2012 The Bitcoin developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "assert.h"

#include "chainparams.h"
#include "main.h"
#include "util.h"

#include <boost/assign/list_of.hpp>

using namespace boost::assign;

struct SeedSpec6 {
	uint8_t addr[16];
	uint16_t port;
};

#include "chainparamsseeds.h"

//
// Main network
//

// Convert the pnSeeds array into usable address objects.
static void convertSeeds(std::vector<CAddress> &vSeedsOut, const unsigned int *data, unsigned int count, int port)
{
	// It'll only connect to one or two seed nodes because once it connects,
	// it'll get a pile of addresses with newer timestamps.
	// Seed nodes are given a random 'last seen time' of between one and two
	// weeks ago.
	const int64_t nOneWeek = 7 * 24 * 60 * 60;
	for (unsigned int k = 0; k < count; ++k)
	{
		struct in_addr ip;
		unsigned int i = data[k], t;

		// -- convert to big endian
		t = (i & 0x000000ff) << 24u
			| (i & 0x0000ff00) << 8u
			| (i & 0x00ff0000) >> 8u
			| (i & 0xff000000) >> 24u;

		memcpy(&ip, &t, sizeof(ip));

		CAddress addr(CService(ip, port));
		addr.nTime = GetTime() - GetRand(nOneWeek) - nOneWeek;
		vSeedsOut.push_back(addr);
	}
}

class CMainParams : public CChainParams {
public:
	CMainParams() {
		// The message start string is designed to be unlikely to occur in normal data.
		// The characters are rarely used upper ASCII, not valid as UTF-8, and produce
		// a large 4-byte int at any alignment.
		pchMessageStart[0] = 0x5f;
		pchMessageStart[1] = 0x79;
		pchMessageStart[2] = 0x64;
		pchMessageStart[3] = 0xc9;
		vAlertPubKey = ParseHex("047d56dfe4da604d86552a456c8e40b8a56f979e73508851521d043b279301f32139ccc9f1475f3fc661b97138f0b49f65eff4deb025b23862075fadcd3538cc39");
		nDefaultPort = 44144;
		nRPCPort = 44155;
		bnProofOfWorkLimit = CBigNum(~uint256(0) >> 16);
		/* The initial difficulty after switching to NeoScrypt (0.0625) */
		bnNeoScryptFirstTarget = CBigNum(~uint256(0) >> 28);

		// Build the genesis block. Note that the output of the genesis coinbase cannot
		// be spent as it did not originally exist in the database.

		const char* pszTimestamp = "Here 18 Dec 2017 we start the Ignition";
		std::vector<CTxIn> vin;
		vin.resize(1);
		vin[0].scriptSig = CScript() << 0 << CBigNum(42) << vector<unsigned char>((const unsigned char*)pszTimestamp, (const unsigned char*)pszTimestamp + strlen(pszTimestamp));
		std::vector<CTxOut> vout;
		vout.resize(1);
		vout[0].SetEmpty();
		CTransaction txNew(1, 1426700641, vin, vout, 0);
		genesis.vtx.push_back(txNew);
		genesis.hashPrevBlock = 0;
		genesis.hashMerkleRoot = genesis.BuildMerkleTree();
		genesis.nVersion = 1;
		genesis.nTime = 1513634048; //
		genesis.nBits = 520159231;
		genesis.nNonce = 47950;



		hashGenesisBlock = genesis.GetHash();

		assert(genesis.hashMerkleRoot == uint256("0x2d960352c0162362a744b23a639a657fc8050ffba450f49a634166d7e4790b58"));
		assert(hashGenesisBlock == uint256("0x000088660811c8469e191c629657e36b6d339b9b76ce494cd9f957d59552bb3c"));


		base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1, 103); // i
		base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1, 39); // G
		base58Prefixes[SECRET_KEY] = std::vector<unsigned char>(1, 138); // x
		base58Prefixes[STEALTH_ADDRESS] = std::vector<unsigned char>(1, 76); // X
		base58Prefixes[EXT_PUBLIC_KEY] = list_of(0x04)(0x88)(0x06)(0x2D).convert_to_container<std::vector<unsigned char> >();
		base58Prefixes[EXT_SECRET_KEY] = list_of(0x04)(0x88)(0xAD)(0xE4).convert_to_container<std::vector<unsigned char> >();

//Replacing centralized seeders with a snapshot of masternodes and few others on 2022-02-20
		vSeeds.push_back(CDNSSeedData("seednode-america", "america.ignitioncoin.org"));
		vSeeds.push_back(CDNSSeedData("seednode-explorer", "explorer.ignitioncoin.org"));
		vSeeds.push_back(CDNSSeedData("161.97.136.254", "161.97.136.254"));
		vSeeds.push_back(CDNSSeedData("161.97.137.0", "161.97.137.0"));
		vSeeds.push_back(CDNSSeedData("161.97.137.1", "161.97.137.1"));
		vSeeds.push_back(CDNSSeedData("162.253.68.240", "162.253.68.240"));
		vSeeds.push_back(CDNSSeedData("164.68.102.148", "164.68.102.148"));
		vSeeds.push_back(CDNSSeedData("164.68.112.233", "164.68.112.233"));
		vSeeds.push_back(CDNSSeedData("167.86.102.231", "167.86.102.231"));
		vSeeds.push_back(CDNSSeedData("167.86.102.234", "167.86.102.234"));
		vSeeds.push_back(CDNSSeedData("167.86.103.119", "167.86.103.119"));
		vSeeds.push_back(CDNSSeedData("167.86.124.237", "167.86.124.237"));
		vSeeds.push_back(CDNSSeedData("167.86.127.48", "167.86.127.48"));
		vSeeds.push_back(CDNSSeedData("167.86.79.4", "167.86.79.4"));
		vSeeds.push_back(CDNSSeedData("167.86.83.59", "167.86.83.59"));
		vSeeds.push_back(CDNSSeedData("167.86.85.147", "167.86.85.147"));
		vSeeds.push_back(CDNSSeedData("167.86.89.49", "167.86.89.49"));
		vSeeds.push_back(CDNSSeedData("167.86.91.104", "167.86.91.104"));
		vSeeds.push_back(CDNSSeedData("167.86.91.140", "167.86.91.140"));
		vSeeds.push_back(CDNSSeedData("167.86.96.109", "167.86.96.109"));
		vSeeds.push_back(CDNSSeedData("167.86.97.7", "167.86.97.7"));
		vSeeds.push_back(CDNSSeedData("167.86.97.9", "167.86.97.9"));
		vSeeds.push_back(CDNSSeedData("173.212.223.176", "173.212.223.176"));
		vSeeds.push_back(CDNSSeedData("173.212.225.161", "173.212.225.161"));
		vSeeds.push_back(CDNSSeedData("173.249.36.55", "173.249.36.55"));
		vSeeds.push_back(CDNSSeedData("173.249.40.165", "173.249.40.165"));
		vSeeds.push_back(CDNSSeedData("173.249.6.78", "173.249.6.78"));
		vSeeds.push_back(CDNSSeedData("174.251.64.8", "174.251.64.8"));
		vSeeds.push_back(CDNSSeedData("174.251.65.210", "174.251.65.210"));
		vSeeds.push_back(CDNSSeedData("185.119.0.12", "185.119.0.12"));
		vSeeds.push_back(CDNSSeedData("185.34.216.108", "185.34.216.108"));
		vSeeds.push_back(CDNSSeedData("195.181.215.154", "195.181.215.154"));
		vSeeds.push_back(CDNSSeedData("207.180.204.186", "207.180.204.186"));
		vSeeds.push_back(CDNSSeedData("207.180.206.21", "207.180.206.21"));
		vSeeds.push_back(CDNSSeedData("207.180.211.105", "207.180.211.105"));
		vSeeds.push_back(CDNSSeedData("207.180.211.134", "207.180.211.134"));
		vSeeds.push_back(CDNSSeedData("207.180.216.124", "207.180.216.124"));
		vSeeds.push_back(CDNSSeedData("45.32.75.38", "45.32.75.38"));
		vSeeds.push_back(CDNSSeedData("54.89.181.4", "54.89.181.4"));
		vSeeds.push_back(CDNSSeedData("70.30.63.112", "70.30.63.112"));
		vSeeds.push_back(CDNSSeedData("70.30.63.23", "70.30.63.23"));
		vSeeds.push_back(CDNSSeedData("71.156.29.52", "71.156.29.52"));
		vSeeds.push_back(CDNSSeedData("73.211.238.177", "73.211.238.177"));
		vSeeds.push_back(CDNSSeedData("75.104.120.52", "75.104.120.52"));
		vSeeds.push_back(CDNSSeedData("80.211.63.237", "80.211.63.237"));
		vSeeds.push_back(CDNSSeedData("80.241.217.68", "80.241.217.68"));
		vSeeds.push_back(CDNSSeedData("81.4.111.96", "81.4.111.96"));
		vSeeds.push_back(CDNSSeedData("91.108.0.251", "91.108.0.251"));
		vSeeds.push_back(CDNSSeedData("94.225.34.185", "94.225.34.185"));
		vSeeds.push_back(CDNSSeedData("95.217.78.80", "95.217.78.80"));
		vSeeds.push_back(CDNSSeedData("107.15.220.153", "107.15.220.153"));
		vSeeds.push_back(CDNSSeedData("124.149.141.170", "124.149.141.170"));
		vSeeds.push_back(CDNSSeedData("136.49.86.118", "136.49.86.118"));
		vSeeds.push_back(CDNSSeedData("136.53.37.127", "136.53.37.127"));
		vSeeds.push_back(CDNSSeedData("144.202.83.222", "144.202.83.222"));
		vSeeds.push_back(CDNSSeedData("161.97.133.237", "161.97.133.237"));
		vSeeds.push_back(CDNSSeedData("167.99.153.194", "167.99.153.194"));
		vSeeds.push_back(CDNSSeedData("173.79.75.72", "173.79.75.72"));
		vSeeds.push_back(CDNSSeedData("174.94.2.52", "174.94.2.52"));
		vSeeds.push_back(CDNSSeedData("178.170.253.9", "178.170.253.9"));
		vSeeds.push_back(CDNSSeedData("184.146.57.48", "184.146.57.48"));
		vSeeds.push_back(CDNSSeedData("185.236.167.65", "185.236.167.65"));
		vSeeds.push_back(CDNSSeedData("185.82.203.241", "185.82.203.241"));
		vSeeds.push_back(CDNSSeedData("193.2.36.40", "193.2.36.40"));
		vSeeds.push_back(CDNSSeedData("2.59.132.236", "2.59.132.236"));
		vSeeds.push_back(CDNSSeedData("203.82.45.242", "203.82.45.242"));
		vSeeds.push_back(CDNSSeedData("207.180.244.200", "207.180.244.200"));
		vSeeds.push_back(CDNSSeedData("207.246.77.53", "207.246.77.53"));
		vSeeds.push_back(CDNSSeedData("209.126.13.50", "209.126.13.50"));
		vSeeds.push_back(CDNSSeedData("209.250.225.55:6970", "209.250.225.55:6970"));
		vSeeds.push_back(CDNSSeedData("216.250.114.165", "216.250.114.165"));
		vSeeds.push_back(CDNSSeedData("24.159.181.207", "24.159.181.207"));
		vSeeds.push_back(CDNSSeedData("37.153.237.21", "37.153.237.21"));
		vSeeds.push_back(CDNSSeedData("37.18.41.143", "37.18.41.143"));
		vSeeds.push_back(CDNSSeedData("45.77.69.168", "45.77.69.168"));
		vSeeds.push_back(CDNSSeedData("46.151.159.53", "46.151.159.53"));
		vSeeds.push_back(CDNSSeedData("51.222.94.20", "51.222.94.20"));
		vSeeds.push_back(CDNSSeedData("51.222.94.28", "51.222.94.28"));
		vSeeds.push_back(CDNSSeedData("51.89.139.159", "51.89.139.159"));
		vSeeds.push_back(CDNSSeedData("58.69.103.136", "58.69.103.136"));
		vSeeds.push_back(CDNSSeedData("62.171.128.147:44162", "62.171.128.147:44162"));
		vSeeds.push_back(CDNSSeedData("66.42.72.200", "66.42.72.200"));
		vSeeds.push_back(CDNSSeedData("67.1.244.29", "67.1.244.29"));
		vSeeds.push_back(CDNSSeedData("73.188.203.62", "73.188.203.62"));
		vSeeds.push_back(CDNSSeedData("76.218.98.85", "76.218.98.85"));
		vSeeds.push_back(CDNSSeedData("82.223.9.101", "82.223.9.101"));
		vSeeds.push_back(CDNSSeedData("85.156.135.83", "85.156.135.83"));
		vSeeds.push_back(CDNSSeedData("87.189.156.129", "87.189.156.129"));
		vSeeds.push_back(CDNSSeedData("87.225.105.6:44162", "87.225.105.6:44162"));
		vSeeds.push_back(CDNSSeedData("89.179.125.135", "89.179.125.135"));
		vSeeds.push_back(CDNSSeedData("95.179.147.152", "95.179.147.152"));
		vSeeds.push_back(CDNSSeedData("95.217.85.170", "95.217.85.170"));
		vSeeds.push_back(CDNSSeedData("98.124.121.80", "98.124.121.80"));
		vSeeds.push_back(CDNSSeedData("87.98.185.244", "87.98.185.244"));
		vSeeds.push_back(CDNSSeedData("70.30.62.117", "70.30.62.117"));
		vSeeds.push_back(CDNSSeedData("70.173.186.75", "70.173.186.75"));
		vSeeds.push_back(CDNSSeedData("161.97.136.252", "161.97.136.252"));

		convertSeeds(vFixedSeeds, pnSeed, ARRAYLEN(pnSeed), nDefaultPort);

		nPoolMaxTransactions = 3;
		//strSporkKey = "046f78dcf911fbd61910136f7f0f8d90578f68d0b3ac973b5040fb7afb501b5939f39b108b0569dca71488f5bbf498d92e4d1194f6f941307ffd95f75e76869f0e";
		//strMasternodePaymentsPubKey = "046f78dcf911fbd61910136f7f0f8d90578f68d0b3ac973b5040fb7afb501b5939f39b108b0569dca71488f5bbf498d92e4d1194f6f941307ffd95f75e76869f0e";
		strDarksendPoolDummyAddress = "i7FBJNGDmEsU5wx2m3xw85N8kRgCqA8S7L";
		nLastPOWBlock = nForkTwo + 200;
		nPOSStartBlock = 1;
	}


	virtual const CBlock& GenesisBlock() const { return genesis; }
	virtual Network NetworkID() const { return CChainParams::MAIN; }

	virtual const vector<CAddress>& FixedSeeds() const {
		return vFixedSeeds;
	}
protected:
	CBlock genesis;
	vector<CAddress> vFixedSeeds;
};
static CMainParams mainParams;


//
// Testnet
//

class CTestNetParams : public CMainParams {
public:
	CTestNetParams() {
		// The message start string is designed to be unlikely to occur in normal data.
		// The characters are rarely used upper ASCII, not valid as UTF-8, and produce
		// a large 4-byte int at any alignment.
		pchMessageStart[0] = 0x1d;
		pchMessageStart[1] = 0x7e;
		pchMessageStart[2] = 0xa6;
		pchMessageStart[3] = 0x2c;
		bnProofOfWorkLimit = CBigNum(~uint256(0) >> 16);
		bnNeoScryptFirstTarget = CBigNum(~uint256(0) >> 20);
		vAlertPubKey = ParseHex("042a4acc6f2c09d425e45c73b11e8f5c2afefdab644689948dbe3e7efbd32bfe8a810ed0532359f42f6a15830137c28d10504056cb64539e5fea5f9ed1dc62aa2b");
		nDefaultPort = 33133;
		nRPCPort = 33155;
		strDataDir = "testnet";

		// Modify the testnet genesis block so the timestamp is valid for a later start.
		genesis.nBits = 520159231;
		genesis.nNonce = 47950;

		assert(hashGenesisBlock == uint256("0x000088660811c8469e191c629657e36b6d339b9b76ce494cd9f957d59552bb3c"));

		vFixedSeeds.clear();
		vSeeds.clear();

		base58Prefixes[PUBKEY_ADDRESS] = std::vector<unsigned char>(1, 28);
		base58Prefixes[SCRIPT_ADDRESS] = std::vector<unsigned char>(1, 38);
		base58Prefixes[SECRET_KEY] = std::vector<unsigned char>(1, 88);
		base58Prefixes[STEALTH_ADDRESS] = std::vector<unsigned char>(1, 98);
		base58Prefixes[EXT_PUBLIC_KEY] = list_of(0x04)(0x35)(0x87)(0xCF).convert_to_container<std::vector<unsigned char> >();
		base58Prefixes[EXT_SECRET_KEY] = list_of(0x04)(0x35)(0x83)(0x94).convert_to_container<std::vector<unsigned char> >();

		convertSeeds(vFixedSeeds, pnTestnetSeed, ARRAYLEN(pnTestnetSeed), nDefaultPort);

		nLastPOWBlock = nTestnetForkTwo + 20;
	}
	virtual Network NetworkID() const { return CChainParams::TESTNET; }
};
static CTestNetParams testNetParams;


static CChainParams *pCurrentParams = &mainParams;

const CChainParams &Params() {
	return *pCurrentParams;
}

void SelectParams(CChainParams::Network network) {
	switch (network) {
	case CChainParams::MAIN:
		pCurrentParams = &mainParams;
		break;
	case CChainParams::TESTNET:
		pCurrentParams = &testNetParams;
		break;
	default:
		assert(false && "Unimplemented network");
		return;
	}
}

bool SelectParamsFromCommandLine() {

	fTestNet = GetBoolArg("-testnet", false);

	if (fTestNet) {
		SelectParams(CChainParams::TESTNET);
	}
	else {
		SelectParams(CChainParams::MAIN);
	}
	return true;
}
