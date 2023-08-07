// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@src/utils/Random.sol";

contract testRandom is Test {
    function testGenerateNumberRange() 
        public
    {
        vm.roll(200);

        (uint256 lower, uint256 upper) = (50, 100);   

        uint256[] memory Counter = new uint256[](upper-lower);
        
        for (uint nonce ; nonce < 100000 ; nonce++) {
            bytes32 seed = blockhash(1);
            uint256 n = Random.generateNumber(lower, upper, seed, nonce);
            Counter[n-50]++;
            assertFalse(!(50 <= n && n < 100));
        }

        for (uint blockNumber ; blockNumber < 200 ; blockNumber++) {
            bytes32 seed = blockhash(blockNumber);
            uint256 nonce = 0;
            uint256 n = Random.generateNumber(lower, upper, seed, nonce);
            assertFalse(!(50 <= n && n < 100));
        }

        uint256 maxCounter = max(Counter);
        uint256 minCounter = min(Counter);
        uint256 minLimit = (100000/50) * (80/100);
        uint256 maxLimit = (100000/50) * (120/100);

        assertFalse(!(maxCounter < maxLimit && minCounter > minLimit));
    }
 
    function max(uint256[] memory numbers) 
        internal pure 
        returns (uint256) 
    {
        require(numbers.length > 0);
        uint256 maxNumber = numbers[0];

        for (uint256 i = 0; i < numbers.length; i++) {
            if (numbers[i] > maxNumber) {
                maxNumber = numbers[i];
            }
        }

        return maxNumber;
    }

    function min(uint256[] memory numbers) 
        internal pure 
        returns (uint256) 
    {
        require(numbers.length > 0);
        uint256 minNumber = numbers[0];

        for (uint256 i = 0; i < numbers.length; i++) {
            if (numbers[i] < minNumber) {
                minNumber = numbers[i];
            }
        }

        return minNumber;
    }
}