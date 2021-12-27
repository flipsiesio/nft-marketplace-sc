//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

interface IRandomMinter {
     function mintRandomFree(uint8 _itemsPerRandomMint, address _to) external;
     function mintRandom(uint8 _itemsPerRandomMint) external payable;
}
