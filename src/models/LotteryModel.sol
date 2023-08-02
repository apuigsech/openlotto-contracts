// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UD60x18, ud} from "@prb/math/UD60x18.sol";

import "@models/TicketModel.sol";

/// @title Library containing the data model and functions related to the LotteryItem struct.
library LotteryModel {
    // Custom errors used for validation.
    /// @dev Error thrown when the name of the lottery is invalid (empty or non-existent).
    error InvalidName();
    /// @dev Error thrown when the rounds configuration of the lottery is invalid (zero rounds or round blocks).
    error InvalidRoundsConfiguration();
    /// @dev Error thrown when the distribution pool exceeds the 100%.
    error InvalidDistributionPool();
    /// @dev Error thrown when the ticket rounds are not compatible with the lottery.
    error InvalidTicketRounds(); 

    // Number of entries on the distribution pool - distribuion of the income from bought tickets.
    uint8 private constant _MAX_DISTRIBUTIONPOOL = 5;

    /// @dev Data structure representing a specific lottery.
    struct LotteryItem {
        string Name;                                                // Human-readable identifier for the lottery.

        uint256 InitBlock;                                          // Block number at which the lottery rounds are initialized or started.

        uint32 Rounds;                                              // Number of rounds or iterations for the lottery (how many times the lottery will be played).
        uint16 RoundBlocks;                                         // Number of blocks between each round.

        uint256 BetPrice;                                           // Cost of a single bet for the lottery.

        uint256 JackpotMin;                                         // Minimum size of the lottery jackpot.

        address[_MAX_DISTRIBUTIONPOOL] DistributionPoolTo;           // Destination for the distribution pool entries. (address(0) sends money to the reserve, remaining value goes to jackpot).
        UD60x18[_MAX_DISTRIBUTIONPOOL] DistributionPoolShare;        // Share (%) for the distribution pool entries.
    }

    function MAX_DISTRIBUTIONPOOL()
        internal  pure
        returns(uint8)
    {
        return _MAX_DISTRIBUTIONPOOL;
    }

    /// @dev Function to validate whether a lottery item is valid (has a name and valid rounds configuration).
    function isValid(LotteryModel.LotteryItem memory lottery) 
        internal pure
    {
        if (bytes(lottery.Name).length == 0) revert InvalidName();
        if (lottery.Rounds == 0 || lottery.RoundBlocks == 0) revert InvalidRoundsConfiguration();
        
        UD60x18 totalDistributed =  ud(0e18);
        for (uint i ; i < _MAX_DISTRIBUTIONPOOL ; i++) {
            totalDistributed = totalDistributed + lottery.DistributionPoolShare[i];
            if (totalDistributed > ud(1e18)) revert InvalidDistributionPool();
        }

    }

    // @dev Function to validate whether a ticket item is compatible for a specific lottery item.
    function isValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) 
        internal pure
    {
        if (ticket.LotteryRoundFini > lottery.Rounds) revert InvalidTicketRounds();
    }

    /// @dev Function to create an empty LotteryItem.
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

/// @title Library containing functions to manage the storage of LotteryItems.
library LotteryModelStorage {
    using LotteryModel for LotteryModel.LotteryItem;

    // Custom error used when an invalid ID is encountered.
    /// @dev Error thrown when an invalid lottery ID is encountered.
    error InvalidID();

    /// @dev Data structure to store multiple lottery items.
    struct LotteryStorage {
        mapping (uint32 => LotteryModel.LotteryItem) LotteryMap;
    }

    /// @dev Function to set (update/create) a lottery item in the storage.
    function set(LotteryStorage storage data, uint32 id, LotteryModel.LotteryItem calldata lottery)
        internal
        isValid(lottery)
    {
        data.LotteryMap[id] = lottery;
    }

    /// @dev Function to unset (delete) a lottery item from the storage.
    function unset(LotteryStorage storage data, uint32 id)
        internal
    {
        delete data.LotteryMap[id];
    }

    /// @dev Function to get a specific lottery item from the storage by its ID.
    function get(LotteryStorage storage data, uint32 id)
        internal view
        exist(data, id)
        returns (LotteryModel.LotteryItem storage lottery)
    {
        lottery = data.LotteryMap[id];
    }

    /// @dev Modifier to check if a lottery item with a given ID exists in the storage.
    modifier exist(LotteryStorage storage data, uint32 id) {
        if (data.LotteryMap[id].Rounds == 0) revert InvalidID();
        _;
    }

    /// @dev Modifier to check if a LotteryItem is valid.
    modifier isValid(LotteryModel.LotteryItem calldata lottery) {
        LotteryModel.isValid(lottery);
        _;
    }
}
