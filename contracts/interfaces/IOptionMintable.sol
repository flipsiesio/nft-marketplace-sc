//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title This is a generic factory contract that can be used to mint tokens. The configuration
 * for minting is specified by an _optionId, which can be used to delineate various
 * ways of minting.
 */
interface IOptionMintable {
    /**
     * @dev Mints asset(s) in accordance to a specific address with a particular "option". This should be
     * callable only by the contract owner or the owner's Wyvern Proxy (later universal login will solve this).
     * Options should also be delineated 0 - (numOptions() - 1) for convenient indexing.
     * @param _optionId The option id
     * @param _toAddress Address of the future owner of the asset(s)
     */
    function mint(uint8 _optionId, address _toAddress) external returns (bool);
}
