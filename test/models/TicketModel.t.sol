// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@models/TicketModel.sol";

contract wrapTicketModel {
    using TicketModel for TicketModel.TicketItem;

    function isValid(TicketModel.TicketItem memory ticket)
        public pure
    {
        ticket.isValid();
    }
}

contract testTicketModel is Test {
    using TicketModel for TicketModel.TicketItem;

    TicketModel.TicketItem ticket_storage;

    function _newFilledTicket()
        internal pure
        returns(TicketModel.TicketItem memory ticket)
    {
        ticket.LotteryID = 1;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
    }

    function testItemStorageGas()
        public
    {
        vm.pauseGasMetering();
        TicketModel.TicketItem memory ticket = _newFilledTicket();
        vm.resumeGasMetering();

        ticket_storage = ticket;
    }

    function testIsValid()
        public
    {    
        wrapTicketModel wrap = new wrapTicketModel();

        TicketModel.TicketItem memory ticket;

        ticket = _newFilledTicket();
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        wrap.isValid(ticket);

        ticket = _newFilledTicket();
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        wrap.isValid(ticket);

        ticket = _newFilledTicket();
        wrap.isValid(ticket);
    }
}