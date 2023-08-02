// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/access/AccessControl.sol";
import "openzeppelin/utils/structs/BitMaps.sol";

contract Database is AccessControl {
    using BitMaps for BitMaps.BitMap;

    string public name;

    bytes32 public constant CREATE_ROLE = keccak256("CREATE_ROLE");
    bytes32 public constant READ_ROLE = keccak256("READ_ROLE");
    bytes32 public constant UPDATE_ROLE = keccak256("UPDATE_ROLE");
    bytes32 public constant DELETE_ROLE = keccak256("DELETE_ROLE");

    uint32 private _currentID;
    BitMaps.BitMap private _mapIDs;

    error InvalidID(); 

    event CreatedItem(string name, uint32 indexed id, address indexed creator);
    event UpdatedItem(string name, uint32 indexed id, address indexed updater);
    event DeletedItem(string name, uint32 indexed id, address indexed deleter);

    constructor(string memory _name) {
        name = _name;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _newID() 
        private 
        returns(uint32) 
    {
        unchecked {
            _currentID++;
        }
        return(_currentID);
    }

    function _existsID(uint32 id) 
        internal view
    {
        if (_mapIDs.get(uint256(id)) != true) { revert InvalidID(); }
    } 

    function _create() 
        internal virtual
        onlyRole(CREATE_ROLE)
        returns(uint32 id)
    {
        id = _newID();
        _mapIDs.set(id);
        emit CreatedItem(name, id, msg.sender);
    }

    function _read(uint32 id) 
        internal view virtual
        onlyRole(READ_ROLE) existID(id)
        returns(uint32)
    {
        return id;
    }    

    function _update(uint32 id) 
        internal virtual
        onlyRole(UPDATE_ROLE) existID(id)
        returns(uint32)
    {
        emit UpdatedItem(name, id, msg.sender);
        return id;
    }

    function _delete(uint32 id) 
        internal virtual
        onlyRole(DELETE_ROLE) existID(id)
        returns(uint32)
    {
        _mapIDs.unset(id);
        emit DeletedItem(name, id, msg.sender);
        return id;
    }

    modifier existID(uint32 id) {
        _existsID(id);
        _;
    }
}

contract DatabaseEnumerable is Database {
    uint32[] private _listIDs;

    constructor(string memory _name) Database(_name) {
    }

    function _create() 
        internal override
        returns(uint32)
    {
        uint32 id = super._create();
        _listIDs.push(id);
        return id;
    }

    function _delete(uint32 _id) 
        internal override
        returns(uint32)
    {
        uint32 id = super._delete(_id);
        if (id != 0) {
            for (uint256 i = 0; i < _listIDs.length; i++) {
                if (_listIDs[i] == id) {
                    _listIDs[i] = _listIDs[_listIDs.length - 1];
                    _listIDs.pop();
                    break;
                }
            }
        }
        return id;
    }

    function _list() 
        internal view
        onlyRole(READ_ROLE)
        returns(uint32[] memory)
    {
        return _listIDs;
    }
}