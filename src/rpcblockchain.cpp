// Copyright (c) 2010 Satoshi Nakamoto
// Copyright (c) 2009-2012 The Bitcoin developers
// Distributed under the MIT/X11 software license, see the accompanying
// file COPYING or http://www.opensource.org/licenses/mit-license.php.

#include "rpcserver.h"
#include "main.h"
#include "kernel.h"
#include "checkpoints.h"
#include "spork.h"

using namespace json_spirit;
using namespace std;

extern void TxToJSON(const CTransaction& tx, const uint256 hashBlock, json_spirit::Object& entry);
extern void spj(const CScript& scriptPubKey, Object& out, bool fIncludeHex);

double GetDifficulty(const CBlockIndex *blockindex) {

    /* The reference difficulty is 1.0 which is the lowest Bitcoin difficulty
     * and may not match the minimal difficulty of a particular altcoin */

    if(!blockindex && pindexBest)
      blockindex = GetPrevBlockIndex(pindexBest, 0, false);

    if(!blockindex) return(1.0);

    int nShift = (blockindex->nBits >> 24) & 0xff;

    double dDiff =
        (double)0x0000ffff / (double)(blockindex->nBits & 0x00ffffff);

    while (nShift < 29)
    {
        dDiff *= 256.0;
        nShift++;
    }
    while (nShift > 29)
    {
        dDiff /= 256.0;
        nShift--;
    }

    return dDiff;
}

double GetPoWMHashPS()
{
    if (pindexBest->nHeight >= Params().LastPOWBlock())
        return 0;

    int nPoWInterval = 72;
    int64_t nTargetSpacingWorkMin = 30, nTargetSpacingWork = 30;

    CBlockIndex* pindex = pindexGenesisBlock;
    CBlockIndex* pindexPrevWork = pindexGenesisBlock;

    while (pindex)
    {
        if (pindex->IsProofOfWork())
        {
            int64_t nActualSpacingWork = pindex->GetBlockTime() - pindexPrevWork->GetBlockTime();
            nTargetSpacingWork = ((nPoWInterval - 1) * nTargetSpacingWork + nActualSpacingWork + nActualSpacingWork) / (nPoWInterval + 1);
            nTargetSpacingWork = max(nTargetSpacingWork, nTargetSpacingWorkMin);
            pindexPrevWork = pindex;
        }

        pindex = pindex->pnext;
    }

    return GetDifficulty() * 4294.967296 / nTargetSpacingWork;
}

double GetPoSKernelPS()
{
    int nPoSInterval = 72;
    double dStakeKernelsTriedAvg = 0;
    int nStakesHandled = 0, nStakesTime = 0;

    CBlockIndex* pindex = pindexBest;;
    CBlockIndex* pindexPrevStake = NULL;

    while (pindex && nStakesHandled < nPoSInterval)
    {
        if (pindex->IsProofOfStake())
        {
            if (pindexPrevStake)
            {
                dStakeKernelsTriedAvg += GetDifficulty(pindexPrevStake) * 4294967296.0;
                nStakesTime += pindexPrevStake->nTime - pindex->nTime;
                nStakesHandled++;
            }
            pindexPrevStake = pindex;
        }

        pindex = pindex->pprev;
    }

    double result = 0;

    if (nStakesTime)
        result = dStakeKernelsTriedAvg / nStakesTime;

    result *= STAKE_TIMESTAMP_MASK + 1;

    return result;
}

