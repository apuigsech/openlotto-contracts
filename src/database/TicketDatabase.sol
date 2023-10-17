// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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
}
