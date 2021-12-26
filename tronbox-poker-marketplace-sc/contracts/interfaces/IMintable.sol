//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

interface IMintable {
     function mint(address _to, uint256 _tokenId) external;
}
