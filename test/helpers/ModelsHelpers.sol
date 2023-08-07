// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {UD60x18, ud} from "@prb/math/UD60x18.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

contract DummyLotteryOperator is LotteryOperatorInterface {
    bool public AuthorizationEnabled = false;

    function _createLottery(uint32, LotteryModel.LotteryItem memory) override internal {}
    function _createTicket(uint32, TicketModel.TicketItem memory) override internal {}
    function _isValidTicket(LotteryModel.LotteryItem memory, TicketModel.TicketItem memory) override internal pure {}
    function _ticketCombinations(TicketModel.TicketItem memory) override internal pure returns(uint16) { return 1; }
    function _ticketPrizes(uint32, LotteryModel.LotteryItem memory, uint32, TicketModel.TicketItem memory, uint32) override internal pure returns(uint32) { return 0; }  
    function _resolveRound(uint32, LotteryModel.LotteryItem memory, uint32, uint256) override internal returns(bool) { return true; }

    function testEnableAuthorization() public {
        AuthorizationEnabled = true;
    }

    function _checkRole(bytes32 role, address account) override internal view {
        if (AuthorizationEnabled) {
            super._checkRole(role, account);
        }
    }
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
        ticket.NumBets = 1;
    }
}