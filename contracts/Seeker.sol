//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interface/IFortuneController.sol";
import "hardhat/console.sol";

contract Seeker is ERC721Pausable, Ownable {
    address FORTUNE_CONTRACT_ADDRESS;
    IFortuneController FORTUNE_CONTROLLER;
    string BASE_URI;

    constructor() ERC721("Fortune Seekers", "SEEK") {}

    function spawnNewSeeker(address minter, uint256 id)
        public
        onlyFortuneController
    {
        _safeMint(minter, id);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._afterTokenTransfer(from, to, tokenId);
        FORTUNE_CONTROLLER.afterTokenTransfer(from, to, tokenId);
    }

    function setFortuneContract(address contractAddress) external onlyOwner {
        FORTUNE_CONTRACT_ADDRESS = contractAddress;
        FORTUNE_CONTROLLER = IFortuneController(FORTUNE_CONTRACT_ADDRESS);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        BASE_URI = uri;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }

    function pauseSpawning() external onlyOwner {
        _pause();
    }

    function unpauseSpawning() external onlyOwner {
        _unpause();
    }

    modifier onlyFortuneController() {
        require(
            msg.sender == FORTUNE_CONTRACT_ADDRESS,
            "Can only be called by Fortune Controller"
        );
        _;
    }
}
