// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@test/helpers/ModelsHelpers.sol";
import "@test/helpers/RevertDataHelpers.sol";
import "@test/helpers/Deployments.sol";

import "@src/OpenLotto.sol";

contract TestLotteryOperator is DummyLotteryOperator {

    // ticket_id => round => prizes
    mapping (uint32 => mapping(uint32 => uint32)) TicketPrizesTestData;

    // function _ticketPrizes(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 ticket_id, TicketModel.TicketItem memory, uint32 round) 
    //     override internal 
    //     returns(uint32 prizes) 
    // {
    //     TicketPrizesTestData[1][10] = 1;    // 00001
    //     TicketPrizesTestData[1][11] = 2;    // 00010
    //     TicketPrizesTestData[1][12] = 4;    // 00100
    //     TicketPrizesTestData[1][13] = 8;    // 01000
    //     TicketPrizesTestData[1][14] = 16;   // 10000
    //     TicketPrizesTestData[1][15] = 1;    // 00001
    //     TicketPrizesTestData[1][26] = 3;    // 00011
    //     TicketPrizesTestData[1][27] = 7;    // 00111
    //     TicketPrizesTestData[1][28] = 15;   // 01111
    //     TicketPrizesTestData[1][29] = 63;   // 11111

    //     return TicketPrizesTestData[ticket_id][round];
    // }  
}

