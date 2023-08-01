// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LotteryModel {
    struct LotteryItem{
        string Name;                    // Human-readable identifier for the lottery.

        uint256 InitBlock;              // Block number at which the lottery rounds are initialized or started.
        uint32 Rounds;                  // Number of rounds or iterations for the lottery (many times the lottery will be played).
        uint16 RoundBlocks;             // Number of blocks between each round.

        uint256 BetPrice;               // Cost of a single bet for the lottery.

        uint256 JackpotMin;             // Minimum size of the lottery jackpot.
    }

    function isValid(LotteryModel.LotteryItem calldata lottery) 
        internal pure
    {}

    function newEmptyLottery()
        internal pure
        returns(LotteryModel.LotteryItem memory lottery) 
    {
        lottery.Name = "";
        lottery.InitBlock = 0;
        lottery.Rounds = 0;
        lottery.RoundBlocks = 0;
        lottery.BetPrice = 0;
        lottery.JackpotMin = 0;
    }

}