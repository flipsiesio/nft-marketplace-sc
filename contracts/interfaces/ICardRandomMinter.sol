//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


/// @title A generic poker card minter contract.
interface ICardRandomMinter {

    /**
     * @notice Checks if provided address is an admin
     * @param adminAddress The address to check
     * @return True if address is an admin, false - if address is not an admin
     */
    function isAdmin(address adminAddress) external view returns(bool);
    
    /**
     * @notice Adds a new admin address
     * @param newAdmin The address of the new admin to set
     */
    function addAdmin(address newAdmin) external;

    /** 
     * @notice Removes an address from admin list
     * @param adminAddress The address to remove from admin list
     */
    function removeAdmin(address adminAddress) external;

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
     * @notice Gives rights to call card mint function
     * @param who Address to be given rights to mint cards
     * @param status 'True' gives the address the right to mint cards, 'false' - forbids to mint cards
     */
    function setMinterRole(address who, bool status) external;


    /**
     * @notice Sets the amount of items that can be randomly minted
     * @param amount The amount of items that can be randomly minted
     * @param status 'True' allows to mint that amount of cards, 'false' - forbids to mint that amount of cards
     */
    function setAllowedAmountOfItemsPerRandomMint(uint8 amount, bool status) external;
    
    /**
     * @notice Changes the factory that mints cards
     * @param newFactoryAddress An address of a new factory
     */
    function setFactory(address newFactoryAddress) external;

    /**
     * @notice Changes the seed to change the source of randomness
     * @param newSeed A new seed to be set
     */
    function setCurrentSeed(uint256 newSeed) external;

    /**
     * @notice Sets probabilty of each class of cards to be randomly picked
     * @param classProbs List of probabilities for all classes of cards
     */
    function setProbabilitiesForClasses(uint16[5] memory classProbs) external;

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

    /// @notice Transfers all funds to the owner
    function getRevenue() external;

}
