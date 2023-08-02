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

    bytes32 public constant LOTTERY_MANAGER_ROLE = keccak256("LOTTERY_MANAGER_ROLE");

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    mapping(uint32 => uint256) public Reserve;

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
        return lottery_db.Create(lottery);
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

        return ticket_db.Create(ticket);
    }

    function ReadTicket(uint32 id)
        public
        returns(TicketModel.TicketItem memory ticket)
    {
        return ticket_db.Read(id);
    }
}