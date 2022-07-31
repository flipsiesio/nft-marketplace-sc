//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMintable {
    function mint(address _to, uint256 _tokenId) external;

    function exists(uint256 _tokenId) external view returns (bool);
}
