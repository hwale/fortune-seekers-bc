// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract ISeeker {
    function spawnNewSeeker(address minter, uint256 id) public virtual;

    function ownerOf(uint256 tokenId) public view virtual returns (address);
}
