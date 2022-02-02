//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './openzeppelin/math/SafeMath.sol';

import './interfaces/IERC721.sol';
import './Management.sol';

/// @title A contract of the marketplace.
/// @author Integral Team
contract NFTSale is Management {
    using SafeMath for uint256;


    /// @notice This event is fired when seller create the sell order
    event OrderCreated(uint256 tokenId, uint256 indexed orderIndex);

    /// @notice This event is fired when seller fill the sell order
    event OrderFilled(uint256 indexed orderIndex);

    /// @notice This event is fired when seller reject the sell order
    event OrderRejected(uint256 indexed orderIndex);

    // This struct is describing the sell order information
    struct SellOrder {
        uint256 tokenId; // ID of the selling token
        address seller; // seller address
        uint256 price; // price of the selling token in ETH
        Status status; // status of the sell order
        uint256 expirationTime; // time when the sell order expires
        uint256 paidFees; // amount of fees to pay
    }

    /// @notice the storage for the sell orders
    mapping(uint256 => SellOrder) internal _sellOrders;

    /// @notice This custom modifier is to validate if msg.sender is the seller of the sell orders
    /// @param _at The index of the given sell roder in which seller is checked
    modifier onlySellerOf(uint256 _at) {
        require(_sellOrders[_at].seller == msg.sender, "onlySeller");
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

    /// @notice The standard getter to return an amount of the sell orders
    /// @return Amount of the sell orders
    function getSellOrdersAmount() external view returns(uint256) {
        return _length;
    }

    /// @notice The standard getter to return a token ID of the given sell order
    /// @param _at The index of the sell order
    /// @return The ID of the selling token
    function getSellOrderTokenId(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].tokenId;
    }

    /// @notice The standard getter to return a seller address of the given sell order
    /// @param _at The index of the sell order
    /// @return The seller address of the sell order
    function getSellOrderSeller(uint256 _at) external view validIndex(_at) returns(address) {
        return _sellOrders[_at].seller;
    }

    /// @notice The standard getter to return a price in ETH of the given sell order
    /// @param _at The index of the sell order
    /// @return Price in ETH
    function getSellOrderPrice(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].price;
    }

    /// @notice The standard getter to return a fees to pay amount of the given sell order
    /// @param _at The index of the sell order
    /// @return Amount fees to pay
    function getSellOrderFeesPaid(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].paidFees;
    }

    /// @notice The standard getter to return an expiration time of the given sell order
    /// @param _at The index of the sell order
    /// @return Expiration timestamp in future
    function getSellOrderExpirationTime(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].expirationTime;
    }

    /// @notice The standard getter to return a status of the given sell order
    /// @param _at The index of the auction
    /// @return Status enumeration member as uint256
    function getSellOrderStatus(uint256 _at) external view validIndex(_at) returns(uint256) {
        return uint256(_sellOrders[_at].status);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param _at The index of the sell order
    function getBackFromSale(uint256 _at) external onlySellerOf(_at) {
        require(_sellOrders[_at].status == Status.PENDING, "onlyWhenPending");
        nftOnSale.safeTransferFrom(address(this), msg.sender, _sellOrders[_at].tokenId);
        if (block.timestamp <= _sellOrders[_at].expirationTime) {
            _sellOrders[_at].status = Status.REJECTED;
        } else {
            _sellOrders[_at].status = Status.EXPIRED;
        }
        emit OrderRejected(_at);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param _nftToSell The token ID to sell through sell order
    /// @param _price The price of the sell order
    /// @param _expirationDuration The duration of the sell order, and when it passed the sell order could not be filled without restarting of the sell order.
    function acceptTokenToSell(uint256 _nftToSell, uint256 _price, uint256 _expirationDuration)
        external
        validExpirationDuration(_expirationDuration)
    {
        nftOnSale.safeTransferFrom(msg.sender, address(this), _nftToSell);
        _sellOrders[_length] = SellOrder({
            tokenId: _nftToSell,
            seller: msg.sender,
            price: _price,
            status: Status.PENDING,
            expirationTime: block.timestamp.add(_expirationDuration),
            paidFees: 0
        });
        emit OrderCreated(_nftToSell, _length);
        _length = _length.add(1);
    }

    /// @notice The function allows seller to change price.
    /// @param _at The seller order index
    /// @param _price The new price for the sell order
    function setPriceFor(uint256 _at, uint256 _price) external
        validIndex(_at)
        onlySellerOf(_at)
    {
        _sellOrders[_at].price = _price;
    }

    /// @notice The function allows seller continue selling by expanding the expiration time of the sell order.
    /// @param _at The seller order index
    /// @param _expirationTime The new expiration time for the sell order
    function setExpirationTimeFor(uint256 _at, uint256 _expirationTime) external
        validIndex(_at)
        onlySellerOf(_at)
    {
        require(_sellOrders[_at].expirationTime <= _expirationTime, "onlyFutureTimeAllowed");
        _sellOrders[_at].expirationTime = _expirationTime;
    }

    /// @notice The function allows anyone to fill sell order.
    /// @param _at The seller order index
    function buy(uint256 _at) external payable nonReentrant validIndex(_at) {
        uint256 price = _sellOrders[_at].price;
        uint256 feeAmount = price.mul(feeInBps).div(MAX_FEE);
        require(msg.value >= price.add(feeAmount), "notEnoughFunds");
        require(_sellOrders[_at].status == Status.PENDING, "orderIsFilledOrRejected");
        require(block.timestamp <= _sellOrders[_at].expirationTime, "orderIsExpired");

        nftOnSale.safeTransferFrom(address(this), msg.sender, _sellOrders[_at].tokenId);
        _sellOrders[_at].seller.transfer(_sellOrders[_at].price);
        feeReceiver.transfer(feeAmount);
        _sellOrders[_at].paidFees = feeAmount;
        _sellOrders[_at].status = Status.FILLED;
        emit OrderFilled(_at);
    }
}
