//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";


/// @title A poker game card
contract Card is Ownable, ERC721 {
    /// @dev A list of minters
    mapping(address => bool) public isMinter;
    /// @dev A list of supported interfaces
    mapping(bytes4 => bool) private _supportedInterfaces;
    /// @dev A list of tokens owned by users
    mapping(address => uint256[]) public ownedTokens;

    /// @dev All supported interfaces
    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

    /// @dev Caller gets the right to mint
    constructor() ERC721("Flipsies NFT", "FLP") {
        isMinter[msg.sender] = true;

        _supportedInterfaces[_INTERFACE_ID_TRC165] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721_METADATA] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721_ENUMERABLE] = true;
    }

    /**
     * @notice Mints an NFT token with 'tokenID' to the 'to' address 
     * @dev Adds the minted token to the list of owned tokens of the 'to' address
     * @param to The address that receives minted toke
     * @param tokenId The ID of the minted token
     */
    function mint(address to, uint256 tokenId) external {
        require(isMinter[msg.sender], "Card: Caller Is Not A Minter!");
        _mint(to, tokenId);
        ownedTokens[to].push(tokenId);
    }

    /**
     * @notice Gives the 'minter' address a right to call card 'mint' function
     * @notice Usually you have to call this function for CardFactory instance
     * @param minter The address that gets the rights to mint cards
     * @param status If 'true' - allows to mint cards, if 'false - forbids to do that
     */
    function setMinterRole(address minter, bool status) external onlyOwner {
        isMinter[minter] = status;
    }

    /**
     *  @notice Returns all tokens owned by the 'nftOwner' address
     *  @param nftOwner The address of tokens owner
     *  @return List of IDs of tokens owned by the address
     */
    function getNFTListByAddress(address nftOwner)
        public
        view
        returns (uint256[] memory)
    {
        return ownedTokens[nftOwner];
    }

    function exists(uint256 tokenID) public view returns(bool) {
        return _exists(tokenID);
    }

    /**
     * @notice Checks whether this contract supports the provided interface
     * @param interfaceId 4 bytes representing ID of the interface to check
     * @return 'True' if contracts supports provided interface, 'false' - if does not
     */
    function supportsInterface (bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }
}
