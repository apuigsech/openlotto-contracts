// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Database.sol";
import "@models/LotteryModel.sol";

contract LotteryDatabase is DatabaseEnumerable {
    using LotteryModelStorage for LotteryModelStorage.LotteryStorage;

    LotteryModelStorage.LotteryStorage data;

    constructor() DatabaseEnumerable("Lottery") {}

    function Create(LotteryModel.LotteryItem calldata lottery)
        external
        returns(uint32 id)
    {
        id = _create();
        data.set(id, lottery);
    }

    function Read(uint32 id) 
        external view
        returns(LotteryModel.LotteryItem memory lottery)
    {
        _read(id);
        lottery = data.get(id);
    }

    function Update(uint32 id, LotteryModel.LotteryItem calldata lottery)
        external
    {
        _update(id);
        data.set(id, lottery);
    }

    function Delete(uint32 id)
        external
    {
        _delete(id);
        data.unset(id);
    }
}