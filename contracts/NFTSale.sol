//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './interfaces/IERC721.sol';
import './Management.sol'
import './SafeMath.sol';
import './Status.sol';

contract NFTSale is Management {
    using SafeMath for uint256;

    event OrderCreated(uint256 indexed orderIndex);
    event OrderFilled(uint256 indexed orderIndex);
    event OrderRejected(uint256 indexed orderIndex);

    struct SellOrder {
        uint256 tokenId;
        address seller;
        uint256 price;
        Status status;
        uint256 expirationTime;
        uint256 paidFees;
    }

    mapping(uint256 => SellOrder) internal _sellOrders;

    function getSellOrdersAmount() external view returns(uint256) {
        return _length;
    }

    function getSellOrderTokenId(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].tokenId;
    }

    function getSellOrderSeller(uint256 _at) external view validIndex(_at) returns(address) {
        return _sellOrders[_at].seller;
    }

    function getSellOrderPrice(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].price;
    }

    function getSellOrderFeesPaid(uint256 _at) external view validIndex(_at) returns(uint256) {
        return _sellOrders[_at].paidFees;
    }

    function getSellStatus(uint256 _at) external view validIndex(_at) returns(uint256) {
        return uint256(_sellOrders[_at].status);
    }

    function getBackFromSale(uint256 _at) external onlySellerOf(_at) {
        nftOnSale.safeTransferFrom(address(this), msg.sender, _sellOrders[_at].tokenId);
        if (block.timestamp <= _sellOrders[_at].expirationDuration) {
            _sellOrders[_at].status = Status.REJECTED;
        } else {
            _sellOrders[_at].status = Status.EXPIRED;
        }
        emit OrderRejected(_at);
    }

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
        emit OrderCreated(_length);
        _length = _length.add(1);
    }

    function setPriceFor(uint256 _at, uint256 _price) external
        validIndex(_at)
        onlySellerOf(_at)
    {
        _sellOrders[_at].price = _price;
    }

    function setExpirationTimeFor(uint256 _at, uint256 _expirationTime) external
        validIndex(_at)
        onlySellerOf(_at)
    {
        require(block.timestamp <= _expirationTime, "onlyFutureTimeAllowed");
        _sellOrders[_at].expirationTime = _expirationTime;
    }

    function buy(uint256 _at) external payable nonReentrant validIndex(_at) {
        uint256 price = _sellOrders[_at].price;
        uint256 feeAmount = price.mul(buyFee).div(MAX_FEE);
        require(msg.value >= price.add(feeAmount)), "notEnoughFunds");
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
