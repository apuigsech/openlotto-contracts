// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library TicketModel {
    error InvalidRounds();

    struct TicketItem{
        uint32 LotteryID;                   // Reference identifier of the lottery associated with the ticket.
        uint32 LotteryRoundInit;            // Starting round of the lottery for which the ticket is playing.
        uint32 LotteryRoundFini;            // Ending round of the lottery for which the ticket is playing.
    }

    function isValid(TicketModel.TicketItem memory ticket) 
        internal pure
    {
        if (ticket.LotteryRoundInit == 0 || ticket.LotteryRoundFini < ticket.LotteryRoundInit ) { revert InvalidRounds(); }
    }

    function newEmptyTicket()
        internal pure
        returns(TicketModel.TicketItem memory ticket)
    {
        ticket.LotteryID = 0;
        ticket.LotteryRoundInit = 0;
        ticket.LotteryRoundFini = 0;
    }

}