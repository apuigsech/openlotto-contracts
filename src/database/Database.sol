// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/access/AccessControl.sol";
import "@openzeppelin/utils/structs/BitMaps.sol";


/**
 * @title CRUD Database Contract
 * @dev Manages a database with access control and CRUD (Create, Read, Update, Delete) capabilities for items.
 */
contract Database is AccessControl {
    using BitMaps for BitMaps.BitMap;

    // Name of the database.
    string public name;

    // Role identifiers for access control
    bytes32 public constant CREATE_ROLE = keccak256("CREATE_ROLE");
    bytes32 public constant READ_ROLE = keccak256("READ_ROLE");
    bytes32 public constant UPDATE_ROLE = keccak256("UPDATE_ROLE");
    bytes32 public constant DELETE_ROLE = keccak256("DELETE_ROLE");

    // Private variables for tracking item IDs and existence mapping
    uint32 private _currentID;
    BitMaps.BitMap private _mapIDs;

    error InvalidID(); 

    // Events emitted upon item creation, update, and deletion
    event CreatedItem(string name, uint32 indexed id, address indexed creator);
    event UpdatedItem(string name, uint32 indexed id, address indexed updater);
    event DeletedItem(string name, uint32 indexed id, address indexed deleter);


    /**
     * @dev Constructor to initialize the database with a name.
     * @param _name The name of the database.
     */
    constructor(string memory _name) {
        name = _name;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @dev Generates a new unique item ID.
     * @return id The newly generated item ID.
     */
    function _newID() 
        private 
        returns(uint32 id) 
    {
        unchecked {id = ++_currentID; }
    }

    /**
     * @dev Checks if an item with a given ID exists.
     * @param id The ID of the item to check.
     */
    function _existsID(uint32 id) 
        internal view
    {
        if (_mapIDs.get(uint256(id)) != true) { revert InvalidID(); }
    } 

    /**
     * @dev Creates a new item.
     * @return id The ID of the newly created item.
     */
    function _create() 
        internal virtual
        onlyRole(CREATE_ROLE)
        returns(uint32 id)
    {
        id = _newID();
        _mapIDs.set(id);
        emit CreatedItem(name, id, msg.sender);
    }

    /**
     * @dev Reads an item by its ID and returns the ID.
     * @param _id The ID of the item to read.
     * @return id The ID of the read item.
     */
    function _read(uint32 _id) 
        internal view virtual
        onlyRole(READ_ROLE) existID(_id)
        returns(uint32 id)
    {
        id = _id;
    }

    /**
     * @dev Updates an item.
     * @param _id The ID of the item to update.
     * @return id The ID of the updated item.
     */
    function _update(uint32 _id) 
        internal virtual
        onlyRole(UPDATE_ROLE) existID(_id)
        returns(uint32 id)
    {
        id = _id;
        emit UpdatedItem(name, id, msg.sender);
    }

    /**
     * @dev Deletes an item.
     * @param _id The ID of the item to delete.
     * @return id The ID of the deleted item.
     */
    function _delete(uint32 _id) 
        internal virtual
        onlyRole(DELETE_ROLE) existID(_id)
        returns(uint32 id)
    {
        _mapIDs.unset(_id);
        id = _id;
        emit DeletedItem(name, id, msg.sender);
    }

    /*
     * @dev Modifier to check the existence of an item ID.
     * @param id The ID of the item to check.
     */
    modifier existID(uint32 id) {
        _existsID(id);
        _;
    }
}

/**
 * @title DatabaseEnumerable Contract
 * @dev Extends the Database contract and adds enumeration functionality to list item IDs.
 */
contract DatabaseEnumerable is Database {
    uint32[] private _listIDs;


    /**
     * @dev Constructor to initialize the contract with a name.
     * @param _name The name of the database.
     */
    constructor(string memory _name) Database(_name) {
    }

    /**
     * @dev Creates a new item.
     * @return id The ID of the newly created item.
     */
    function _create() 
        internal override
        returns(uint32 id)
    {
        id = super._create();
        _listIDs.push(id);
    }

    /**
     * @dev Deletes an item.
     * @param _id The ID of the item to delete.
     * @return id The ID of the deleted item.
     */
    function _delete(uint32 _id) 
        internal override
        returns(uint32 id)
    {
        id = super._delete(_id);
        if (id != 0) {
            for (uint256 i = 0; i < _listIDs.length; i++) {
                if (_listIDs[i] == id) {
                    _listIDs[i] = _listIDs[_listIDs.length - 1];
                    _listIDs.pop();
                    break;
                }
            }
        }
    }

    /**
     * @dev Lists all item IDs.
     * @return array An array containing all item IDs.
     */
    function _list() 
        internal view
        onlyRole(READ_ROLE)
        returns(uint32[] memory)
    {
        return _listIDs;
    }
}