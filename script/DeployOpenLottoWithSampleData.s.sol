pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "@src/utils/Deployments.sol";
import "@src/operators/BaseLotteryOperator.sol";

import "@src/OpenLotto.sol";
import "@src/models/LotteryModel.sol";

contract DummyLotteryOperator is BaseLotteryOperator {
}


contract DeployOpenLotto is Script {
    uint256 internal adminPrivateKey = vm.deriveKey(vm.envString("OPENLOTTO_MNEMONIC"), 0);
    uint256 internal lotteryManagerPrivateKey = vm.deriveKey(vm.envString("OPENLOTTO_MNEMONIC"), 1);
    uint256 internal numLotteries = vm.envUint("OPENLOTTO_NUM_LOTTERIES");
    address internal lotteryManagerAddress = vm.addr(lotteryManagerPrivateKey);

    function run() public {
        vm.startBroadcast(adminPrivateKey);
        OpenLotto openlotto = Deployments.deployAll(lotteryManagerAddress);
        vm.stopBroadcast();

        vm.startBroadcast(lotteryManagerPrivateKey);
        DummyLotteryOperator dummyLotteryOperator = new DummyLotteryOperator();
        dummyLotteryOperator.grantRole(dummyLotteryOperator.OPERATOR_CONTROLER_ROLE(), address(openlotto));

        for (uint i = 0 ; i < numLotteries ; i++) {
            LotteryModel.LotteryItem memory lottery;
            lottery.Name = "dummy";
            lottery.InitBlock = block.number + 100;
            lottery.Rounds = 10;
            lottery.RoundBlocks = 100;
            lottery.BetPrice = 1 ether;
            lottery.PrizePoolShare[0] = ud(1e18);
            lottery.Operator = dummyLotteryOperator;
            openlotto.CreateLottery(lottery);
        }

        vm.stopBroadcast();
    }
}