Object blockToJSON(const CBlock& block, const CBlockIndex* blockindex, bool fPrintTransactionDetail)
{
    Object result;
    result.push_back(Pair("hash", block.GetHash().GetHex()));
    int confirmations = -1;
    // Only report confirmations if the block is on the main chain
    if (blockindex->IsInMainChain())
        confirmations = nBestHeight - blockindex->nHeight + 1;
    result.push_back(Pair("confirmations", confirmations));
    result.push_back(Pair("size", (int)::GetSerializeSize(block, SER_NETWORK, PROTOCOL_VERSION)));
    result.push_back(Pair("height", blockindex->nHeight));
    result.push_back(Pair("version", block.nVersion));
    result.push_back(Pair("merkleroot", block.hashMerkleRoot.GetHex()));
#ifndef LOWMEM
    result.push_back(Pair("mint", ValueFromAmount(blockindex->nMint)));
#endif
    result.push_back(Pair("moneysupply", ValueFromAmount(blockindex->nMoneySupply)));
    result.push_back(Pair("time", (int64_t)block.GetBlockTime()));
    result.push_back(Pair("nonce", (uint64_t)block.nNonce));
    result.push_back(Pair("bits", strprintf("%08x", block.nBits)));
    result.push_back(Pair("difficulty", GetDifficulty(blockindex)));
    result.push_back(Pair("blocktrust", leftTrim(blockindex->GetBlockTrust().GetHex(), '0')));
    result.push_back(Pair("chaintrust", leftTrim(blockindex->nChainTrust.GetHex(), '0')));
    if (blockindex->pprev)
        result.push_back(Pair("previousblockhash", blockindex->pprev->GetBlockHash().GetHex()));
    if (blockindex->pnext)
        result.push_back(Pair("nextblockhash", blockindex->pnext->GetBlockHash().GetHex()));

    result.push_back(Pair("flags", strprintf("%s%s", blockindex->IsProofOfStake()? "proof-of-stake" : "proof-of-work", blockindex->GeneratedStakeModifier()? " stake-modifier": "")));
    result.push_back(Pair("proofhash", blockindex->hashProof.GetHex()));
    result.push_back(Pair("entropybit", (int)blockindex->GetStakeEntropyBit()));
    result.push_back(Pair("modifier", strprintf("%016x", blockindex->nStakeModifier)));
    Array txinfo;
    BOOST_FOREACH (const CTransaction& tx, block.vtx)
    {
        if (fPrintTransactionDetail)
        {
            Object entry;

            entry.push_back(Pair("txid", tx.GetHash().GetHex()));
            TxToJSON(tx, 0, entry);

            txinfo.push_back(entry);
        }
        else
            txinfo.push_back(tx.GetHash().GetHex());
    }

    result.push_back(Pair("tx", txinfo));

    if (block.IsProofOfStake())
        result.push_back(Pair("signature", HexStr(block.vchBlockSig.begin(), block.vchBlockSig.end())));

    return result;
}

Value getbestblockhash(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 0)
        throw runtime_error(
            "getbestblockhash\n"
            "Returns the hash of the best block in the longest block chain.");

    return hashBestChain.GetHex();
}

Value getblockcount(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 0)
        throw runtime_error(
            "getblockcount\n"
            "Returns the number of blocks in the longest block chain.");

    return nBestHeight;
}


Value getdifficulty(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 0)
        throw runtime_error(
            "getdifficulty\n"
            "Returns the difficulty as a multiple of the minimum difficulty.");

    Object obj;
    obj.push_back(Pair("proof-of-work",        GetDifficulty(GetPrevBlockIndex(pindexBest, 0, false))));
    obj.push_back(Pair("proof-of-stake",       GetDifficulty(GetPrevBlockIndex(pindexBest, 0, true))));
    return obj;
}


Value getrawmempool(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 0)
        throw runtime_error(
            "getrawmempool\n"
            "Returns all transaction ids in memory pool.");

    vector<uint256> vtxid;
    mempool.queryHashes(vtxid);

    Array a;
    BOOST_FOREACH(const uint256& hash, vtxid)
        a.push_back(hash.ToString());

    return a;
}

Value getblockhash(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 1)
        throw runtime_error(
            "getblockhash <index>\n"
            "Returns hash of block in best-block-chain at <index>.");

    int nHeight = params[0].get_int();
    if (nHeight < 0 || nHeight > nBestHeight)
        throw runtime_error("Block number out of range.");

    CBlockIndex* pblockindex = FindBlockByHeight(nHeight);
    return pblockindex->phashBlock->GetHex();
}

Value getblock(const Array& params, bool fHelp)
{
    if (fHelp || params.size() < 1 || params.size() > 2)
        throw runtime_error(
            "getblock <hash> [txinfo]\n"
            "txinfo optional to print more detailed tx info\n"
            "Returns details of a block with given block-hash.");

    std::string strHash = params[0].get_str();
    uint256 hash(strHash);

    if (mapBlockIndex.count(hash) == 0)
        throw JSONRPCError(RPC_INVALID_ADDRESS_OR_KEY, "Block not found");

    CBlock block;
    CBlockIndex* pblockindex = mapBlockIndex[hash];
    block.ReadFromDisk(pblockindex, true);

    return blockToJSON(block, pblockindex, params.size() > 1 ? params[1].get_bool() : false);
}

