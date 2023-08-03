// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@test/helpers/ModelsHelpers.sol";

import "@models/TicketModel.sol";

contract wrapTicketModel {
    using TicketModel for TicketModel.TicketItem;

    function isValid(TicketModel.TicketItem memory ticket)
        public pure
    {
        ticket.isValid();
    }
}

contract wrapTicketModelStorage {
    using TicketModelStorage for TicketModelStorage.TicketStorage;

    TicketModelStorage.TicketStorage data;

    function set(uint32 id, TicketModel.TicketItem calldata ticket)
        public
    {
        data.set(id, ticket);        
    }

    function unset(uint32 id)
        public
    {
        data.unset(id);
    }

    function get(uint32 id)
        public view
        returns (TicketModel.TicketItem memory ticket)
    {
        ticket = data.get(id);
    }    
}

contract testTicketModel is Test {
    using TicketModel for TicketModel.TicketItem;

    TicketModel.TicketItem ticket_storage;

    function testItemStorageGas()
        public
    {
        vm.pauseGasMetering();
        TicketModel.TicketItem memory ticket = ModelsHelpers.newFilledTicket();
        vm.resumeGasMetering();

        ticket_storage = ticket;
    }

    function testIsValid()
        public
    {    
        wrapTicketModel wrap = new wrapTicketModel();

        TicketModel.TicketItem memory ticket;

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        wrap.isValid(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        wrap.isValid(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        wrap.isValid(ticket);
    }
}

contract testTicketModelStorage is Test {

    function testSet()
        public
    {
        wrapTicketModelStorage wrap = new wrapTicketModelStorage(); 

        TicketModel.TicketItem memory ticket;

        ticket = ModelsHelpers.newFilledTicket(); 
        wrap.set(1, ticket);
        wrap.get(1);
    }

    function testUnset()
        public
    {
        wrapTicketModelStorage wrap = new wrapTicketModelStorage(); 

        TicketModel.TicketItem memory ticket;

        ticket = ModelsHelpers.newFilledTicket(); 
        wrap.set(1, ticket);
        wrap.get(1);

        wrap.unset(1);

        vm.expectRevert(TicketModelStorage.InvalidID.selector);
        wrap.get(1);
    }

    function testGet()
        public
    {
        wrapTicketModelStorage wrap = new wrapTicketModelStorage(); 

        TicketModel.TicketItem memory ticket;

        vm.expectRevert(TicketModelStorage.InvalidID.selector);
        wrap.get(1);

        ticket = ModelsHelpers.newFilledTicket(); 
        ticket.LotteryID = 1;
        wrap.set(1, ticket);
        ticket = ModelsHelpers.newFilledTicket(); 
        ticket.LotteryID = 2;
        wrap.set(2, ticket);
        ticket = ModelsHelpers.newFilledTicket(); 
        ticket.LotteryID = 3;
        wrap.set(3, ticket);

        ticket = wrap.get(1);
        assertEq(ticket.LotteryID, 1);
        ticket = wrap.get(2);
        assertEq(ticket.LotteryID, 2);
        ticket = wrap.get(3);
        assertEq(ticket.LotteryID, 3);    
    }
}