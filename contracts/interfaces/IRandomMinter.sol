//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomMinter {
    function mintRandomFree(
        uint8 _itemsPerRandomMint,
        address _to,
        string memory desc
    ) external;

    function mintRandom(uint8 _itemsPerRandomMint) external payable;
}
