pragma solidity ^0.8.22;

import "forge-std/Script.sol";
import "@src/utils/Deployments.sol";

contract DeployOpenLotto is Script {
    address internal lotteryManagerAddress = vm.envAddress("LOTTERY_MANAGER_ADDR");

    function run() public {
        vm.startBroadcast();
        OpenLotto openlotto = Deployments.deployAll();
        openlotto.grantRole(openlotto.LOTTERY_MANAGER_ROLE(), lotteryManagerAddress);
        vm.stopBroadcast();
    }
}