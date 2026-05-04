// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "forge-std/Test.sol";

import "@openzeppelin/utils/Strings.sol";
import "@openzeppelin/access/IAccessControl.sol";

import "@models/LotteryModel.sol";
import "@models/TicketModel.sol";

library RevertDataHelpers {
    /// @dev Replicates the `Error(string)` revert emitted by OpenZeppelin v4.x AccessControl when an account lacks a
    /// role. Format: "AccessControl: account 0x... is missing role 0x..."
    function accessControlUnauthorizedAccount(address account, bytes32 role) internal pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "Error(string)",
            string(
                abi.encodePacked(
                    "AccessControl: account ",
                    Strings.toHexString(account),
                    " is missing role ",
                    Strings.toHexString(uint256(role), 32)
                )
            )
        );
    }
}
