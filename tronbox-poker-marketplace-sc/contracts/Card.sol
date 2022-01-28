//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './openzeppelin/ownership/Ownable.sol';
import './openzeppelin/token/ERC721/ERC721Token.sol';

import "./interfaces/IMintable.sol";

contract Card is Ownable, ERC721Token {

    mapping(address => bool) public isMinter;

    constructor() ERC721Token("Flipsies NFT", "FLP") public {
        isMinter[msg.sender] = true;
    }

    function mint(address _to, uint256 _tokenId) external {
        require(isMinter[msg.sender], "onlyMinter");
        _mint(_to, _tokenId);
    }

    // Set CardFactory instance as minter
    function setMinterRole(address _minter, bool _status) external onlyOwner {
        isMinter[_minter] = _status;
    }

    function getNFTListByAddress(address _nftOwner) public returns (uint256 []) {
        return ownedTokens[_nftOwner];
    }
}