Value getblockbynumber(const Array& params, bool fHelp)
{
    if (fHelp || params.size() < 1 || params.size() > 2)
        throw runtime_error(
            "getblockbynumber <number> [txinfo]\n"
            "txinfo optional to print more detailed tx info\n"
            "Returns details of a block with given block-number.");

    int nHeight = params[0].get_int();
    if (nHeight < 0 || nHeight > nBestHeight)
        throw runtime_error("Block number out of range.");

    CBlock block;
    CBlockIndex* pblockindex = mapBlockIndex[hashBestChain];
    while (pblockindex->nHeight > nHeight)
        pblockindex = pblockindex->pprev;

    uint256 hash = *pblockindex->phashBlock;

    pblockindex = mapBlockIndex[hash];
    block.ReadFromDisk(pblockindex, true);

    return blockToJSON(block, pblockindex, params.size() > 1 ? params[1].get_bool() : false);
}

// ppcoin: get information of sync-checkpoint
Value getcheckpoint(const Array& params, bool fHelp)
{
    if (fHelp || params.size() != 0)
        throw runtime_error(
            "getcheckpoint\n"
            "Show info of synchronized checkpoint.\n");

    Object result;
    const CBlockIndex* pindexCheckpoint = Checkpoints::AutoSelectSyncCheckpoint();

    result.push_back(Pair("synccheckpoint", pindexCheckpoint->GetBlockHash().ToString().c_str()));
    result.push_back(Pair("height", pindexCheckpoint->nHeight));
    result.push_back(Pair("timestamp", DateTimeStrFormat(pindexCheckpoint->GetBlockTime()).c_str()));

    result.push_back(Pair("policy", "rolling"));

    return result;
}

Value getblockchaininfo(const Array& params, bool fHelp)
{
  if (fHelp || params.size() != 0)
      throw runtime_error(
              "getblockchaininfo\n"
              "Returns an object containing various state info regarding block chain processing.\n"
              "\nResult:\n"
              "{\n"
              "  \"chain\": \"xxxx\",        (string) current chain (main, testnet)\n"
              "  \"blocks\": xxxxxx,         (numeric) the current number of blocks processed in the server\n"
              "  \"bestblockhash\": \"...\", (string) the hash of the currently best block\n"
              "  \"difficulty\": xxxxxx,     (numeric) the current difficulty\n"
              "  \"initialblockdownload\": xxxx, (bool) estimate of whether this IC node is in Initial Block Download mode.\n"
              "  \"verificationprogress\": xxxx, (numeric) estimate of verification progress [0..1]\n"
              "  \"chainwork\": \"xxxx\"     (string) total amount of work in active chain, in hexadecimal\n"
              "  \"moneysupply\": xxxx, (numeric) the current supply of IC in circulation\n"
              "}\n"
      );

  proxyType proxy;
  GetProxy(NET_IPV4, proxy);

  Object obj, diff;
  std::string chain = "testnet";
  if(!fTestNet)
      chain = "main";
      obj.push_back(Pair("chain",          chain));
    obj.push_back(Pair("blocks",         (int)nBestHeight));
    //obj.push_back(Pair("headers",      pindexBestHeader ? pindexBestHeader->nHeight : -1));
    obj.push_back(Pair("bestblockhash",  hashBestChain.GetHex()));
    diff.push_back(Pair("proof-of-work",  GetDifficulty()));
    diff.push_back(Pair("proof-of-stake", GetDifficulty(GetPrevBlockIndex(pindexBest, 0, true))));
    obj.push_back(Pair("difficulty",     diff));
    obj.push_back(Pair("initialblockdownload",  IsInitialBlockDownload()));
    obj.push_back(Pair("verificationprogress", Checkpoints::AutoSelectSyncCheckpoint()));
    obj.push_back(Pair("chainwork",      leftTrim(pindexBest->nChainTrust.GetHex(), '0')));
    obj.push_back(Pair("moneysupply",    ValueFromAmount(pindexBest->nMoneySupply)));
    //obj.push_back(Pair("size_on_disk",   CalculateCurrentUsage()));
    return obj;
}

