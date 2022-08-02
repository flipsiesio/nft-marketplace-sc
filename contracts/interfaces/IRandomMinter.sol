//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/// @title A generic poker card minter contract.
interface IRandomMinter {
    /**
     * @notice Mints a set of random items (cards) for free
     * @param _itemsPerRandomMint Number of cards to be minted
     * @param _to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function mintRandomFree(
        uint8 _itemsPerRandomMint,
        address _to,
        string memory desc
    ) external;
    
    /**
     * @notice Mints a set of random items (cards) for provided funds
     * @param _itemsPerRandomMint Number of cards to be minted
     */
    function mintRandom(uint8 _itemsPerRandomMint) external payable;
}
