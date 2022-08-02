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
     * @param _to The address that receives minted toke
     * @param _tokenId The ID of the minted token
     */
    function mint(address _to, uint256 _tokenId) external {
        require(isMinter[msg.sender], "Card: Caller Is Not A Minter!");
        _mint(_to, _tokenId);
        ownedTokens[_to].push(_tokenId);
    }

    /**
     * @notice Gives the '_minter' address a right to call card 'mint' function
     * @notice Usually you have to call this function oт CardFactory instance
     * @param _minter The address that gets the rights to mint cards
     * @param _status If 'true' - allows to mint cards, if 'false - forbids to do that
     */
    function setCardMinter(address _minter, bool _status) external onlyOwner {
        isMinter[_minter] = _status;
    }

    /**
     *  @notice Returns all tokens owned by the '_nftOwner' address
     *  @param _nftOwner The address of tokens owner
     *  @return List of IDs of tokens owned by the address
     */
    function getNFTListByAddress(address _nftOwner)
        public
        view
        returns (uint256[] memory)
    {
        return ownedTokens[_nftOwner];
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
