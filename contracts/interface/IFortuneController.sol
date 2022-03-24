// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract IFortuneController {
    function afterTokenTransfer(
        address from,
        address to,
        uint256 characterId
    ) external virtual;
}
