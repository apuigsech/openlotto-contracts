// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "@test/helpers/RevertDataHelpers.sol";

import "@src/database/Database.sol";

contract DatabaseWrap is Database {
    constructor(string memory name) Database(name) { }

    function wrap_create() public returns (uint32) {
        return _create();
    }

    function wrap_read(uint32 _id) public view returns (uint32) {
        return _read(_id);
    }

    function wrap_update(uint32 _id) public returns (uint32) {
        return _update(_id);
    }

    function wrap_delete(uint32 _id) public returns (uint32) {
        return _delete(_id);
    }
}

contract DatabaseEnumerableWrap is DatabaseEnumerable {
    constructor(string memory name) DatabaseEnumerable(name) { }

    function wrap_create() public returns (uint32) {
        return _create();
    }

    function wrap_read(uint32 _id) public view returns (uint32) {
        return _read(_id);
    }

    function wrap_update(uint32 _id) public returns (uint32) {
        return _update(_id);
    }

    function wrap_delete(uint32 _id) public returns (uint32) {
        return _delete(_id);
    }

    function wrap_list() public view returns (uint32[] memory) {
        return _list();
    }
}

contract DatabaseTest is Test {
    DatabaseWrap public database;

    address admin_role = makeAddr("admin_role");

    address create_role = makeAddr("create_role");
    address read_role = makeAddr("read_role");
    address update_role = makeAddr("update_role");
    address delete_role = makeAddr("delete_role");

    address regular_role = makeAddr("regular_role");

    function setUp() public {
        database = new DatabaseWrap("Item");
        database.grantRole(database.CREATE_ROLE(), create_role);
        database.grantRole(database.READ_ROLE(), read_role);
        database.grantRole(database.UPDATE_ROLE(), update_role);
        database.grantRole(database.DELETE_ROLE(), delete_role);
    }

    function testAuthorization() public {
        // Test CREATE_ROLE authorization
        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(regular_role, database.CREATE_ROLE()));
        vm.prank(regular_role);
        database.wrap_create();

        vm.prank(create_role);
        uint32 id = database.wrap_create();

        // Test READ_ROLE authorization
        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(regular_role, database.READ_ROLE()));
        vm.prank(regular_role);
        database.wrap_read(id);

        vm.prank(read_role);
        database.wrap_read(id);

        // Test UPDATE_ROLE authorization
        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(regular_role, database.UPDATE_ROLE()));
        vm.prank(regular_role);
        database.wrap_update(id);

        vm.prank(update_role);
        database.wrap_update(id);

        // Test DELETE_ROLE authorization
        vm.expectRevert(RevertDataHelpers.accessControlUnauthorizedAccount(regular_role, database.DELETE_ROLE()));
        vm.prank(regular_role);
        database.wrap_delete(id);

        vm.prank(delete_role);
        database.wrap_delete(id);
    }

    function testCreate() public {
        vm.startPrank(create_role);
        assertEq(database.wrap_create(), 1);
        assertEq(database.wrap_create(), 2);
        assertEq(database.wrap_create(), 3);
        vm.stopPrank();
    }

    function testRead() public {
        vm.prank(create_role);
        uint32 id = database.wrap_create();

        vm.startPrank(read_role);
        database.wrap_read(id);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_read(id - 1);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_read(id + 1);
        vm.stopPrank();
    }

    function testUpdate() public {
        vm.prank(create_role);
        uint32 id = database.wrap_create();

        vm.startPrank(update_role);
        assertEq(database.wrap_update(id), id);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_update(id - 1);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_update(id + 1);
        vm.stopPrank();
    }

    function testDelete() public {
        vm.prank(create_role);
        uint32 id = database.wrap_create();

        vm.startPrank(delete_role);
        assertEq(database.wrap_delete(id), id);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_delete(id - 1);
        vm.expectRevert(Database.InvalidID.selector);
        database.wrap_delete(id + 1);
        vm.stopPrank();
    }
}

contract DatabaseEnumerableTest is Test {
    DatabaseEnumerableWrap public database;

    address admin_role = makeAddr("admin_role");

    address create_role = makeAddr("create_role");
    address read_role = makeAddr("read_role");
    address update_role = makeAddr("update_role");
    address delete_role = makeAddr("delete_role");

    address regular_role = makeAddr("regular_role");

    function setUp() public {
        database = new DatabaseEnumerableWrap("Item");
        database.grantRole(database.CREATE_ROLE(), create_role);
        database.grantRole(database.READ_ROLE(), read_role);
        database.grantRole(database.UPDATE_ROLE(), update_role);
        database.grantRole(database.DELETE_ROLE(), delete_role);
    }

    function testList() public {
        uint32[] memory ids;

        vm.startPrank(create_role);
        assertEq(database.wrap_create(), 1);
        assertEq(database.wrap_create(), 2);
        assertEq(database.wrap_create(), 3);
        assertEq(database.wrap_create(), 4);
        assertEq(database.wrap_create(), 5);
        vm.stopPrank();

        vm.prank(delete_role);
        database.wrap_delete(2);

        vm.prank(read_role);
        ids = database.wrap_list();
        assertEq(ids.length, 4);
        assertEq(ids[0], 1);
        assertEq(ids[1], 5);
        assertEq(ids[2], 3);
        assertEq(ids[3], 4);

        vm.prank(delete_role);
        database.wrap_delete(1);

        vm.prank(read_role);
        ids = database.wrap_list();
        assertEq(ids.length, 3);
        assertEq(ids[0], 4);
        assertEq(ids[1], 5);
        assertEq(ids[2], 3);
    }
}
