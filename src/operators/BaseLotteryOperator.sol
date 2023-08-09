// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@models/LotteryModel.sol";

abstract contract BaseLotteryOperator is LotteryOperatorInterface {
    function _createLottery(uint32 id, LotteryModel.LotteryItem memory lottery) override virtual internal {}
    function _createTicket(uint32 id, TicketModel.TicketItem memory ticket) override virtual internal {}
    function _isValidTicket(LotteryModel.LotteryItem memory lottery, TicketModel.TicketItem memory ticket) override virtual internal pure {}
    function _ticketCombinations(TicketModel.TicketItem memory ticket) override virtual internal pure returns(uint16) { return 1; }
    function _ticketPrizes(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 ticket_id, TicketModel.TicketItem memory ticket, uint32 round) override virtual internal returns(uint32) {}
    function _lotteryWinnersCount(uint32 lottery_id, LotteryModel.LotteryItem memory lottery, uint32 round) override virtual internal returns(uint32[] memory) {}
}