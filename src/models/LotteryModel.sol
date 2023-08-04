// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/utils/Address.sol";

import {UD60x18, ud} from "@prb/math/UD60x18.sol";

import "@models/TicketModel.sol";

abstract contract LotteryOperatorInterface is AccessControl {
    bytes32 public constant OPENLOTTO_ROLE = keccak256("OPENLOTTO_ROLE");

    uint32 private UnresolvedBets;
    mapping (uint32 => mapping (uint32 => uint32)) private UnresolvedBetsPerLotteryRound;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function CreateLottery(uint32 id, LotteryModel.LotteryItem memory lottery) 
        public
        onlyRole(OPENLOTTO_ROLE)
    {
        _createLottery(id, lottery);
    }

    function CreateTicket(uint32 id, TicketModel.TicketItem memory ticket)  
        public
        onlyRole(OPENLOTTO_ROLE)
    {
        for (uint32 round = ticket.LotteryRoundInit ; round <= ticket.LotteryRoundFini ; round++) { 
            UnresolvedBetsPerLotteryRound[ticket.LotteryID][round] += ticket.NumBets;
            UnresolvedBets += ticket.NumBets;
        }

        _createTicket(id, ticket);      
    }

    function IsValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) 
        public pure
    {
        _isValidTicket(lottery, ticket);
    }

    function TicketCombinations(TicketModel.TicketItem memory ticket) 
        public pure 
        returns(uint16)
    {
        return _ticketCombinations(ticket);
    }

    function TicketPrizes(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 ticket_id, TicketModel.TicketItem memory ticket, uint32 round) 
        public
        onlyRole(OPENLOTTO_ROLE)
        returns(uint32)
    {
        return _ticketPrizes(lottery_id, lottery, ticket_id, ticket, round);
    }

    function ResolveRound(uint32 lottery_id, uint32 round, uint256 seed, address caller)
        public
        onlyRole(OPENLOTTO_ROLE)
    {
        uint256 amount = UnresolvedBetsPerLotteryRound[lottery_id][round] * (address(this).balance / UnresolvedBets);

        UnresolvedBets -= UnresolvedBetsPerLotteryRound[lottery_id][round];
        UnresolvedBetsPerLotteryRound[lottery_id][round] = 0;

        _resolveRound(lottery_id, round, seed);

        payable(caller).transfer(amount);  
    }

    function _createLottery(uint32 id, LotteryModel.LotteryItem memory lottery) virtual internal;
    function _createTicket(uint32 id, TicketModel.TicketItem memory ticket) virtual internal;
    function _isValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) virtual internal pure;
    function _ticketCombinations(TicketModel.TicketItem memory ticket) virtual internal pure returns(uint16);
    function _ticketPrizes(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 ticket_id, TicketModel.TicketItem memory ticket, uint32 round) virtual internal returns(uint32);
    function _resolveRound(uint32 lottery_id, uint32 round, uint256 seed) virtual internal;
}

