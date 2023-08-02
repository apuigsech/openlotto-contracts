// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import "@src/database/LotteryDatabase.sol";

contract testLotteryDatabase is Test {
    LotteryDatabase database;

    function _newFilledLottery() internal pure returns (LotteryModel.LotteryItem memory lottery) {
        lottery.Name = "dummy";
        lottery.Rounds = 10;
        lottery.RoundBlocks = 100;
    }

    function setUp()
        public 
    {
        database = new LotteryDatabase();
        database.grantRole(database.CREATE_ROLE(), address(this));
        database.grantRole(database.READ_ROLE(), address(this));
        database.grantRole(database.UPDATE_ROLE(), address(this));
        database.grantRole(database.DELETE_ROLE(), address(this));
    }

    function testCreate() 
        public
    {
        LotteryModel.LotteryItem memory lottery;

        lottery = _newFilledLottery();
        lottery.Name = "";
        vm.expectRevert(LotteryModel.InvalidName.selector);
        database.Create(lottery);

        lottery = _newFilledLottery();
        lottery.Rounds = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        database.Create(lottery);

        lottery = _newFilledLottery();
        lottery.RoundBlocks = 0;
        vm.expectRevert(LotteryModel.InvalidRoundsConfiguration.selector);
        database.Create(lottery);

        lottery = _newFilledLottery();
        assertEq(database.Create(lottery), 1);
        assertEq(database.Create(lottery), 2);
        assertEq(database.Create(lottery), 3);
    }

    function testRead()
        public
    {
        LotteryModel.LotteryItem memory lottery;

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        lottery = database.Read(0);

        lottery = _newFilledLottery();
        lottery.Name = "one";
        uint32 id_1 = database.Create(lottery);
        lottery = _newFilledLottery();
        lottery.Name = "two";
        uint32 id_2 = database.Create(lottery);
        lottery = _newFilledLottery();
        lottery.Name = "three";
        uint32 id_3 = database.Create(lottery);

        lottery = database.Read(id_1);
        assertEq(lottery.Name, "one");
        lottery = database.Read(id_2);
        assertEq(lottery.Name, "two");
        lottery = database.Read(id_3);
        assertEq(lottery.Name, "three");
    }

    function testUpdate()
        public
    {
        LotteryModel.LotteryItem memory lottery;

        lottery = _newFilledLottery();
        lottery.Name = "zero";
        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        database.Update(0, lottery);

        lottery = _newFilledLottery();
        lottery.Name = "one";
        uint32 id_1 = database.Create(lottery);

        lottery = database.Read(id_1);
        assertEq(lottery.Name, "one");

        lottery = _newFilledLottery();
        lottery.Name = "one again";
        database.Update(id_1, lottery);

        lottery = database.Read(id_1);
        assertEq(lottery.Name, "one again");
    }

    function testDelete()
        public
    {
        LotteryModel.LotteryItem memory lottery;

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        database.Delete(0);

        lottery = _newFilledLottery();
        lottery.Name = "one";
        uint32 id_1 = database.Create(lottery);

        database.Delete(id_1);

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        database.Read(id_1);         

        vm.expectRevert(LotteryModelStorage.InvalidID.selector);
        database.Delete(id_1);
    }
}