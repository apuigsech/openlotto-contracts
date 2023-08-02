// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@src/OpenLotto.sol";


contract testOpenLotto is Test {
    OpenLotto openlotto;

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    address lottery_manager_role = makeAddr("lottery_manager_role");

    function _newFilledLottery() 
        internal pure 
        returns (LotteryModel.LotteryItem memory lottery)
    {
        lottery.Name = "dummy";
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
    }

    function _newFilledTicket()
        internal pure
        returns(TicketModel.TicketItem memory ticket)
    {
        ticket.LotteryID = 1;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
    }

    function setUp() 
        public
    {
        lottery_db = new LotteryDatabase();
        ticket_db = new TicketDatabase();
        openlotto = new OpenLotto(lottery_db, ticket_db);

        lottery_db.grantRole(lottery_db.CREATE_ROLE(), address(openlotto));
        lottery_db.grantRole(lottery_db.READ_ROLE(), address(openlotto));
        ticket_db.grantRole(ticket_db.CREATE_ROLE(), address(openlotto));
        ticket_db.grantRole(ticket_db.READ_ROLE(), address(openlotto));

        openlotto.grantRole(openlotto.LOTTERY_MANAGER_ROLE(), lottery_manager_role);
    }

    function testAuthorization() 
        public
    {
        LotteryModel.LotteryItem memory lottery;

        lottery = _newFilledLottery();
        vm.expectRevert(_accessControlUnauthorizedAccount(address(this), openlotto.LOTTERY_MANAGER_ROLE()));
        openlotto.CreateLottery(lottery);

        vm.prank(lottery_manager_role);
        openlotto.CreateLottery(lottery);
    }

    function testCreateLottery() 
        public
    {
        LotteryModel.LotteryItem memory lottery;

        vm.startPrank(lottery_manager_role);

        lottery = _newFilledLottery();
        lottery.Name = "";
        vm.expectRevert(LotteryModel.InvalidName.selector);
        openlotto.CreateLottery(lottery);

        lottery = _newFilledLottery();
        lottery.Rounds = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        openlotto.CreateLottery(lottery);

        lottery = _newFilledLottery();
        lottery.RoundBlocks = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        openlotto.CreateLottery(lottery);

        lottery = _newFilledLottery();
        assertEq(openlotto.CreateLottery(lottery), 1);
        assertEq(openlotto.CreateLottery(lottery), 2);
        assertEq(openlotto.CreateLottery(lottery), 3);
    
        vm.stopPrank();
    } 

    function testReadLottery() 
        public
    {
        LotteryModel.LotteryItem memory lottery;

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        lottery = openlotto.ReadLottery(0);

        vm.startPrank(lottery_manager_role);
        lottery = _newFilledLottery();
        lottery.Name = "one";
        uint32 id_1 = openlotto.CreateLottery(lottery);
        lottery = _newFilledLottery();
        lottery.Name = "two";
        uint32 id_2 = openlotto.CreateLottery(lottery);
        lottery = _newFilledLottery();
        lottery.Name = "three";
        uint32 id_3 = openlotto.CreateLottery(lottery);
        vm.stopPrank();

        lottery = openlotto.ReadLottery(id_1);
        assertEq(lottery.Name, "one");
        lottery = openlotto.ReadLottery(id_2);
        assertEq(lottery.Name, "two");
        lottery = openlotto.ReadLottery(id_3);
        assertEq(lottery.Name, "three");    
    }

    function testBuyTicket() 
        public
    {
        TicketModel.TicketItem memory ticket;

        ticket = _newFilledTicket();
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket(ticket);

        ticket = _newFilledTicket();
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket(ticket);

        ticket = _newFilledTicket();
        assertEq(openlotto.BuyTicket(ticket), 1);
        assertEq(openlotto.BuyTicket(ticket), 2);
        assertEq(openlotto.BuyTicket(ticket), 3);
    }

    function testReadTicket()
        public
    {
    }

    function _accessControlUnauthorizedAccount(address account, bytes32 role) 
        internal pure 
        returns(bytes memory) 
    {
        return abi.encodePacked(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            uint96(0),
            account,
            role
        );
    }

}