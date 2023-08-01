// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/access/AccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

contract OpenLotto is AccessControl {
    bytes32 public constant LOTTERY_MANAGER = keccak256("LOTTERY_MANAGER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function CreateLottery(LotteryModel.LotteryItem calldata lottery) 
        public
        returns(uint32 id)
    {}

    function BuyTicket(TicketModel.TicketItem calldata ticket) 
        public
        returns(uint32 id)
    {}
}