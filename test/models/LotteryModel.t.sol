// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@test/helpers/ModelsHelpers.sol";

import "@models/LotteryModel.sol";

contract wrapLotteryModel {
    using LotteryModel for LotteryModel.LotteryItem;

    function isValid(LotteryModel.LotteryItem memory lottery)
        public pure
    {
        lottery.isValid();
    }
}

contract wrapLotteryModelStorage {
    using LotteryModelStorage for LotteryModelStorage.LotteryStorage;

    LotteryModelStorage.LotteryStorage data;

    function set(uint32 id, LotteryModel.LotteryItem calldata lottery)
        public
    {
        data.set(id, lottery);        
    }

    function unset(uint32 id)
        public
    {
        data.unset(id);
    }

    function get(uint32 id)
        public view
        returns (LotteryModel.LotteryItem memory lottery)
    {
        lottery = data.get(id);
    }    
}


contract testLotteryModel is Test {
    using LotteryModel for LotteryModel.LotteryItem;

    LotteryModel.LotteryItem lottery_storage;

    function testItemStorageGas() 
        public
    {
        vm.pauseGasMetering();
        LotteryModel.LotteryItem memory lottery = ModelsHelpers.newFilledLottery();
        vm.resumeGasMetering();

        lottery_storage = lottery;
    }

    function testIsValid()
        public
    {
        wrapLotteryModel wrap = new wrapLotteryModel();

        LotteryModel.LotteryItem memory lottery;

        lottery = ModelsHelpers.newFilledLottery();
        lottery.Name = "";
        vm.expectRevert(LotteryModel.InvalidName.selector);
        wrap.isValid(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.Rounds = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        wrap.isValid(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.RoundBlocks = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        wrap.isValid(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.DistributionPoolShare[0] = ud(0.25e18);
        lottery.DistributionPoolShare[1] = ud(0.25e18);
        lottery.DistributionPoolShare[2] = ud(0.25e18);
        lottery.DistributionPoolShare[3] = ud(0.25e18);
        lottery.DistributionPoolShare[4] = ud(0.25e18);
        vm.expectRevert(LotteryModel.InvalidDistributionPool.selector);
        wrap.isValid(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        lottery.PrizePoolShare[0] = ud(0.25e18);
        lottery.PrizePoolShare[1] = ud(0.25e18);
        lottery.PrizePoolShare[2] = ud(0.25e18);
        lottery.PrizePoolShare[3] = ud(0.25e18);
        lottery.PrizePoolShare[4] = ud(0.25e18);
        vm.expectRevert(LotteryModel.InvalidPrizePool.selector);
        wrap.isValid(lottery);

        lottery = ModelsHelpers.newFilledLottery();
        wrap.isValid(lottery);
    }  
}

contract testLotteryModelStorage is Test {
    function testSet()
        public
    {
        wrapLotteryModelStorage wrap = new wrapLotteryModelStorage(); 

        LotteryModel.LotteryItem memory lottery;

        lottery = ModelsHelpers.newFilledLottery(); 
        wrap.set(1, lottery);
        wrap.get(1);
    }

    function testUnset()
        public
    {
        wrapLotteryModelStorage wrap = new wrapLotteryModelStorage(); 

        LotteryModel.LotteryItem memory lottery;

        lottery = ModelsHelpers.newFilledLottery(); 
        wrap.set(1, lottery);
        wrap.get(1);

        wrap.unset(1);

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        wrap.get(1);
    }

    function testGet()
        public
    {
        wrapLotteryModelStorage wrap = new wrapLotteryModelStorage(); 

        LotteryModel.LotteryItem memory lottery;

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        wrap.get(1);

        lottery = ModelsHelpers.newFilledLottery(); 
        lottery.Name = "one";
        wrap.set(1, lottery);
        lottery = ModelsHelpers.newFilledLottery(); 
        lottery.Name = "two";
        wrap.set(2, lottery);
        lottery = ModelsHelpers.newFilledLottery(); 
        lottery.Name = "three";
        wrap.set(3, lottery);

        lottery = wrap.get(1);
        assertEq(lottery.Name, "one");
        lottery = wrap.get(2);
        assertEq(lottery.Name, "two");
        lottery = wrap.get(3);
        assertEq(lottery.Name, "three");     
    }
}