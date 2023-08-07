// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Random {
    error InvalidBlockNumber();

    function seedFromBlock(uint256 blockNumber)
        internal view
        returns(bytes32 seed)
    {
        seed = blockhash(blockNumber);
        if (seed == 0) revert InvalidBlockNumber();
    }

    function generateNumber(uint256 lower, uint256 upper, bytes32 seed, uint256 nonce) 
        internal pure
        returns(uint256)
    {
        uint256 r = uint256(keccak256(abi.encodePacked(seed, nonce)));
        return (lower + r % (upper - lower));
    }
}

contract RandomCachedSeed {
    mapping(uint256 => bytes32) CachedSeeds;

    function _seed(uint256 blockNumber)
        internal
        returns(bytes32)
    {
        if (CachedSeeds[blockNumber] == 0) CachedSeeds[blockNumber] = Random.seedFromBlock(blockNumber);
        return CachedSeeds[blockNumber];
    }
}