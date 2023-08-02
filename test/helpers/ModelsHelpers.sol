// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

library ModelsHelpers {
    function newFilledLottery()
        internal pure 
        returns (LotteryModel.LotteryItem memory lottery)
    {
        lottery.Name = "dummy";
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
    }

    function newFilledTicket()
        internal pure
        returns(TicketModel.TicketItem memory ticket)
    {
        ticket.LotteryID = 1;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
    }
}