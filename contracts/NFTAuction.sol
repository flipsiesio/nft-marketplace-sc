//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './interfaces/IERC721.sol';
import './Management.sol';
import './SafeMath.sol';

contract NFTAuction is Management {
    using SafeMath for uint256;

    struct Auction {
        uint256 tokenId;
        address seller;
        address lastBuyer;
        uint256 stopTime;
        uint256 currentPrice;
        uint256 feesToPay;
        Status status;
    }

    event AuctionCreated(uint256 indexed _at);
    event AuctionRejected(uint256 indexed _at);
    event AuctionFilled(uint256 indexed _at);
    event AuctionBid(uint256 indexed _at);

    mapping(uint256 => Auction) internal _auctions;

    modifier onlySellerOf(uint256 _at) {
        require(_auctions[_at].seller == msg.sender, "onlySeller");
        _;
    }

    function getAuctionsAmount() external view returns(uint256) {
        return _length;
    }

    function getTokenIdOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].tokenId;
    }

    function getSellerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        return _auctions[_at].seller;
    }

    function getLastBuyerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        return _auctions[_at].lastBuyer;
    }

    function getStopTimeOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].stopTime;
    }

    function getCurrentPriceOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].currentPrice;
    }

    function getCurrentFeesToPayOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].feesToPay;
    }

    function getStatusOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return uint256(_auctions[_at].status);
    }

    function createAuction(uint256 _nftToSell, uint256 _expirationDuration, uint256 _startPrice)
        external
        validExpirationDuration(_expirationDuration)
    {
        nftOnSale.safeTransferFrom(msg.sender, address(this), _nftToSell);
        _auctions[_length] = Auction({
            tokenId: _nftToSell,
            seller: msg.sender,
            lastBuyer: address(0),
            stopTime: block.timestamp.add(_expirationDuration),
            currentPrice: _startPrice,
            feesToPay: 0,
            status: Status.PENDING
        });
        emit AuctionCreated(_length);
        _length = _length.add(1);
    }

    function cancelAuction(uint256 _at)
        external
        validIndex(_at)
        onlySellerOf(_at)
    {
        nftOnSale.safeTransferFrom(address(this), msg.sender, _auctions[_at].tokenId);
        if (block.timestamp <= _auctions[_at].stopTime) {
          _auctions[_at].status = Status.REJECTED;
        } else {
          _auctions[_at].status = Status.EXPIRED;
        }
        emit AuctionRejected(_at);
    }

    function bid(uint256 _at, uint256 _newPrice) external validIndex(_at) {
        require(msg.sender.balance >= _newPrice, "notEnoughFundsToProveYourBid");
        require(_auctions[_at].currentPrice < _newPrice, "cannotBidOnLowerPrice");
        require(block.timestamp <= _auctions[_at].stopTime, "auctionIsStopped");
        require(_auctions[_at].status == Status.PENDING, "auctionMustBePending");
        _auctions[_at].currentPrice = _newPrice;
        _auctions[_at].lastBuyer = msg.sender;
        _auctions[_at].feesToPay = _newPrice.mul(feeInBps).div(MAX_FEE);
        emit AuctionBid(_at);
    }

    function take(uint256 _at) external payable nonReentrant {
        require(msg.value >= _auctions[_at].currentPrice.add(_auctions[_at].feesToPay), "notEnoughFunds");
        require(block.timestamp > _auctions[_at].stopTime, "auctionIsStopped");
        require(msg.sender == _auctions[_at].lastBuyer, "mustBeBuyerWhoWon");
        _auctions[_at].seller.transfer(_auctions[_at].currentPrice);
        feeReceiver.transfer(_auctions[_at].feesToPay);
        nftOnSale.safeTransferFrom(address(this), _auctions[_at].lastBuyer, _auctions[_at].tokenId);
        _auctions[_at].status = Status.FILLED;
        emit AuctionFilled(_at);
    }

}
