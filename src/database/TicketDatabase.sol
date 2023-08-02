// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Database.sol";
import "@models/TicketModel.sol";

contract TicketDatabase is Database {
    using TicketModelStorage for TicketModelStorage.TicketStorage;

    TicketModelStorage.TicketStorage data;

    constructor() Database("Ticket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function Create(TicketModel.TicketItem calldata ticket) 
        external
        returns(uint32 id)
    {
        id = _create();
        data.set(id, ticket);
    }

    function Read(uint32 id) 
        external view
        returns(TicketModel.TicketItem memory ticket)
    {
        _read(id);
        ticket = data.get(id);
    }
}