// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/access/AccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";
import "@database/LotteryDatabase.sol";
import "@database/TicketDatabase.sol";

contract OpenLotto is AccessControl {
    using LotteryModel for LotteryModel.LotteryItem;
    using TicketModel for TicketModel.TicketItem;

    error DistributionFailed();

    error InsuficientFunds();

    error InvalidRounds();

    bytes32 public constant LOTTERY_MANAGER_ROLE = keccak256("LOTTERY_MANAGER_ROLE");

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    mapping(uint32 => uint256) public Reserve;
    mapping(uint32 => mapping(uint32 => uint256)) public RoundJackpot;

    constructor(LotteryDatabase _lottery_db, TicketDatabase _ticket_db) {
        lottery_db = _lottery_db;
        ticket_db = _ticket_db;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function CreateLottery(LotteryModel.LotteryItem calldata lottery) 
        public
        onlyRole(LOTTERY_MANAGER_ROLE)
        returns(uint32 id)
    {
        lottery.isValid();
        id = lottery_db.Create(lottery);
        lottery.Operator.CreateLottery(id, lottery);
    }

    function ReadLottery(uint32 id)
        public view
        returns(LotteryModel.LotteryItem memory lottery)
    {
        return lottery_db.Read(id);
    }

    function BuyTicket(TicketModel.TicketItem calldata ticket)
        public payable
        returns(uint32 id)
    {
        ticket.isValid();
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(ticket.LotteryID);
        lottery.isValidTicket(ticket);
        lottery.Operator.IsValidTicket(lottery, ticket);

        if (ticket.LotteryRoundInit < lottery.nextRound()) revert InvalidRounds();

        uint32 roundsCount = 1 + ticket.LotteryRoundFini - ticket.LotteryRoundInit;
        
        uint256 ticketCost = lottery.BetPrice;
        ticketCost *= ticket.NumBets;
        ticketCost *= lottery.Operator.TicketCombinations(ticket);
        ticketCost *= roundsCount;

        if (msg.value < ticketCost) revert InsuficientFunds();

        UD60x18 totalValue = ud(msg.value);
        UD60x18 remainingValue = totalValue;
        for (uint i ; i < LotteryModel.MAX_DISTRIBUTIONPOOL() ; i++) {
            UD60x18 distributeValue = totalValue * lottery.DistributionPoolShare[i];
            remainingValue = remainingValue - distributeValue;
            if (address(lottery.DistributionPoolTo[i]) != address(0)) {
                (bool sent,) = payable(lottery.DistributionPoolTo[i]).call{value: distributeValue.unwrap()}("");
                if (!sent) revert DistributionFailed();
            } else {
                Reserve[ticket.LotteryID] += distributeValue.unwrap();
            }
        }

        uint valuePerRound = remainingValue.unwrap() / roundsCount;
        for (uint32 round = ticket.LotteryRoundInit ; round <= ticket.LotteryRoundFini ; round++ ) {
            RoundJackpot[ticket.LotteryID][round] += valuePerRound;
        }

        id = ticket_db.Create(ticket);
        lottery.Operator.CreateTicket(id, ticket);
    }

    function ReadTicket(uint32 id)
        public view
        returns(TicketModel.TicketItem memory ticket)
    {
        return ticket_db.Read(id);
    }

    function ResolveRound(uint32 id, uint32 round) public {
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(id);
        lottery.Operator.ResolveRound(id, round, 0, msg.sender);
    }


    function TicketPrizes(uint32 id, uint32 round)
        public
        returns(uint32)
    {
        TicketModel.TicketItem memory ticket = ticket_db.Read(id);
        LotteryModel.LotteryItem memory lottery = lottery_db.Read(ticket.LotteryID);

        return lottery.Operator.TicketPrizes(ticket.LotteryID, lottery, id, ticket, round);
    }
}