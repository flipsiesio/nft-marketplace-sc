// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title A simple ERC20 token for tests
contract Rummy is ERC20 {
    constructor() ERC20("Rummy", "RMM") {}

    function mintTo(address receiver, uint256 amount) public {
        _mint(receiver, amount);
    }
}