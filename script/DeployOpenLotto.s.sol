pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@src/utils/Deployments.sol";

contract DeployOpenLotto is Script {
    uint256 internal adminPrivateKey = vm.deriveKey(vm.envString("OPENLOTTO_MNEMONIC"), 0);
    uint256 internal lotteryManagerPrivateKey = vm.deriveKey(vm.envString("OPENLOTTO_MNEMONIC"), 1);
    address internal lotteryManagerAddress = vm.addr(lotteryManagerPrivateKey);

    function run() public {
        vm.startBroadcast(adminPrivateKey);
        OpenLotto openlotto = Deployments.deployAll(lotteryManagerAddress);
        vm.stopBroadcast();
    }
}