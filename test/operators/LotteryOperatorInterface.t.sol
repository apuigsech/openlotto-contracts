// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@test/helpers/Deployments.sol";
import "@test/helpers/ModelsHelpers.sol";
import "@test/helpers/RevertDataHelpers.sol";

import "@src/OpenLotto.sol";


contract LotteryOperator is LotteryOperatorInterface {
    constructor() {
        resolutionBlocksRange = 256;
    }

    function _createLottery(uint32, LotteryModel.LotteryItem memory) override internal {}
    function _createTicket(uint32 id, TicketModel.TicketItem memory ticket) override internal {}
    function _isValidTicket(LotteryModel.LotteryItem memory, TicketModel.TicketItem memory ticket) override internal pure {}
    function _ticketCombinations(TicketModel.TicketItem memory) override internal pure returns(uint16) { return 1; }
    function _ticketPrizes(uint32, LotteryModel.LotteryItem memory, uint32, TicketModel.TicketItem memory, uint32) override internal pure returns(uint32) { return 0; }  
    function _resolveRound(uint32, LotteryModel.LotteryItem memory lottery, uint32 round, uint256) override internal returns(bool) { return true; }
}

contract testLotteryOperator is Test {
    using LotteryModel for LotteryModel.LotteryItem;

    OpenLotto openlotto;
    LotteryOperatorInterface operator;

    LotteryModel.LotteryItem lottery;
    uint32 lottery_id;

    address lottery_manager_role = makeAddr("lottery_manager_role");
    address resolver_account_1 = makeAddr("resolver_account_1");
    address resolver_account_2 = makeAddr("resolver_account_2");
    address resolver_account_3 = makeAddr("resolver_account_3");

    function setUp()
        public
    {
        openlotto = Deployments.deployAll(lottery_manager_role);

        operator = new LotteryOperator();
        operator.grantRole(operator.OPERATOR_CONTROLER_ROLE(), address(openlotto));

        lottery = ModelsHelpers.newFilledLottery();
        lottery.InitBlock = 0;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.Operator = operator;
        vm.prank(lottery_manager_role);
        lottery_id = openlotto.CreateLottery(lottery);
    }

    function testResolveRound() 
        public
    {
        for (uint i ; i < 10 ; i++) {
            TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
            ticket.LotteryID = lottery_id;
            ticket.LotteryRoundInit = 1;
            ticket.LotteryRoundFini = 1;
            ticket.NumBets = 1;
            openlotto.BuyTicket{value: 1 ether}(ticket);
        }
        for (uint i ; i < 10 ; i++) {
            TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
            ticket.LotteryID = lottery_id;
            ticket.LotteryRoundInit = 2;
            ticket.LotteryRoundFini = 2;
            ticket.NumBets = 1;
            openlotto.BuyTicket{value: 1 ether}(ticket);
        }

        for (uint i ; i < 10 ; i++) {
            TicketModel.TicketItem memory ticket = TicketModel.newEmptyTicket();
            ticket.LotteryID = lottery_id;
            ticket.LotteryRoundInit = 2;
            ticket.LotteryRoundFini = 3;
            ticket.NumBets = 1;
            openlotto.BuyTicket{value: 2 ether}(ticket);
        }


        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(address(this), lottery.Operator.OPERATOR_CONTROLER_ROLE()));
        lottery.Operator.ResolveRound(lottery_id, lottery, 1, 0);

        vm.expectRevert(LotteryModel.InvalidRound.selector);
        openlotto.ResolveRound(lottery_id, 0);

        vm.expectRevert(LotteryOperatorInterface.OutOfResolutionRange.selector);
        openlotto.ResolveRound(lottery_id, 1);

        vm.expectRevert(LotteryModel.LotteryExpired.selector);
        openlotto.ResolveRound(lottery_id, 101);

        vm.roll(lottery.resolutionBlock(1) + 1);

        openlotto.ResolveRound(lottery_id, 1);

        vm.expectRevert(LotteryOperatorInterface.AlreadyResolved.selector);
        openlotto.ResolveRound(lottery_id, 1);
    }
}