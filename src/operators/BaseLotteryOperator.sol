// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@models/LotteryModel.sol";

abstract contract BaseLotteryOperator is LotteryOperatorInterface {
    function _createLottery(uint32 id, LotteryModel.LotteryItem memory lottery) internal virtual override { }
    function _createTicket(uint32 id, TicketModel.TicketItem memory ticket) internal virtual override { }
    function _isValidTicket(
        LotteryModel.LotteryItem memory lottery,
        TicketModel.TicketItem memory ticket
    )
        internal
        pure
        virtual
        override
    { }

    function _ticketCombinations(TicketModel.TicketItem memory)
        internal
        pure
        virtual
        override
        returns (uint16)
    {
        return 1;
    }

    function _ticketPrizes(
        uint32 lottery_id,
        LotteryModel.LotteryItem memory lottery,
        uint32 ticket_id,
        TicketModel.TicketItem memory ticket,
        uint32 round
    )
        internal
        virtual
        override
        returns (uint32)
    { }

    function _lotteryWinnersCount(
        uint32 lottery_id,
        LotteryModel.LotteryItem memory lottery,
        uint32 round
    )
        internal
        virtual
        override
        returns (uint32[] memory)
    { }
}
