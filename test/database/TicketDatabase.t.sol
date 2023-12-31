// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";
import "@test/helpers/ModelsHelpers.sol";

import "@src/database/TicketDatabase.sol";

contract testTicketDatabase is Test {
    TicketDatabase database;

    function setUp() public {
        database = new TicketDatabase();
        database.grantRole(database.CREATE_ROLE(), address(this));
        database.grantRole(database.READ_ROLE(), address(this));
        database.grantRole(database.UPDATE_ROLE(), address(this));
        database.grantRole(database.DELETE_ROLE(), address(this));
    }

    function testCreate() public {
        TicketModel.TicketItem memory ticket;

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        database.Create(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        database.Create(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        assertEq(database.Create(ticket), 1);
        assertEq(database.Create(ticket), 2);
        assertEq(database.Create(ticket), 3);
    }

    function testRead() public {
        TicketModel.TicketItem memory ticket;

        vm.expectRevert(Database.InvalidID.selector);
        ticket = database.Read(0);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = 1;
        uint32 id_1 = database.Create(ticket);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = 2;
        uint32 id_2 = database.Create(ticket);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = 3;
        uint32 id_3 = database.Create(ticket);

        ticket = database.Read(id_1);
        assertEq(ticket.LotteryID, 1);
        ticket = database.Read(id_2);
        assertEq(ticket.LotteryID, 2);
        ticket = database.Read(id_3);
        assertEq(ticket.LotteryID, 3);
    }
}
