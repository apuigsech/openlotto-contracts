// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@test/helpers/ModelsHelpers.sol";
import "@test/helpers/RevertDataHelpers.sol";

import "@src/OpenLotto.sol";



contract testOpenLotto is Test {
    OpenLotto openlotto;

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    address lottery_manager_role = makeAddr("lottery_manager_role");

    address distribution_pool_0 = makeAddr("distribution_pool_0");
    address distribution_pool_1 = makeAddr("distribution_pool_1");
    address distribution_pool_2 = makeAddr("distribution_pool_2");

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

        lottery = ModelsHelpers.newFilledLottery();
        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(address(this), openlotto.LOTTERY_MANAGER_ROLE()));
        openlotto.CreateLottery(lottery);

        vm.prank(lottery_manager_role);
        openlotto.CreateLottery(lottery);
    }

    function testCreateLottery() 
        public
    {
        LotteryModel.LotteryItem memory lottery;

        vm.startPrank(lottery_manager_role);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "";
        vm.expectRevert(LotteryModel.InvalidName.selector);
        openlotto.CreateLottery(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.Rounds = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        openlotto.CreateLottery(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.RoundBlocks = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        openlotto.CreateLottery(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.DistributionPoolShare[0] = ud(0.25e18);
        lottery.DistributionPoolShare[1] = ud(0.25e18);
        lottery.DistributionPoolShare[2] = ud(0.25e18);
        lottery.DistributionPoolShare[3] = ud(0.25e18);
        lottery.DistributionPoolShare[4] = ud(0.25e18);
        vm.expectRevert(LotteryModel.InvalidDistributionPool.selector);
        openlotto.CreateLottery(lottery);

        lottery = ModelsHelpers.newFilledLottery();
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
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "one";
        uint32 id_1 = openlotto.CreateLottery(lottery);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "two";
        uint32 id_2 = openlotto.CreateLottery(lottery);
        lottery = ModelsHelpers.newFilledLottery();
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
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "one";
        lottery.Rounds = 10;
        uint32 lottery_id = openlotto.CreateLottery(lottery);
        vm.stopPrank();

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = 0;
        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 11;
        vm.expectRevert(LotteryModel.InvalidTicketRounds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{value: 0.5 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        assertEq(openlotto.BuyTicket{value: 1 ether}(ticket), 1);
        ticket.LotteryRoundFini = 5;
        assertEq(openlotto.BuyTicket{value: 5 ether}(ticket), 2);
        ticket.LotteryRoundFini = 10;
        assertEq(openlotto.BuyTicket{value: 10 ether}(ticket), 3);
    }

    function testDistributionPool()
        public
    {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();

        lottery.BetPrice = 1 ether;
        
        lottery.DistributionPoolTo[0] = distribution_pool_0;
        lottery.DistributionPoolShare[0] = ud(0.10e18);

        lottery.DistributionPoolTo[1] = distribution_pool_1;
        lottery.DistributionPoolShare[1] = ud(0.075e18);
        
        lottery.DistributionPoolTo[2] = distribution_pool_2;
        lottery.DistributionPoolShare[2] = ud(0.05e18);
        
        lottery.DistributionPoolTo[3] = address(0); // Reserve.
        lottery.DistributionPoolShare[3] = ud(0.025e18);
    
        uint32 lottery_id = openlotto.CreateLottery(lottery);
        vm.stopPrank(); 

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        assertEq(distribution_pool_0.balance, 0.1 ether);
        assertEq(distribution_pool_1.balance, 0.075 ether); 
        assertEq(distribution_pool_2.balance, 0.05 ether);
        assertEq(openlotto.Reserve(lottery_id), 0.025 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        assertEq(distribution_pool_0.balance, 0.2 ether);
        assertEq(distribution_pool_1.balance, 0.15 ether); 
        assertEq(distribution_pool_2.balance, 0.1 ether);
        assertEq(openlotto.Reserve(lottery_id), 0.05 ether);
    }    

    function testReadTicket()
        public
    {
    }
}