/// @title Library containing the data model and functions related to the LotteryItem struct.
library LotteryModel {
    // Custom errors used for validation.
    /// @dev Error thrown when the name of the lottery is invalid (empty or non-existent).
    error InvalidName();
    /// @dev Error thrown when the rounds configuration of the lottery is invalid (zero rounds or round blocks).
    error InvalidRoundsConfiguration();
    /// @dev Error thrown when the distribution pool exceeds the 100%.
    error InvalidDistributionPool();
    /// @dev Error thrown when the prize pool exceeds the 100%.
    error InvalidPrizePool();
    /// @dev rror thrown when the adddress of the lottery operator is not a contract.
    error InvalidOperator();
    /// @dev Error throun when a lottery is expired (all rounds are done).
    error LotteryExpired();
    /// @dev Error thrown when the ticket rounds are not compatible with the lottery.
    error InvalidTicketRounds(); 

    // Number of entries on the distribution pool - distribuion of the income from bought tickets.
    uint8 private constant _MAX_DISTRIBUTIONPOOL = 5;

    // Number of entries on the prize pool - distribuion of the jackpot to the winners.
    uint8 private constant _MAX_PRIZEPOOL = 20;

    /// @dev Data structure representing a specific lottery.
    struct LotteryItem {
        string Name;                                                // Human-readable identifier for the lottery.

        uint256 InitBlock;                                          // Block number at which the lottery rounds are initialized or started.

        uint32 Rounds;                                              // Number of rounds or iterations for the lottery (how many times the lottery will be played).
        uint16 RoundBlocks;                                         // Number of blocks between each round.

        uint256 BetPrice;                                           // Cost of a single bet for the lottery.

        uint256 JackpotMin;                                         // Minimum size of the lottery jackpot.

        address[_MAX_DISTRIBUTIONPOOL] DistributionPoolTo;          // Destination for the distribution pool entries. (address(0) sends money to the reserve, remaining value goes to jackpot).
        UD60x18[_MAX_DISTRIBUTIONPOOL] DistributionPoolShare;       // Share (%) for the distribution pool entries.

        UD60x18[_MAX_PRIZEPOOL] PrizePoolShare;                     // Share (%) for the prize pool entries.

        LotteryOperatorInterface Operator;                          // Contract that 'operates' this lottery.
        bytes16 Attributes;                                         // Attributes for the operator.
    }

    function MAX_DISTRIBUTIONPOOL()
        internal pure
        returns(uint8)
    {
        return _MAX_DISTRIBUTIONPOOL;
    }

    function MAX_PRIZEPOOL()
        internal pure
        returns(uint8)
    {
        return _MAX_PRIZEPOOL;
    }

    /// @dev Function to validate whether a lottery item is valid (has a name and valid rounds configuration).
    function isValid(LotteryModel.LotteryItem memory lottery) 
        internal view
    {
        if (bytes(lottery.Name).length == 0) revert InvalidName();
        if (lottery.Rounds == 0 || lottery.RoundBlocks == 0) revert InvalidRoundsConfiguration();
        
        UD60x18 totalDistributed; 
        
        totalDistributed = ud(0e18);
        for (uint i ; i < _MAX_DISTRIBUTIONPOOL ; i++) {
            totalDistributed = totalDistributed + lottery.DistributionPoolShare[i];
        }
        if (totalDistributed > ud(1e18)) revert InvalidDistributionPool();

        totalDistributed =  ud(0e18);
        for (uint i ; i < _MAX_PRIZEPOOL ; i++) {
            totalDistributed = totalDistributed + lottery.PrizePoolShare[i];
        }
        if (totalDistributed != ud(1e18)) revert InvalidPrizePool();

        if (!Address.isContract(address(lottery.Operator))) revert InvalidOperator();
    }

    /// @dev Function to validate whether a ticket item is compatible for a specific lottery item.
    function isValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) 
        internal pure
    {
        if (ticket.LotteryRoundFini > lottery.Rounds) revert InvalidTicketRounds();
    }

    /// @dev Function that returns the next round to be resolved for a specific lottery item on a specific block number;
    function nextRoundOnBlock(LotteryModel.LotteryItem memory lottery, uint256 blockNumber) 
        internal pure
        returns(uint32 round)
    {
        if (blockNumber < lottery.InitBlock) {
            blockNumber = lottery.InitBlock;
        }
        round = 1 + (uint32(blockNumber - lottery.InitBlock) / lottery.RoundBlocks);
        if (round > lottery.Rounds) revert LotteryExpired();
    }

    /// @dev Function that returns the next round to be resolved for a specific lottery item.
    function nextRound(LotteryModel.LotteryItem memory lottery)
        internal view
        returns(uint32 round)
    {
        round = nextRoundOnBlock(lottery, block.number);
    }

    /// @dev function that returns the resolution block for a specific lottery round.
    function resolutionBlock(LotteryModel.LotteryItem memory lottery, uint32 round) 
        internal pure 
        returns(uint256 blockNumber)
    {
        if (round > lottery.Rounds) revert LotteryExpired();
        blockNumber = lottery.InitBlock + round * lottery.RoundBlocks;
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
