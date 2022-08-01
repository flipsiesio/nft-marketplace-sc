//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Card is Ownable, ERC721 {
    mapping(address => bool) public isMinter;
    mapping(bytes4 => bool) private _supportedInterfaces;
    mapping(address => uint256[]) public ownedTokens;

    bytes4 private constant _INTERFACE_ID_TRC165 = 0x01ffc9a7;
    bytes4 private constant _INTERFACE_ID_TRC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_TRC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_TRC721_ENUMERABLE = 0x780e9d63;

    constructor() ERC721("Flipsies NFT", "FLP") {
        isMinter[msg.sender] = true;

        _supportedInterfaces[_INTERFACE_ID_TRC165] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721_METADATA] = true;
        _supportedInterfaces[_INTERFACE_ID_TRC721_ENUMERABLE] = true;
    }

    function mint(address _to, uint256 _tokenId) external {
        require(isMinter[msg.sender], "onlyMinter");
        _mint(_to, _tokenId);
        ownedTokens[_to].push(_tokenId);

    }

    // Set CardFactory instance as minter
    function setMinterRole(address _minter, bool _status) external onlyOwner {
        isMinter[_minter] = _status;
    }

    function getNFTListByAddress(address _nftOwner)
        public
        view
        returns (uint256[] memory)
    {
        return ownedTokens[_nftOwner];
    }

    function supportsInterface (bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }
}
