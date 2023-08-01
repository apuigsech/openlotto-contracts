// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@models/LotteryModel.sol";

contract wrapLotteryModel {
    using LotteryModel for LotteryModel.LotteryItem;

    function isValid(LotteryModel.LotteryItem memory lottery)
        public pure
    {
        lottery.isValid();
    }
}

contract testLotteryModel is Test {
    using LotteryModel for LotteryModel.LotteryItem;

    LotteryModel.LotteryItem lottery_storage;

    function _newFilledLottery()
        internal pure
        returns(LotteryModel.LotteryItem memory lottery)
    {
        lottery.Name = "dummy";
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
    }

    function testItemStorageGas() 
        public
    {
        vm.pauseGasMetering();
        LotteryModel.LotteryItem memory lottery = _newFilledLottery();
        vm.resumeGasMetering();

        lottery_storage = lottery;
    }

    function testIsValid()
        public
    {
        wrapLotteryModel wrap = new wrapLotteryModel();

        LotteryModel.LotteryItem memory lottery;

        lottery = _newFilledLottery();
        lottery.Name = "";
        vm.expectRevert(LotteryModel.InvalidName.selector);
        wrap.isValid(lottery);

        lottery = _newFilledLottery();
        lottery.Rounds = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        wrap.isValid(lottery);

        lottery = _newFilledLottery();
        lottery.RoundBlocks = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        wrap.isValid(lottery);

        lottery = _newFilledLottery();
        wrap.isValid(lottery);
    }  
}