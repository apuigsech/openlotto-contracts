// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import "@test/helpers/ModelsHelpers.sol";
import "@test/helpers/RevertDataHelpers.sol";
import "@src/utils/Deployments.sol";

import "@src/OpenLotto.sol";


contract testOpenLotto is Test {
    using LotteryModel for LotteryModel.LotteryItem;

    OpenLotto openlotto;

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    TestLotteryOperator testOperator;

    address lottery_manager_role = makeAddr("lottery_manager_role");

    address[3] distribution_pool =
        [makeAddr("distribution_pool[0]"), makeAddr("distribution_pool[1]"), makeAddr("distribution_pool[2]")];

    address[10] player_accounts = [
        makeAddr("player_0"),
        makeAddr("player_1"),
        makeAddr("player_2"),
        makeAddr("player_3"),
        makeAddr("player_4"),
        makeAddr("player_5"),
        makeAddr("player_6"),
        makeAddr("player_7"),
        makeAddr("player_8"),
        makeAddr("player_9")
    ];

    function setUp() public {
        openlotto = Deployments.deployAllWithLotteryManager(lottery_manager_role);

        testOperator = new TestLotteryOperator();
        testOperator.grantRole(testOperator.OPERATOR_CONTROLER_ROLE(), address(openlotto));
    }

    function testAuthorization() public {
        LotteryModel.LotteryItem memory lottery;

        lottery = ModelsHelpers.newFilledLottery();
        vm.expectRevert(
            RevertDataHelpers.accessControlUnauthorizedAccount(address(this), openlotto.LOTTERY_MANAGER_ROLE())
        );
        openlotto.CreateLottery(lottery);

        vm.prank(lottery_manager_role);
        openlotto.CreateLottery(lottery);
    }

    function testCreateLottery() public {
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

    function testGetReserve() public {
        LotteryModel.LotteryItem memory lottery;
        uint32 id;

        lottery = ModelsHelpers.newFilledLottery();

        hoax(lottery_manager_role);
        id = openlotto.CreateLottery(lottery);
        assertEq(openlotto.GetReserve(id), 0 ether);

        hoax(lottery_manager_role);
        id = openlotto.CreateLottery{value: 100 ether}(lottery);
        assertEq(openlotto.GetReserve(id), 100 ether);
        assertEq(address(openlotto).balance, 100 ether);

        hoax(lottery_manager_role);
        id = openlotto.CreateLottery{value: 50 ether}(lottery);
        assertEq(openlotto.GetReserve(id), 50 ether);
        assertEq(address(openlotto).balance, 150 ether);
    }

    function testReadLottery() public {
        LotteryModel.LotteryItem memory lottery;

        vm.expectRevert(Database.InvalidID.selector);
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

    function testBuyTicket() public {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        uint initialBlockNumber = block.number;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "one";
        lottery.InitBlock = initialBlockNumber + 1000;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        uint32 lottery_id = openlotto.CreateLottery(lottery);
        vm.stopPrank();

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = 0;
        vm.expectRevert(Database.InvalidID.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 0;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 5;
        ticket.LotteryRoundInit = 4;
        vm.expectRevert(TicketModel.InvalidRounds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 11;
        vm.expectRevert(LotteryModel.InvalidTicketRounds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 2;
        ticket.NumBets = 2;
        vm.expectRevert(OpenLotto.InsuficientFunds.selector);
        openlotto.BuyTicket{ value: 3 ether }(ticket);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        assertEq(openlotto.BuyTicket{ value: 1 ether }(ticket), 1);
        ticket.LotteryRoundFini = 5;
        assertEq(openlotto.BuyTicket{ value: 5 ether }(ticket), 2);
        ticket.LotteryRoundFini = 10;
        assertEq(openlotto.BuyTicket{ value: 10 ether }(ticket), 3);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 1;
        assertEq(openlotto.BuyTicket{ value: 5 ether }(ticket), 4);
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 5;
        assertEq(openlotto.BuyTicket{ value: 5 ether }(ticket), 5);
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 10;
        assertEq(openlotto.BuyTicket{ value: 10 ether }(ticket), 6);

        vm.roll(initialBlockNumber + 1099);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        vm.roll(initialBlockNumber + 1100);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        vm.expectRevert(OpenLotto.InvalidRounds.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        vm.roll(initialBlockNumber + 2100);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        vm.expectRevert(LotteryModel.LotteryExpired.selector);
        openlotto.BuyTicket{ value: 1 ether }(ticket);
    }

    function testDistributionPool() public {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.BetPrice = 1 ether;
        lottery.DistributionPoolTo[0] = distribution_pool[0];
        lottery.DistributionPoolShare[0] = ud(0.1e18);
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
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        assertEq(distribution_pool[0].balance, 0.1 ether);
        assertEq(distribution_pool[1].balance, 0.075 ether);
        assertEq(distribution_pool[2].balance, 0.05 ether);
        assertEq(openlotto.GetReserve(lottery_id), 0.025 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        assertEq(distribution_pool[0].balance, 0.2 ether);
        assertEq(distribution_pool[1].balance, 0.15 ether);
        assertEq(distribution_pool[2].balance, 0.1 ether);
        assertEq(openlotto.GetReserve(lottery_id), 0.05 ether);
    }

    function testRoundJackpots() public {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        vm.startPrank(lottery_manager_role);
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "one";
        lottery.Rounds = 10;
        lottery.BetPrice = 1 ether;
        lottery.DistributionPoolTo[0] = distribution_pool[0];
        lottery.DistributionPoolShare[0] = ud(0.1e18);
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
        openlotto.BuyTicket{ value: 1 ether }(ticket);

        assertEq(openlotto.GetRoundJackpot(lottery_id, 1), 0.75 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 5;
        openlotto.BuyTicket{ value: 5 ether }(ticket);

        assertEq(openlotto.GetRoundJackpot(lottery_id, 1), 1.5 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 2), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 3), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 4), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 5), 0.75 ether);

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 10;
        openlotto.BuyTicket{ value: 10 ether }(ticket);

        assertEq(openlotto.GetRoundJackpot(lottery_id, 1), 2.25 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 2), 1.5 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 3), 1.5 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 4), 1.5 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 5), 1.5 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 6), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 7), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 8), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 9), 0.75 ether);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 10), 0.75 ether);
    }

    function testWithdrawTicket() public {
        LotteryModel.LotteryItem memory lottery = LotteryModel.newEmptyLottery();
        lottery.Name = "Dummy";
        lottery.InitBlock = block.number;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(0.3e18);
        lottery.PrizePoolAttributes[0] = bytes8(uint64(0));
        lottery.PrizePoolShare[1] = ud(0.25e18);
        lottery.PrizePoolAttributes[1] = bytes8(uint64(2));
        lottery.PrizePoolShare[2] = ud(0.2e18);
        lottery.PrizePoolAttributes[2] = bytes8(uint64(5));
        lottery.PrizePoolShare[3] = ud(0.15e18);
        lottery.PrizePoolAttributes[3] = bytes8(uint64(10));
        lottery.PrizePoolShare[4] = ud(0.1e18);
        lottery.PrizePoolAttributes[4] = bytes8(uint64(15));
        lottery.Operator = testOperator;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        for (uint256 i; i < 100; i++) {
            TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
            ticket.LotteryID = lottery_id;
            ticket.LotteryRoundInit = 1;
            ticket.LotteryRoundFini = 3;
            ticket.NumBets = 1;
            payable(player_accounts[(i + 1) % 10]).call{ value: 3 ether }("");
            vm.prank(player_accounts[(i + 1) % 10]);
            openlotto.BuyTicket{ value: 3 ether }(ticket);
        }

        uint32[] memory WinnersCountTestData = new uint32[](5);
        WinnersCountTestData[0] = 1;
        WinnersCountTestData[1] = 1;
        WinnersCountTestData[2] = 2;
        WinnersCountTestData[3] = 3;
        WinnersCountTestData[4] = 4;

        uint32 round = 1;
        vm.roll(lottery.resolutionBlock(round) + 1);

        testOperator._setWinnersCountTestData(lottery_id, WinnersCountTestData);
        testOperator._setTicketPrizesTestData(10, round, 1); // 00001
        vm.prank(address(testOperator));
        openlotto.ClaimTicket(10, round);
        openlotto.WithdrawTicket(10, round);
        vm.expectRevert(OpenLotto.TicketAlreadyWithdrawn.selector);
        openlotto.WithdrawTicket(10, round);

        round = 2;
        vm.roll(lottery.resolutionBlock(round) + 1);

        testOperator._setWinnersCountTestData(lottery_id, WinnersCountTestData);
        testOperator._setTicketPrizesTestData(10, round, 1); // 00001
        testOperator._setTicketPrizesTestData(11, round, 2); // 00010
        testOperator._setTicketPrizesTestData(12, round, 4); // 00100
        testOperator._setTicketPrizesTestData(13, round, 8); // 01000
        testOperator._setTicketPrizesTestData(14, round, 16); // 10000

        for (uint32 i = 1; i <= 100; i++) {
            vm.prank(address(testOperator));
            openlotto.ClaimTicket(i, round);
        }

        /**
         * - Pot: 100
         *             - Win 0:   30
         *             - Win 1:   25
         *             - Win 2:   20
         *             - Win 3:   15
         *             - Win 4:   10
         *     
         *         - Winners:
         *             - Win 0:    1
         *             - Win 1:    1
         *             - Win 2:    2
         *             - Win 3:    3
         *             - Win 4:    4  
         * 
         *         - Player        0   1   2   3   4   5   6   7   8   9  10 
         *             - Win 0:    1   0   0   0   0   0   0   0   0   0   0      
         *             - Win 1:    0   1   0   0   0   0   0   0   0   0   0   
         *             - Win 2:    0   0   1   0   0   0   0   0   0   0   0
         *             - Win 3:    0   0   0   1   0   0   0   0   0   0   0
         *             - Win 4:    0   0   0   0   1   0   0   0   0   0   0
         *     
         *         - Payouts:
         *             - Player 0: 30 ether
         *             - Player 1: 25 ether
         *             - Player 2: 10 ether
         *             - Player 3: 5 ether
         *             - Player 4: 2.5 ether
         */

        for (uint32 i = 1; i <= 100; i++) {
            openlotto.WithdrawTicket(i, round);
        }

        assertEq(player_accounts[0].balance, 30 ether + 30 ether);
        assertEq(player_accounts[1].balance, 25 ether);
        assertEq(player_accounts[2].balance, 10 ether);
        assertEq(player_accounts[3].balance, 5 ether);
        assertEq(player_accounts[4].balance, 2.5 ether);

        round = 3;
        vm.roll(lottery.resolutionBlock(round) + 1);

        testOperator._setWinnersCountTestData(lottery_id, WinnersCountTestData);
        testOperator._setTicketPrizesTestData(10, round, 31); // 11111
        testOperator._setTicketPrizesTestData(11, round, 28); // 11100
        testOperator._setTicketPrizesTestData(12, round, 24); // 11000
        testOperator._setTicketPrizesTestData(13, round, 16); // 10000

        for (uint32 i = 1; i <= 100; i++) {
            vm.prank(address(testOperator));
            openlotto.ClaimTicket(i, round);
        }

        /**
         * - Pot: 100
         *             - Win 0:   30
         *             - Win 1:   25
         *             - Win 2:   20
         *             - Win 3:   15
         *             - Win 4:   10
         *     
         *         - Winners:
         *             - Win 0:    1
         *             - Win 1:    1
         *             - Win 2:    2
         *             - Win 3:    3
         *             - Win 4:    4  
         * 
         *         - Player        0   1   2   3   4   5   6   7   8   9  10 
         *             - Win 0:    1   0   0   0   0   0   0   0   0   0   0      
         *             - Win 1:    1   0   0   0   0   0   0   0   0   0   0   
         *             - Win 2:    1   1   0   0   0   0   0   0   0   0   0
         *             - Win 3:    1   1   1   0   0   0   0   0   0   0   0
         *             - Win 4:    1   1   1   1   0   0   0   0   0   0   0
         *     
         *         - Payouts:
         *             - Player 0: 72.5 ether
         *             - Player 1: 17.5 ether
         *             - Player 2: 7.5 ether
         *             - Player 3: 2.5 ether
         *             - Player 4: 0 ether
         */

        for (uint32 i = 1; i <= 100; i++) {
            openlotto.WithdrawTicket(i, round);
        }

        assertEq(player_accounts[0].balance, 30 ether + 30 ether + 72.5 ether);
        assertEq(player_accounts[1].balance, 25 ether + 17.5 ether);
        assertEq(player_accounts[2].balance, 10 ether + 7.5 ether);
        assertEq(player_accounts[3].balance, 5 ether + 2.5 ether);
        assertEq(player_accounts[4].balance, 2.5 ether + 0 ether);
    }

    function testReadTicket() public { }

    // ClaimTicket must only be callable by the lottery's operator.
    function testClaimTicketUnauthorized() public {
        LotteryModel.LotteryItem memory lottery = ModelsHelpers.newFilledLottery();
        lottery.InitBlock = block.number;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        TicketModel.TicketItem memory ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        uint32 ticket_id = openlotto.BuyTicket{ value: 1 ether }(ticket);

        vm.expectRevert(OpenLotto.UnauthorizedOperator.selector);
        openlotto.ClaimTicket(ticket_id, 1);
    }

    // WithdrawTicket must revert if the ticket has not been claimed by the operator.
    function testWithdrawBeforeClaimReverts() public {
        LotteryModel.LotteryItem memory lottery = ModelsHelpers.newFilledLottery();
        lottery.InitBlock = block.number;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        TicketModel.TicketItem memory ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        uint32 ticket_id = openlotto.BuyTicket{ value: 1 ether }(ticket);

        vm.expectRevert(OpenLotto.TicketNotClaimed.selector);
        openlotto.WithdrawTicket(ticket_id, 1);
    }

    // CreateLottery must reject operators that did not grant OPERATOR_CONTROLER_ROLE to OpenLotto.
    function testCreateLotteryRejectsOperatorWithoutRole() public {
        LotteryModel.LotteryItem memory lottery = ModelsHelpers.newFilledLottery();
        TestLotteryOperator badOperator = new TestLotteryOperator();
        badOperator.testEnableAuthorization(); // now real role checks apply and OpenLotto lacks the role
        lottery.Operator = badOperator;

        vm.prank(lottery_manager_role);
        vm.expectRevert(OpenLotto.OperatorRoleMissing.selector);
        openlotto.CreateLottery(lottery);
    }

    // WithdrawTicket must decrement the round jackpot by the amount paid.
    function testWithdrawDecrementsJackpot() public {
        LotteryModel.LotteryItem memory lottery = LotteryModel.newEmptyLottery();
        lottery.Name = "dec";
        lottery.InitBlock = block.number;
        lottery.Rounds = 1;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.Operator = testOperator;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 1;
        hoax(player_accounts[0], 1 ether);
        uint32 ticket_id = openlotto.BuyTicket{ value: 1 ether }(ticket);

        uint32[] memory winners = new uint32[](1);
        winners[0] = 1;
        testOperator._setWinnersCountTestData(lottery_id, winners);
        testOperator._setTicketPrizesTestData(ticket_id, 1, 1);

        vm.roll(lottery.resolutionBlock(1) + 1);
        vm.prank(address(testOperator));
        openlotto.ClaimTicket(ticket_id, 1);

        uint256 jackpotBefore = openlotto.GetRoundJackpot(lottery_id, 1);
        uint256 playerBefore = player_accounts[0].balance;
        openlotto.WithdrawTicket(ticket_id, 1);
        uint256 paid = player_accounts[0].balance - playerBefore;

        assertEq(paid, jackpotBefore);
        assertEq(openlotto.GetRoundJackpot(lottery_id, 1), 0);
    }

    // If the receiver of the prize rejects the payment, the withdrawal must revert so the user can retry.
    function testWithdrawRevertsOnFailedTransfer() public {
        RejectingReceiver receiver = new RejectingReceiver();

        LotteryModel.LotteryItem memory lottery = LotteryModel.newEmptyLottery();
        lottery.Name = "fail";
        lottery.InitBlock = block.number;
        lottery.Rounds = 1;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.Operator = testOperator;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 1;
        hoax(address(receiver), 1 ether);
        uint32 ticket_id = openlotto.BuyTicket{ value: 1 ether }(ticket);

        uint32[] memory winners = new uint32[](1);
        winners[0] = 1;
        testOperator._setWinnersCountTestData(lottery_id, winners);
        testOperator._setTicketPrizesTestData(ticket_id, 1, 1);

        vm.roll(lottery.resolutionBlock(1) + 1);
        vm.prank(address(testOperator));
        openlotto.ClaimTicket(ticket_id, 1);

        vm.expectRevert(OpenLotto.WithdrawFailed.selector);
        openlotto.WithdrawTicket(ticket_id, 1);
    }

    // The contract balance must always equal sum(reserves) + sum(roundJackpots).
    function testAccountingInvariantAfterBuyAndWithdraw() public {
        LotteryModel.LotteryItem memory lottery = LotteryModel.newEmptyLottery();
        lottery.Name = "inv";
        lottery.InitBlock = block.number;
        lottery.Rounds = 3;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.DistributionPoolTo[0] = address(0); // reserve
        lottery.DistributionPoolShare[0] = ud(0.1e18);
        lottery.Operator = testOperator;
        hoax(lottery_manager_role, 5 ether);
        uint32 lottery_id = openlotto.CreateLottery{ value: 5 ether }(lottery);

        TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 3;
        ticket.NumBets = 1;
        hoax(player_accounts[0], 4 ether);
        uint32 ticket_id = openlotto.BuyTicket{ value: 3 ether + 7 }(ticket);

        _assertAccountingInvariant(lottery_id, 3);

        uint32[] memory winners = new uint32[](1);
        winners[0] = 1;
        testOperator._setWinnersCountTestData(lottery_id, winners);
        testOperator._setTicketPrizesTestData(ticket_id, 1, 1);
        vm.roll(lottery.resolutionBlock(1) + 1);
        vm.prank(address(testOperator));
        openlotto.ClaimTicket(ticket_id, 1);
        openlotto.WithdrawTicket(ticket_id, 1);

        _assertAccountingInvariant(lottery_id, 3);
    }

    function _assertAccountingInvariant(uint32 lottery_id, uint32 rounds) internal {
        uint256 accounted = openlotto.GetReserve(lottery_id);
        for (uint32 r = 1; r <= rounds; r++) {
            accounted += openlotto.GetRoundJackpot(lottery_id, r);
        }
        assertEq(accounted, address(openlotto).balance);
    }

    // Every wei paid in BuyTicket must end up accounted (reserve + jackpots), no dust loss on integer division.
    function testBuyTicketNoDustLoss() public {
        LotteryModel.LotteryItem memory lottery = ModelsHelpers.newFilledLottery();
        lottery.Rounds = 7;
        lottery.BetPrice = 1 ether;
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        TicketModel.TicketItem memory ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 7;

        // 7 ether + 1 wei: the extra wei is a donation and must end up in the last-round jackpot as dust.
        uint256 payment = 7 ether + 1;
        openlotto.BuyTicket{ value: payment }(ticket);

        uint256 totalJackpots;
        for (uint32 r = 1; r <= 7; r++) {
            totalJackpots += openlotto.GetRoundJackpot(lottery_id, r);
        }
        assertEq(totalJackpots + openlotto.GetReserve(lottery_id), payment);
    }
}

contract RejectingReceiver {
    receive() external payable {
        revert("nope");
    }
}