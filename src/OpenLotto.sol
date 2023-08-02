// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/access/AccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";
import "@database/LotteryDatabase.sol";
import "@database/TicketDatabase.sol";

contract OpenLotto is AccessControl {
    bytes32 public constant LOTTERY_MANAGER_ROLE = keccak256("LOTTERY_MANAGER_ROLE");

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

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
        return lottery_db.Create(lottery);
    }

    function BuyTicket(TicketModel.TicketItem calldata ticket) 
        public
        returns(uint32 id)
    {
        return ticket_db.Create(ticket);
    }
}