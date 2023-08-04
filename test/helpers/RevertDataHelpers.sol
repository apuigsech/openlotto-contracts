// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@openzeppelin/utils/Strings.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

library RevertDataHelpers {
    function accessControlUnauthorizedAccount(address account, bytes32 role) 
        internal pure 
        returns(bytes memory) 
    {
        return bytes(
            abi.encodePacked(
                "AccessControl: account ",
                Strings.toHexString(account),
                " is missing role ",
                Strings.toHexString(uint256(role), 32)
            )
        );
    }
}