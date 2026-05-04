// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import "@src/operators/BaseLotteryOperator.sol";


contract TestLotteryOperator is BaseLotteryOperator {

    bool public AuthorizationEnabled = false;

    function testEnableAuthorization() public {
        AuthorizationEnabled = true;
    }

    function _checkRole(bytes32 role, address account) internal view override {
        if (AuthorizationEnabled) {
            super._checkRole(role, account);
        }
    }

    /// @dev When authorization is disabled, pretend every role is granted. Lets OpenLotto's `hasRole` precheck pass
    /// without each test having to explicitly grant OPERATOR_CONTROLER_ROLE.
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        if (!AuthorizationEnabled) return true;
        return super.hasRole(role, account);
    }


    // ticket_id => round => prizes
    mapping(uint32 => mapping(uint32 => uint32)) TicketPrizesTestData;

    mapping(uint32 => uint32[]) WinnersCountTestData;

    constructor() BaseLotteryOperator() {
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