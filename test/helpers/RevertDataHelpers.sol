// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/access/IAccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

library RevertDataHelpers {
    function accessControlUnauthorizedAccount(address account, bytes32 role) internal pure returns (bytes memory) {
        return bytes(
            abi.encodePacked(
                bytes16(IAccessControl.AccessControlUnauthorizedAccount.selector),
                account,
                role
            )
        );
    }
}
