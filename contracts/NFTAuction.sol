//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;
//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './interfaces/IERC721.sol';
import './Management.sol';
import './SafeMath.sol';
import './Status.sol';

contract NFTAuction is Management {
    using SafeMath for uint256;

    struct Auction {
        uint256 tokenId;
        address seller;
        address lastBuyer;
        uint256 stopDuration;
        uint256 currentPrice;
        Status status;
    }

    event AuctionCreated(uint256 indexed _at);
    event AuctionRejected(uint256 indexed _at);
    event AuctionFilled(uint256 indexed _at);
    event AuctionBid(uint256 indexed _at);

    mapping(uint256 => Auction) internal _auctions;
    uint256 public minStopDuration;
    uint256 public maxStopDuration;

    modifier validStopDuration(uint256 _stopDuration) {
        require(_stopDuration >= minStopDuration && _stopDuration <= maxStopDuration, "invalidStopDuration");
        _;
    }

    function setMinStopDuration(uint256 _minStopDuration) external onlyOwner {
        minStopDuration = _minStopDuration;
    }

    function setMaxStopDuration(uint256 _maxStopDuration) external onlyOwner {
        maxStopDuration = _maxStopDuration;
    }

    function getAuctionsAmount() external view returns(uint256) {
        returns _length;
    }

    function getTokenIdOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        returns _auctions[_at].tokenId;
    }

    function getSellerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        returns _auctions[_at].seller;
    }

    function getLastBuyerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        returns _auctions[_at].lastBuyer;
    }

    function getStopDurationOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        returns _auctions[_at].stopDuration;
    }

    function getCurrentPriceOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        returns _auctions[_at].currentPrice;
    }

    function getStatusOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        returns uint256(_auctions[_at].status);
    }

    function createAuction(uint256 _nftToSell, uint256 _stopDuration, uint256 _expirationDuration, uint256 _startPrice)
        external
        validStopDuration(_stopDuration);
        validExpirationDuration(_expirationDuration)
    {
        nftOnSale.safeTransferFrom(msg.sender, address(this), _nftToSell);
        _auctions[_length] = Auction({
            tokenId: _nftToSell,
            seller: msg.sender,
            lastBuyer: address(0),
            stopDuration: _stopDuration,
            currentPrice: _startPrice,
            status: Status.PENDING;
        });
        emit AuctionCreated(_length);
        _length = _length.add(1);
    }

    function cancelAuction(uint256 _at)
        external
        validIndex(_at)
        onlySellerOf(_at)
    {
        nftOnSale.safeTransferFrom(address(this), msg.sender, _sellOrders[_at].tokenId);
        _auctions[_at].status = Status.REJECTED;
        emit AuctionRejected(_at);
    }

    function bid(uint256 _at, uint256 _newPrice) external validIndex(_at) {
        require(msg.sender.balance >= _newPrice, "notEnoughFunds");
        require(_auctions[_at].currentPrice < _newPrice, "cannotBidOnLowerPrice");

    }

    function take(uint256 _at) external {

    }

}
