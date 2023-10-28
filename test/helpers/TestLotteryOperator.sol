// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

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