// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {UD60x18, ud} from "@prb/math/UD60x18.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

contract DummyLotteryOperator is LotteryOperatorInterface {
    function CreateLottery(uint32 id, LotteryModel.LotteryItem memory lottery) override public {}
    function CreateTicket(uint32 id, TicketModel.TicketItem memory ticket) override public {}
    function isValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) override public pure {}
}

library ModelsHelpers {
    function newFilledLottery()
        internal 
        returns (LotteryModel.LotteryItem memory lottery)
    {
        lottery.Name = "dummy";
        lottery.InitBlock = 1000;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.Operator = new DummyLotteryOperator();
    }

    function newFilledTicket()
        internal pure
        returns(TicketModel.TicketItem memory ticket)
    {
        ticket.LotteryID = 0;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
    }
}