// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@src/OpenLotto.sol";

library Deployments {
    function deployDatabases() internal returns (LotteryDatabase lottery_db, TicketDatabase ticket_db) {
        lottery_db = new LotteryDatabase();
        ticket_db = new TicketDatabase();
    }

    function deployOpenLotto(
        LotteryDatabase lottery_db,
        TicketDatabase ticket_db
    )
        internal
        returns (OpenLotto openlotto)
    {
        openlotto = new OpenLotto(lottery_db, ticket_db);

        lottery_db.grantRole(lottery_db.CREATE_ROLE(), address(openlotto));
        lottery_db.grantRole(lottery_db.READ_ROLE(), address(openlotto));
        lottery_db.grantRole(lottery_db.STATE_ROLE(), address(openlotto));

        ticket_db.grantRole(ticket_db.CREATE_ROLE(), address(openlotto));
        ticket_db.grantRole(ticket_db.READ_ROLE(), address(openlotto));
        ticket_db.grantRole(lottery_db.STATE_ROLE(), address(openlotto));

        //openlotto.grantRole(openlotto.LOTTERY_MANAGER_ROLE(), lottery_manager_role);
    }

    function deployAll() internal returns (OpenLotto openlotto) {
        (LotteryDatabase lottery_db, TicketDatabase ticket_db) = deployDatabases();
        openlotto = deployOpenLotto(lottery_db, ticket_db);
    }

    function deployAllWithLotteryManager(address lottery_manager_address) internal returns (OpenLotto openlotto) {
        openlotto = deployAll();
        openlotto.grantRole(openlotto.LOTTERY_MANAGER_ROLE(), lottery_manager_address);
    }

}
