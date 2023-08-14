pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@src/utils/Deployments.sol";

contract DeployOpenLotto is Script {
    uint256 internal adminPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);
    uint256 internal lotteryManagerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 1);
    address internal lotteryManagerAddress = vm.addr(lotteryManagerPrivateKey);

    function run() public {
        uint256 adminPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 0);
        uint256 lotteryManagerPrivateKey = vm.deriveKey(vm.envString("MNEMONIC"), 1);
        address lotteryManagerAddress = vm.addr(lotteryManagerPrivateKey);

        vm.startBroadcast(adminPrivateKey);
        OpenLotto openlotto = Deployments.deployAll(lotteryManagerAddress);
        vm.stopBroadcast();
    }
}
