// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LotteryModel {
    error InvalidName();
    error InvalidRoundsConfiguration();

    struct LotteryItem{
        string Name;                    // Human-readable identifier for the lottery.

        uint256 InitBlock;              // Block number at which the lottery rounds are initialized or started.

        uint32 Rounds;                  // Number of rounds or iterations for the lottery (many times the lottery will be played).
        uint16 RoundBlocks;             // Number of blocks between each round.

        uint256 BetPrice;               // Cost of a single bet for the lottery.

        uint256 JackpotMin;             // Minimum size of the lottery jackpot.
    }

    function isValid(LotteryModel.LotteryItem memory lottery) 
        internal pure
    {
        if (bytes(lottery.Name).length == 0) { revert InvalidName(); }
        if (lottery.Rounds == 0 || lottery.RoundBlocks == 0) { revert InvalidRoundsConfiguration(); }
    }

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


library LotteryModelStorage {
    using LotteryModel for LotteryModel.LotteryItem;

    error InvalidID();

    struct LotteryStorage {
        mapping (uint32 => LotteryModel.LotteryItem) LotteryMap;
    }

    function set(LotteryStorage storage data, uint32 id, LotteryModel.LotteryItem calldata lottery)
        internal
        isValid(lottery)
    {
        data.LotteryMap[id] = lottery;        
    }

    function unset(LotteryStorage storage data, uint32 id)
        internal
    {
        delete data.LotteryMap[id];
    }

    function get(LotteryStorage storage data, uint32 id)
        internal view
        exist(data, id)
        returns (LotteryModel.LotteryItem storage lottery)
    {
        lottery = data.LotteryMap[id];

    }

    modifier exist(LotteryStorage storage data, uint32 id) {
        if (data.LotteryMap[id].Rounds == 0) { revert InvalidID(); }
        _;
    }

    modifier isValid(LotteryModel.LotteryItem calldata lottery) {
        LotteryModel.isValid(lottery);
        _;
    }
}