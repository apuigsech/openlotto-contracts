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

library TicketModelStorage {
    using TicketModel for TicketModel.TicketItem;

    error InvalidID();

    struct TicketStorage {
        mapping (uint32 => TicketModel.TicketItem) TicketMap;
    }

    function set(TicketStorage storage data, uint32 id, TicketModel.TicketItem calldata ticket)
        internal
        isValid(ticket)
    {
        data.TicketMap[id] = ticket;        
    }

    function unset(TicketStorage storage data, uint32 id)
        internal
    {
        delete data.TicketMap[id];
    }

    function get(TicketStorage storage data, uint32 id)
        internal view
        exist(data, id)
        returns (TicketModel.TicketItem storage ticket)
    {
        ticket = data.TicketMap[id];

    }

    modifier exist(TicketStorage storage data, uint32 id) {
        if (data.TicketMap[id].LotteryRoundInit == 0) { revert InvalidID(); }
        _;
    }

    modifier isValid(TicketModel.TicketItem calldata ticket) {
        TicketModel.isValid(ticket);
        _;
    }
}