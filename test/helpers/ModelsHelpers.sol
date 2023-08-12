// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import { UD60x18, ud } from "@prb/math/UD60x18.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";
import "@src/operators/BaseLotteryOperator.sol";

contract DummyLotteryOperator is BaseLotteryOperator {
    bool public AuthorizationEnabled = false;

    function testEnableAuthorization() public {
        AuthorizationEnabled = true;
    }

    function _checkRole(bytes32 role, address account) internal view override {
        if (AuthorizationEnabled) {
            super._checkRole(role, account);
        }
    }
}

library ModelsHelpers {
    function newFilledLottery() internal returns (LotteryModel.LotteryItem memory lottery) {
        lottery.Name = "dummy";
        lottery.InitBlock = 1000;
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
        lottery.BetPrice = 1 ether;
        lottery.PrizePoolShare[0] = ud(1e18);
        lottery.Operator = new DummyLotteryOperator();
    }

    function newFilledTicket() internal pure returns (TicketModel.TicketItem memory ticket) {
        ticket.LotteryID = 0;
        ticket.LotteryRoundInit = 1;
        ticket.LotteryRoundFini = 1;
        ticket.NumBets = 1;
    }
}
