// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;


/// @title Library containing the data model and functions related to the TicketItem struct.
library TicketModel {
    // Custom errors used for validation.
    /// @dev Error thrown when the ticket's round configuration is invalid (round initialization is zero or ending round
    /// is less than the starting round).
    error InvalidRounds();

    /// @dev Data structure representing a lottery ticket.
    struct TicketItem {
        uint32 LotteryID; // Reference identifier of the lottery associated with the ticket.
        uint32 LotteryRoundInit; // Starting round of the lottery for which the ticket is playing.
        uint32 LotteryRoundFini; // Ending round of the lottery for which the ticket is playing.
        uint8 NumBets; // Number of bets the ticket is processing (typically 1). The ticket cost and prize are affected by this value.
        bytes8 Attributes;
    }

    uint8 constant public FLAG_NONE = 0;
    uint8 constant public FLAG_CLAIMED = 1;
    uint8 constant public FLAG_WITHDRAWN = 2;

    struct TicketState {
        mapping(uint32 => uint8) RoundFlags;
    }

    /// @dev Function to validate whether a ticket item is valid (has valid round configuration).
    function isValid(TicketModel.TicketItem memory ticket) internal pure {
        if (ticket.LotteryRoundInit == 0 || ticket.LotteryRoundFini < ticket.LotteryRoundInit) revert InvalidRounds();
    }

    /// @dev Function to create an empty TicketItem.
    function newEmptyTicket() internal pure returns (TicketModel.TicketItem memory ticket) {
        ticket.LotteryID = 0;
        ticket.LotteryRoundInit = 0;
        ticket.LotteryRoundFini = 0;
        ticket.NumBets = 0;
        ticket.Attributes = 0;
    }
}

/// @title Library containing functions to manage the storage of TicketItems.
library TicketModelStorage {
    using TicketModel for TicketModel.TicketItem;

    // Custom error used when an invalid ID is encountered.
    /// @dev Error thrown when an invalid ticket ID is encountered.
    error InvalidItem();

    /// @dev Data structure to store multiple ticket items.
    struct TicketStorage {
        mapping(uint32 => TicketModel.TicketItem) TicketMap;
        mapping(uint32 => TicketModel.TicketState) TicketStateMap;
    }

    /// @dev Function to set (update/create) a ticket item in the storage.
    function set(
        TicketStorage storage data,
        uint32 id,
        TicketModel.TicketItem calldata ticket
    )
        internal
        isValid(ticket)
    {
        data.TicketMap[id] = ticket;
    }

    /// @dev Function to unset (delete) a ticket item from the storage.
    function unset(TicketStorage storage data, uint32 id) internal {
        delete data.TicketMap[id];
    }

    /// @dev Function to get a specific ticket item from the storage by its ID.
    function get(
        TicketStorage storage data,
        uint32 id
    )
        internal
        view
        valid_item(data, id)
        returns (TicketModel.TicketItem storage ticket)
    {
        ticket = data.TicketMap[id];
    }

    /// @dev Modifier to check if a ticket item with a given ID exists in the storage.
    modifier valid_item(TicketStorage storage data, uint32 id) {
        if (data.TicketMap[id].LotteryRoundInit == 0) revert InvalidItem();
        _;
    }

    /// @dev Modifier to check if a TicketItem is valid.
    modifier isValid(TicketModel.TicketItem calldata ticket) {
        TicketModel.isValid(ticket);
        _;
    }
}

