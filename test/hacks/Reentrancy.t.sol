// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@test/helpers/ModelsHelpers.sol";
import "@test/helpers/RevertDataHelpers.sol";
import "@src/utils/Deployments.sol";

import "@src/OpenLotto.sol";

contract TestLotteryOperator is DummyLotteryOperator {
    // ticket_id => round => prizes
    mapping(uint32 => mapping(uint32 => uint32)) TicketPrizesTestData;

    mapping(uint32 => uint32[]) WinnersCountTestData;

    constructor() DummyLotteryOperator() {
        InitialTicketState = 1; // STATE_CLAIMED
    }

    function _setTicketPrizesTestData(uint32 ticket_id, uint32 round, uint32 data) public {
        TicketPrizesTestData[ticket_id][round] = data;
    }

    function _setWinnersCountTestData(uint32 lottery_id, uint32[] memory data) public {
        WinnersCountTestData[lottery_id] = data;
    }

    function _ticketPrizes(
        uint32 lottery_id,
        LotteryModel.LotteryItem memory lottery,
        uint32 ticket_id,
        TicketModel.TicketItem memory,
        uint32 round
    )
        internal
        override
        returns (uint32 prizes)
    {
        return TicketPrizesTestData[ticket_id][round];
    }

    function _lotteryWinnersCount(
        uint32 lottery_id,
        LotteryModel.LotteryItem memory lottery,
        uint32 round
    )
        internal
        override
        returns (uint32[] memory)
    {
        return (WinnersCountTestData[lottery_id]);
    }
}


contract AttackerContract {
    OpenLotto openlotto;
    uint32 target_id;

    constructor(OpenLotto _openlotto) {
        openlotto = _openlotto;
    }

    function setTarget(uint32 _target_id) external {
        target_id = _target_id;
    }

    fallback() external payable {
        TicketModel.TicketItem memory ticket;

        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = target_id;
        openlotto.BuyTicket(ticket);
    }
}


contract testReentrancy is Test {
    using LotteryModel for LotteryModel.LotteryItem;

    OpenLotto openlotto;

    LotteryDatabase lottery_db;
    TicketDatabase ticket_db;

    TestLotteryOperator testOperator;

    address lottery_manager_role = makeAddr("lottery_manager_role");

    address[3] distribution_pool =
        [makeAddr("distribution_pool[0]"), makeAddr("distribution_pool[1]"), makeAddr("distribution_pool[2]")];


    function setUp() public {
        openlotto = Deployments.deployAll(lottery_manager_role);

        testOperator = new TestLotteryOperator();
        testOperator.grantRole(testOperator.OPERATOR_CONTROLER_ROLE(), address(openlotto));

        LotteryModel.LotteryItem memory lottery;
        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "target";
        hoax(lottery_manager_role);
        openlotto.CreateLottery{value: 100 ether}(lottery);
    }

    function testReentrancyAttack() public {
        LotteryModel.LotteryItem memory lottery;
        TicketModel.TicketItem memory ticket;

        AttackerContract attacker = new AttackerContract(openlotto);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "attacker";
        lottery.DistributionPoolShare[0] = ud(0.25e18);
        lottery.DistributionPoolTo[0] = address(attacker);
        vm.prank(lottery_manager_role);
        uint32 lottery_id = openlotto.CreateLottery(lottery);

        attacker.setTarget(lottery_id);
        ticket = ModelsHelpers.newFilledTicket();
        ticket.LotteryID = lottery_id;
        // ReentrancyGuard.ReentrancyGuardReentrantCall.selector
        vm.expectRevert(OpenLotto.DistributionFailed.selector);
        openlotto.BuyTicket{value: 1 ether}(ticket);
    }
}