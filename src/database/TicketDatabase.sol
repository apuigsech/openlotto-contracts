// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "./Database.sol";
import "@models/TicketModel.sol";

/**
 * @title Ticket Database Contract
 * @dev Contract to store and manage ticket data.
 */
contract TicketDatabase is Database {
    using TicketModelStorage for TicketModelStorage.TicketStorage;

    TicketModelStorage.TicketStorage private data;

    constructor() Database("Ticket") { }

    /**
     * @dev Creates a new ticket.
     * @param ticket The data of the ticket to be created.
     * @return id The unique ID of the created ticket.
     */
    function Create(TicketModel.TicketItem calldata ticket) external returns (uint32 id) {
        id = _create();
        data.set(id, ticket);
    }

    /**
     * @dev Retrieves the data of a ticket.
     * @param id The ID of the ticket to be read.
     * @return ticket The data of the requested ticket.
     */
    function Read(uint32 id) external view returns (TicketModel.TicketItem memory ticket) {
        _read(id);
        ticket = data.get(id);
    }

    bytes32 public constant STATE_ROLE = keccak256("STATE_ROLE");

    function GetRoundFlags(uint32 id, uint32 round)
        external
        view
        returns (uint8 flags)
    {
        flags = data.TicketStateMap[id].RoundFlags[round];
    }   

    function HasRoundFlags(uint32 id, uint32 round, uint8 flags) external returns(bool) {
        return (data.TicketStateMap[id].RoundFlags[round] & flags) == flags;
    }   

    function SetRoundFlags(uint32 id, uint32 round, uint8 flags, bool fullSet) external onlyRole(STATE_ROLE) {
        if (fullSet) {
            data.TicketStateMap[id].RoundFlags[round] = flags;
        } else {
            data.TicketStateMap[id].RoundFlags[round] |= flags;
        }
    }
}
