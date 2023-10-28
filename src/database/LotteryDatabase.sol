// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Database.sol";
import "@models/LotteryModel.sol";

/**
 * @title Lottery Database Contract
 * @dev Contract to store and manage lottery data.
 */
contract LotteryDatabase is DatabaseEnumerable {
    using LotteryModelStorage for LotteryModelStorage.LotteryStorage;

    LotteryModelStorage.LotteryStorage private data;

    constructor() DatabaseEnumerable("Lottery") { }

    /**
     * @dev Creates a new lottery.
     * @param lottery The data of the lottery to be created.
     * @return id The unique ID of the created lottery.
     */
    function Create(LotteryModel.LotteryItem calldata lottery) external returns (uint32 id) {
        id = _create();
        data.set(id, lottery);
    }

    /*
     * @dev Retrieves the data of a lottery.
     * @param id The ID of the lottery to be read.
     * @return lottery The data of the requested lottery.
     */
    function Read(uint32 id) external view returns (LotteryModel.LotteryItem memory lottery) {
        _read(id);
        lottery = data.get(id);
    }

    /**
     * @dev Updates the data of an existing lottery.
     * @param id The ID of the lottery to be updated.
     * @param lottery The updated data for the lottery.
     */
    function Update(uint32 id, LotteryModel.LotteryItem calldata lottery) external {
        _update(id);
        data.set(id, lottery);
    }

    /**
     * @dev Deletes an existing lottery.
     * @param id The ID of the lottery that has been deleted.
     */
    function Delete(uint32 id) external {
        _delete(id);
        data.unset(id);
    }

    bytes32 public constant STATE_ROLE = keccak256("STATE_ROLE");

    function GetReserve(uint32 id)
        external
        view
        returns (uint256 reserve)
    {
        reserve = data.LotteryStateMap[id].Reserve;
    }     

    function SetReserve(uint32 id, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].Reserve = amount;
    } 

    function IncReserve(uint32 id, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].Reserve += amount;
    }

    function DecReserve(uint32 id, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].Reserve -= amount;
    }

    function GetRoundJackpot(uint32 id, uint32 round)
        external
        view
        returns (uint256 jackpot)
    {
        jackpot = data.LotteryStateMap[id].RoundJackpot[round];
    }

    function SetRoundJackpot(uint32 id, uint32 round, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].RoundJackpot[round] = amount;
    } 

    function IncRoundJackpot(uint32 id, uint32 round, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].RoundJackpot[round] += amount;
    }

    function DecRoundJackpot(uint32 id, uint32 round, uint256 amount) external onlyRole(STATE_ROLE) {
        data.LotteryStateMap[id].RoundJackpot[round] -= amount;
    }
}