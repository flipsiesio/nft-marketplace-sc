//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/// @title A generic poker card minter contract.
interface ICardRandomMinter {

    /** 
     * 
     * @notice Checks if provided token is supported
     * @param tokenAddress The address of the token to check
     * @return True if token is supported. False - if token is not supported.
     */
    function isSupported(address tokenAddress) external view returns(bool);

    /**
     * @notice Adds a supported token to pay for mint in
     * @param tokenAddress The address of the token to add
     */
    function addSupportedToken(address tokenAddress) external;

    /**
     * @notice Removes a supported token to pay for mint in
     * @param tokenAddress The address of the token to remove
     */
    function removeSupportedToken(address tokenAddress) external;

    /**
     * @notice Returns the number of supported tokens
     * @return The number of supported tokens
     */
    function getSupportedLength() external view returns(uint256);

    /**
     * @notice Sets the mint price for each supported token
     * @param tokenAddress The address of the token to set the price in
     * @param priceInTokens The price in tokens to set
     */
    function setMintPrice(address tokenAddress, uint256 priceInTokens) external;

    /**
     * @notice Gets the card mint price in provided tokens
     * @param tokenAddress The address of the token to check the card mint price in
     * @return A card mint price. Should be divided by `demicals` (18 in most cases) for UI
     */
    function getMintPrice(address tokenAddress) external view returns(uint256);

    /**
     * @notice Mints a set of random items (cards) for free
     * @param numCards Number of cards to be minted
     * @param to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function mintRandomFree(uint8 numCards, address to, string memory desc) external;

    /**
     * @notice Mints a set of random items (cards) for provided funds
     * @param numCards Number of cards to be minted
     * @param tokenToPay Address of the token that will be payed to mint a card
     */            
    function mintRandom(uint8 numCards, address tokenToPay) external payable;

}
