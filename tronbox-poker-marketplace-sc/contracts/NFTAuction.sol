//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './openzeppelin/math/SafeMath.sol';

import './interfaces/IERC721.sol';
import './Management.sol';

/// @title A contract for auctioning the NFTs.
/// @author Integral Team
contract NFTAuction is Management {
    using SafeMath for uint256;

    // This struct is describing the auction information
    struct Auction {
        uint256 tokenId; // id of the auctioning token
        address seller; // id of the seller who is selling the auctioning token
        address lastBuyer; // the last of the buyers who bid last and faster than anyone
        uint256 stopTime; // the time after which the auction is considered closed and "take" function is unblocked
        uint256 currentPrice; // the current price of the auctioning timer, it do rise as auction proceed
        uint256 feesToPay; // the fees amount which must be payed above the current price
        Status status; // the status of the auction
    }

    /// @notice This event is fired when seller create an auction
    event AuctionCreated(uint256 indexed _at);

    /// @notice This event is fired when seller reject the auction
    event AuctionRejected(uint256 indexed _at);

    /// @notice This event is fired when last buyer buy the auctioning item after auction is done
    event AuctionFilled(uint256 indexed _at);

    /// @notice This event is fired when some buyer bids on the auction
    event AuctionBid(uint256 indexed _at);

    /// @notice This mapping contains the auctions history
    mapping(uint256 => Auction) internal _auctions;

    /// @notice This custom modifier is to validate if msg.sender is the seller of the auction
    /// @param _at The index of the given auction in which seller is checked
    modifier onlySellerOf(uint256 _at) {
        require(_auctions[_at].seller == msg.sender, "onlySeller");
        _;
    }

    constructor(
        address _nftOnSale,
        address _feeReceiver,
        uint256 _minExpirationDuration,
        uint256 _maxExpirationDuration,
        uint256 _feeInBps
    )
        public
        Management(
          _nftOnSale,
          _feeReceiver,
          _minExpirationDuration,
          _maxExpirationDuration,
          _feeInBps
        )
    {}

    /// @notice The standard getter to return an amount of the auctions
    /// @return Amount of the auctions
    function getAuctionsAmount() external view returns(uint256) {
        return _length;
    }

    /// @notice The standard getter to return a token ID of the given auctions selling token
    /// @param _at The index of the auction
    /// @return The ID of the auctions selling token
    function getTokenIdOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].tokenId;
    }

    /// @notice The standard getter to return a seller of the given auction
    /// @param _at The index of the auction
    /// @return Seller address
    function getSellerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        return _auctions[_at].seller;
    }

    /// @notice The standard getter to return a seller of the given auction
    /// @param _at The index of the auction
    /// @return Seller address
    function getLastBuyerOfAuction(uint256 _at) external view validIndex(_at) returns(address) {
        return _auctions[_at].lastBuyer;
    }

    /// @notice The standard getter to return a stop time of the given auction
    /// @param _at The index of the auction
    /// @return Stop time in UNIX timestamp
    function getStopTimeOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].stopTime;
    }

    /// @notice The standard getter to return a current price of the given auction
    /// @param _at The index of the auction
    /// @return Current price of the auctioning token
    function getCurrentPriceOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].currentPrice;
    }

    /// @notice The standard getter to return a current amount of fees to pay of the given auction
    /// @param _at The index of the auction
    /// @return Current amount of fees to pay
    function getCurrentFeesToPayOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _auctions[_at].feesToPay;
    }

    /// @notice The standard getter to return a status of the given auction
    /// @param _at The index of the auction
    /// @return Status enumeration member as uint256
    function getStatusOfAuction(uint256 _at) external view validIndex(_at) returns(uint256) {
        return uint256(_auctions[_at].status);
    }

    /// @notice The function which could create a auction
    /// @param _nftToSell The selling token ID
    /// @param _expirationDuration Duration of the auction in valid bounds (between min and max value of the duration)
    /// @param _startPrice Starting price of the selling token in ETH (wei)
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

    /// @notice This function can be called only by the seller of the auctioning item
    /// and provides the functional to reject or expire the auction if certain amount of time passed.
    /// Emits the AuctionRejected event
    /// @param _at The index of the auction
    function cancelAuction(uint256 _at)
        external
        validIndex(_at)
        onlySellerOf(_at)
    {
        require(_auctions[_at].status == Status.PENDING, "auctionIsEitherFilledOrRejectedOrExpired");
        nftOnSale.safeTransferFrom(address(this), msg.sender, _auctions[_at].tokenId);
        if (block.timestamp <= _auctions[_at].stopTime) {
          _auctions[_at].status = Status.REJECTED;
        } else {
          _auctions[_at].status = Status.EXPIRED;
        }
        emit AuctionRejected(_at);
    }

    /// @notice Allows anyone to bid in the ceriatin auction if they have needed balance.
    /// @param _at The index of the auction
    /// @param _newPrice The price which the buyer want to spend at the auctioning item.
    /// Must be greater than current price in the auction.
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

    /// @notice Allows the address who won the auction pay and take bought NFT item.
    /// @param _at The index of the auction
    function take(uint256 _at) external payable nonReentrant {
        require(msg.value >= _auctions[_at].currentPrice.add(_auctions[_at].feesToPay), "notEnoughFunds");
        require(block.timestamp > _auctions[_at].stopTime, "auctionIsStopped");
        require(msg.sender == _auctions[_at].lastBuyer, "senderMustBeBuyerWhoWon");
        _auctions[_at].seller.transfer(_auctions[_at].currentPrice);
        feeReceiver.transfer(_auctions[_at].feesToPay);
        nftOnSale.safeTransferFrom(address(this), _auctions[_at].lastBuyer, _auctions[_at].tokenId);
        _auctions[_at].status = Status.FILLED;
        emit AuctionFilled(_at);
    }

}
