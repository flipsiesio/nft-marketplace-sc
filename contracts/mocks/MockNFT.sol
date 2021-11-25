pragma solidity ^0.4.0;

import "../interfaces/IERC721.sol";

contract MockNFT is IERC721 {

    mapping(address => uint256) internal _balances;
    mapping(uint256 => address) internal _owners;

    function balanceOf(address owner) external view returns(uint256 balance) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns(address owner) {
        return _owners[tokenId];
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {

    }

    function approve(address to, uint256 tokenId) external {

    }

    function getApproved(uint256 tokenId) external view returns(address operator) {
        return address(0);
    }

    function setApprovalForAll(address operator, bool _approved) external {

    }

    function isApprovedForAll(address owner, address operator) external view returns(bool) {
        return true;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes data
    ) external {

    }
}
