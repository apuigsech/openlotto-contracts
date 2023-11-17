// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

/**
 * @title Random Library
 * @dev Library for generating random numbers using different seed per block number (using blockhash).
 */
library Random {
    error InvalidBlockNumber();

    /**
     * @dev Generates a seed for random number generation from a specified block number.
     * @param blockNumber The block number used as the source for the seed.
     * @return seed The generated seed for random number generation.
     */
    function seedFromBlock(uint256 blockNumber) internal view returns (bytes32 seed) {
        seed = blockhash(blockNumber);
        if (seed == 0) revert InvalidBlockNumber();
    }

    /**
     * @dev Generates a random number within a specified range using a seed and nonce.
     * @param lower The lower bound of the range (inclusive).
     * @param upper The upper bound of the range (exclusive).
     * @param seed The seed for random number generation.
     * @param nonce A nonce used to generate different numbers with the same seed.
     * @return randomNumber The generated random number.
     */
    function generateNumber(
        uint256 lower,
        uint256 upper,
        bytes32 seed,
        uint256 nonce
    )
        internal
        pure
        returns (uint256 randomNumber)
    {
        uint256 r = uint256(keccak256(abi.encodePacked(seed, nonce)));
        randomNumber = lower + r % (upper - lower);
    }
}

/**
 * @title Random Cached Seed Contract
 * @dev Contract that utilizes the Random library to generate random numbers with cached seeds.
 * To be able to retrieve previously used seeds after blockhash is not accesible.
 */
contract RandomCachedSeed {
    mapping(uint256 => bytes32) private CachedSeeds;

    /**
     * @dev Retrieves a cached seed for a given block number.
     * If the seed is not cached, generates and caches it.
     * @param blockNumber The block number for which to retrieve the seed.
     * @return seed The cached seed associated with the block number.
     */
    function _seed(uint256 blockNumber) internal returns (bytes32 seed) {
        if (CachedSeeds[blockNumber] == 0) CachedSeeds[blockNumber] = Random.seedFromBlock(blockNumber);
        seed = CachedSeeds[blockNumber];
    }
}
