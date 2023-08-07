// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library Random {
    function generateNumber(uint256 lower, uint256 upper, bytes32 seed, uint256 nonce) 
        internal pure
        returns(uint256)
    {
        uint256 r = uint256(keccak256(abi.encodePacked(seed, nonce)));
        return (lower + r % (upper - lower));
    }
}