Value gettxout(const Array& params, bool fHelp)
{
    if (fHelp || params.size() < 2 || params.size() > 3)
        throw runtime_error(
            "gettxout \"txid\" n ( includemempool )\n"
            "\nReturns details about an unspent transaction output.\n"
            "\nArguments:\n"
            "1. \"txid\"       (string, required) The transaction id\n"
            "2. n              (numeric, required) vout value\n"
            "3. includemempool  (boolean, optional) Whether to included the mem pool\n"
            "\nResult:\n"
            "{\n"
            "  \"bestblock\" : \"hash\",    (string) the block hash\n"
            "  \"confirmations\" : n,       (numeric) The number of confirmations\n"
            "  \"value\" : x.xxx,           (numeric) The transaction value in btc\n"
            "  \"scriptPubKey\" : {         (json object)\n"
            "     \"asm\" : \"code\",       (string) \n"
            "     \"hex\" : \"hex\",        (string) \n"
            "     \"reqSigs\" : n,          (numeric) Number of required signatures\n"
            "     \"type\" : \"pubkeyhash\", (string) The type, eg pubkeyhash\n"
            "     \"addresses\" : [          (array of string) array of bitcoin addresses\n"
            "        \"bitcoinaddress\"     (string) bitcoin address\n"
            "        ,...\n"
            "     ]\n"
            "  },\n"
            "  \"version\" : n,            (numeric) The version\n"
            "  \"coinbase\" : true|false   (boolean) Coinbase or not\n"
            "  \"coinstake\" : true|false  (boolean) Coinstake or not\n"
            "}\n"
        );

    LOCK(cs_main);

    Object ret;

    uint256 hash;
    hash.SetHex(params[0].get_str());
    int n = params[1].get_int();
    bool mem = true;
    if (params.size() == 3)
        mem = params[2].get_bool();

    CTransaction tx;
    uint256 hashBlock = 0;
    if (!GetTransaction(hash, tx, hashBlock, mem))
      return Value::null;

    if (n<0 || (unsigned int)n>=tx.vout.size() || tx.vout[n].IsNull())
      return Value::null;

    ret.push_back(Pair("bestblock", pindexBest->GetBlockHash().GetHex()));
    if (hashBlock == 0)
      ret.push_back(Pair("confirmations", 0));
    else
    {
      map<uint256, CBlockIndex*>::iterator mi = mapBlockIndex.find(hashBlock);
      if (mi != mapBlockIndex.end() && (*mi).second)
      {
        CBlockIndex* pindex = (*mi).second;
        if (pindex->IsInMainChain())
        {
          bool isSpent=false;
          CBlockIndex* p = pindex;
          p=p->pnext;
          for (; p; p = p->pnext)
          {
            CBlock block;
            CBlockIndex* pblockindex = mapBlockIndex[p->GetBlockHash()];
            block.ReadFromDisk(pblockindex, true);
            BOOST_FOREACH(const CTransaction& tx, block.vtx)
            {
              BOOST_FOREACH(const CTxIn& txin, tx.vin)
              {
                if( hash == txin.prevout.hash &&
                   (int64_t)txin.prevout.n )
                {
                  printf("spent at block %s\n", block.GetHash().GetHex().c_str());
                  isSpent=true; break;
                }
              }

              if(isSpent) break;
            }

            if(isSpent) break;
          }

          if(isSpent)
            return Value::null;

          ret.push_back(Pair("confirmations", pindexBest->nHeight - pindex->nHeight + 1));
        }
        else
          return Value::null;
      }
    }

    ret.push_back(Pair("value", ValueFromAmount(tx.vout[n].nValue)));
    Object o;
    spj(tx.vout[n].scriptPubKey, o, true);
    ret.push_back(Pair("scriptPubKey", o));
    ret.push_back(Pair("coinbase", tx.IsCoinBase()));
    ret.push_back(Pair("coinstake", tx.IsCoinStake()));

    return ret;
  }