contract testOpenLotto is Test {
    OpenLotto openlotto;

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    TestLotteryOperator testOperator;

    address lottery_manager_role = makeAddr("lottery_manager_role");

    address[3] distribution_pool = [
        makeAddr("distribution_pool[0]"), makeAddr("distribution_pool[1]"), makeAddr("distribution_pool[2]")
    ];

    address[10] player_accounts = [
        makeAddr("player_0"), makeAddr("player_1"), makeAddr("player_2"), makeAddr("player_3"), makeAddr("player_4"),
        makeAddr("player_5"), makeAddr("player_6"), makeAddr("player_7"), makeAddr("player_8"), makeAddr("player_9")
    ];

    function setUp() 
        public
    {
        openlotto = Deployments.deployAll(lottery_manager_role);

        testOperator = new TestLotteryOperator();
        testOperator.grantRole(testOperator.OPERATOR_CONTROLER_ROLE(), address(openlotto));
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
        lottery.PrizePoolShare[0] = ud(0.25e18);
        lottery.PrizePoolShare[1] = ud(0.25e18);
        lottery.PrizePoolShare[2] = ud(0.25e18);
        lottery.PrizePoolShare[3] = ud(0.25e18);
        lottery.PrizePoolShare[4] = ud(0.25e18);
        vm.expectRevert(LotteryModel.InvalidPrizePool.selector);
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
        lottery.InitBlock = 1000;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
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
        ticket.LotteryRoundFini = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

       ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 2;
        ticket.NumBets = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{value: 3 ether}(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        assertEq(openlotto.BuyTicket{value: 1 ether}(ticket), 1);
        ticket.LotteryRoundFini = 5;
        assertEq(openlotto.BuyTicket{value: 5 ether}(ticket), 2);
        ticket.LotteryRoundFini = 10;
        assertEq(openlotto.BuyTicket{value: 10 ether}(ticket), 3);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 1;
        assertEq(openlotto.BuyTicket{value: 5 ether}(ticket), 4);
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 5;
        assertEq(openlotto.BuyTicket{value: 5 ether}(ticket), 5);
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 10;
        assertEq(openlotto.BuyTicket{value: 10 ether}(ticket), 6);

        vm.roll(1099);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        vm.roll(1100);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        vm.expectRevert(OpenLotto.InvalidRounds.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);

        vm.roll(2100);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        vm.expectRevert(LotteryModel.LotteryExpired.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);
    }

    function testDistributionPool()
        public
    {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.BetPrice = 1 ether;
        lottery.DistributionPoolTo[0] = distribution_pool[0];
        lottery.DistributionPoolShare[0] = ud(0.10e18);
        lottery.DistributionPoolTo[1] = distribution_pool[1];
        lottery.DistributionPoolShare[1] = ud(0.075e18);
        lottery.DistributionPoolTo[2] = distribution_pool[2];
        lottery.DistributionPoolShare[2] = ud(0.05e18);
        lottery.DistributionPoolTo[3] = address(0); // Reserve.
        lottery.DistributionPoolShare[3] = ud(0.025e18);
        uint32 lottery_id = openlotto.CreateLottery(lottery);
        vm.stopPrank(); 

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        assertEq(distribution_pool[0].balance, 0.1 ether);
        assertEq(distribution_pool[1].balance, 0.075 ether); 
        assertEq(distribution_pool[2].balance, 0.05 ether);
        assertEq(openlotto.Reserve(lottery_id), 0.025 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        assertEq(distribution_pool[0].balance, 0.2 ether);
        assertEq(distribution_pool[1].balance, 0.15 ether); 
        assertEq(distribution_pool[2].balance, 0.1 ether);
        assertEq(openlotto.Reserve(lottery_id), 0.05 ether);
    }    

    function testRoundJackpots()
        public
    {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "one";
        lottery.Rounds = 10;
        lottery.BetPrice = 1 ether;
        lottery.DistributionPoolTo[0] = distribution_pool[0];
        lottery.DistributionPoolShare[0] = ud(0.10e18);
        lottery.DistributionPoolTo[1] = distribution_pool[1];
        lottery.DistributionPoolShare[1] = ud(0.075e18);
        lottery.DistributionPoolTo[2] = distribution_pool[2];
        lottery.DistributionPoolShare[2] = ud(0.05e18);
        lottery.DistributionPoolTo[3] = address(0); // Reserve.
        lottery.DistributionPoolShare[3] = ud(0.025e18);
        uint32 lottery_id = openlotto.CreateLottery(lottery);
        vm.stopPrank();

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        openlotto.BuyTicket{value: 1 ether}(ticket);

        assertEq(openlotto.RoundJackpot(lottery_id, 1), 0.75 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 5;
        openlotto.BuyTicket{value: 5 ether}(ticket);

        assertEq(openlotto.RoundJackpot(lottery_id, 1), 1.5 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 2), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 3), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 4), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 5), 0.75 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 10;
        openlotto.BuyTicket{value: 10 ether}(ticket);

        assertEq(openlotto.RoundJackpot(lottery_id, 1), 2.25 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 2), 1.5 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 3), 1.5 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 4), 1.5 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 5), 1.5 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 6), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 7), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 8), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 9), 0.75 ether);
        assertEq(openlotto.RoundJackpot(lottery_id, 10), 0.75 ether);
    }

    function testWithdrawTicket()
        public
    {
        LotteryModel.LotteryItem memory lottery = LotteryModel.newEmptyLottery();
        lottery.Name = "Dummy";
        lottery.InitBlock = 0;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(0.30e18);
        lottery.PrizePoolAttributes[0] = bytes8(uint64(0));
        lottery.PrizePoolShare[1] = ud(0.25e18);
        lottery.PrizePoolAttributes[1] = bytes8(uint64(2));
        lottery.PrizePoolShare[2] = ud(0.20e18);
        lottery.PrizePoolAttributes[2] = bytes8(uint64(5));
        lottery.PrizePoolShare[3] = ud(0.15e18);
        lottery.PrizePoolAttributes[3] = bytes8(uint64(10));
        lottery.PrizePoolShare[4] = ud(0.10e18);             
        lottery.PrizePoolAttributes[4] = bytes8(uint64(15));
        lottery.Operator = testOperator;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        for (uint i ; i < 100 ; i++) {
            TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
            ticket.LotteryID = lottery_id;
            ticket.LotteryRoundInit = 1;
            ticket.LotteryRoundFini = 1;
            ticket.NumBets = 1;
            payable(player_accounts[i % 10]).call{value: 40 ether}("");
            vm.prank(player_accounts[i % 10]);
            openlotto.BuyTicket{value: 1 ether}(ticket);
        }        
    }


    function testReadTicket()
        public
    {
    }
}