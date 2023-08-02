// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "openzeppelin/access/IAccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

library RevertDataHelpers {
    function accessControlUnauthorizedAccount(address account, bytes32 role) 
        internal pure 
        returns(bytes memory) 
    {
        return abi.encodePacked(
            IAccessControl.AccessControlUnauthorizedAccount.selector,
            uint96(0),
            account,
            role
        );
    }
}