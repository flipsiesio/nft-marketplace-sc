//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Management.sol";

/// @title A contract of the marketplace.
/// @author Integral Team
contract NFTMarketplace is Management {
    using SafeMath for uint256;

    /// @notice This event is fired when seller create the sell order
    event OrderCreated(
        uint256 indexed tokenId,
        uint256 indexed orderIndex,
        address seller,
        uint256 expirationTime
    );

    /// @notice This event is fired when seller fill the sell order
    event OrderFilled(
        uint256 indexed orderIndex,
        address indexed buyer,
        uint256 price
    );

    /// @notice This event is fired when seller reject the sell order
    event OrderRejected(uint256 indexed orderIndex);

    /// @notice This event is fired when buyer places or updates a bid
    event Bid(
        uint256 indexed orderIndex,
        address indexed buyer,
        uint256 added,
        uint256 indexed total
    );

    /// @notice This event is fired when buyer renounce the bid
    event BidCancelled(
        uint256 indexed orderIndex,
        address indexed buyer,
        uint256 indexed amount
    );

    // This struct is describing the sell order information
    struct SellOrder {
        uint256 tokenId; // ID of the selling token
        address seller; // seller address
        uint256 price; // price of the selling token in ETH
        Status status; // status of the sell order
        uint256 expirationTime; // time when the sell order expires
        uint256 paidFees; // amount of fees to pay
        mapping(address => uint256) bids; // bids for sell order (buyer => amount to buy)
    }

    /// @notice the storage for the sell orders
    mapping(uint256 => SellOrder) internal _sellOrders;

    /// @notice This custom modifier is to validate if msg.sender is the seller of the sell orders
    /// @param _at The index of the given sell roder in which seller is checked
    modifier onlySellerOf(uint256 _at) {
        require(_sellOrders[_at].seller == msg.sender, "NFTMarketplace: Caller Is Not a Seller!");
        _;
    }

    constructor(
        address _nftOnSale,
        address _feeReceiver,
        uint256 _minExpirationDuration,
        uint256 _maxExpirationDuration,
        uint256 _feeInBps
    )
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
    function getSellOrdersAmount() external view returns (uint256) {
        return _length;
    }

    /// @notice The standard getter to return a token ID of the given sell order
    /// @param _at The index of the sell order
    /// @return The ID of the selling token
    function getSellOrderTokenId(uint256 _at)
        external
        view
        validIndex(_at)
        returns (uint256)
    {
        return _sellOrders[_at].tokenId;
    }

    /// @notice The standard getter to return a seller address of the given sell order
    /// @param _at The index of the sell order
    /// @return The seller address of the sell order
    function getSellOrderSeller(uint256 _at)
        external
        view
        validIndex(_at)
        returns (address)
    {
        return _sellOrders[_at].seller;
    }

    /// @notice The standard getter to return a price in ETH of the given sell order
    /// @param _at The index of the sell order
    /// @return Price in ETH
    function getSellOrderPrice(uint256 _at)
        external
        view
        validIndex(_at)
        returns (uint256)
    {
        return _sellOrders[_at].price;
    }

    /// @notice The standard getter to return a fees to pay amount of the given sell order
    /// @param _at The index of the sell order
    /// @return Amount fees to pay
    function getSellOrderFeesPaid(uint256 _at)
        external
        view
        validIndex(_at)
        returns (uint256)
    {
        return _sellOrders[_at].paidFees;
    }

    /// @notice The standard getter to return an expiration time of the given sell order
    /// @param _at The index of the sell order
    /// @return Expiration timestamp in future
    function getSellOrderExpirationTime(uint256 _at)
        external
        view
        validIndex(_at)
        returns (uint256)
    {
        return _sellOrders[_at].expirationTime;
    }

    /// @notice The standard getter to return a status of the given sell order
    /// @param _at The index of the auction
    /// @return Status enumeration member as uint256
    function getSellOrderStatus(uint256 _at)
        external
        view
        validIndex(_at)
        returns (uint256)
    {
        return uint256(_sellOrders[_at].status);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param _at The index of the sell order
    function getBackFromSale(uint256 _at) external onlySellerOf(_at) {
        require(_sellOrders[_at].status == Status.PENDING, "NFTMarketplace: Possible Only While Pending!");

        if (block.timestamp <= _sellOrders[_at].expirationTime) {
            _sellOrders[_at].status = Status.REJECTED;
        } else {
            _sellOrders[_at].status = Status.EXPIRED;
        }

        nftOnSale.safeTransferFrom(
            address(this),
            msg.sender,
            _sellOrders[_at].tokenId
        );
        emit OrderRejected(_at);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param _nftToSell The token ID to sell through sell order
    /// @param _price The price of the sell order
    /// @param _expirationDuration The duration of the sell order, and when it passed the sell order could not be filled without restarting of the sell order.
    function acceptTokenToSell(
        uint256 _nftToSell,
        uint256 _price,
        uint256 _expirationDuration
    ) external validExpirationDuration(_expirationDuration) {
        nftOnSale.safeTransferFrom(msg.sender, address(this), _nftToSell);
        SellOrder storage order = _sellOrders[_length];
        order.tokenId = _nftToSell;
        order.seller = msg.sender;
        order.price = _price;
        order.status = Status.PENDING;
        order.expirationTime = block.timestamp.add(_expirationDuration);
        order.paidFees = 0;
        emit OrderCreated(
            _nftToSell,
            _length,
            msg.sender,
            block.timestamp.add(_expirationDuration)
        );
        _length = _length.add(1);
    }

    /// @notice The function allows seller to change price.
    /// @param _at The seller order index
    /// @param _price The new price for the sell order
    function setPriceFor(uint256 _at, uint256 _price)
        external
        validIndex(_at)
        onlySellerOf(_at)
    {
        _sellOrders[_at].price = _price;
    }

    /// @notice The function allows seller continue selling by expanding the expiration time of the sell order.
    /// @param _at The seller order index
    /// @param _expirationTime The new expiration time for the sell order
    function setExpirationTimeFor(uint256 _at, uint256 _expirationTime)
        external
        validIndex(_at)
        onlySellerOf(_at)
    {
        require(
            _sellOrders[_at].expirationTime <= _expirationTime,
            "NFTMarketplace: Only Future Time Is Allowed!"
        );
        _sellOrders[_at].expirationTime = _expirationTime;
    }

    function bid(uint256 _at, uint256 _amount)
        external
        payable
        validIndex(_at)
    {
        require(_amount > 0, "NFTMarketplace: Invalid Bid Amount");
        require(
            _sellOrders[_at].status == Status.PENDING,
            "NFTMarketplace: Order Is Filled / Rejected!"
        );
        require(
            block.timestamp <= _sellOrders[_at].expirationTime,
            "NFTMarketplace: Order Is Expired!"
        );

        uint256 feeAmount = _amount.mul(feeInBps).div(MAX_FEE);
        require(msg.value >= _amount.add(feeAmount), "NFTMarketplace: Not Enough Funds!");

        _sellOrders[_at].bids[msg.sender] = _sellOrders[_at]
            .bids[msg.sender]
            .add(_amount);
        emit Bid(_at, msg.sender, _amount, _sellOrders[_at].bids[msg.sender]);
    }

    function cancelBid(uint256 _at) external nonReentrant validIndex(_at) {
        require(
            (_sellOrders[_at].status != Status.PENDING) ||
                (block.timestamp > _sellOrders[_at].expirationTime),
            "NFTMarketplace: Order Is Active!"
        );
        require(
            _sellOrders[_at].bids[msg.sender] > 0,
            "NFTMarketplace: Nothing To Cancel And Return!"
        );

        uint256 bidToReturn = _sellOrders[_at].bids[msg.sender];
        uint256 feeAmount = bidToReturn.mul(feeInBps).div(MAX_FEE);
        uint256 toReturn = bidToReturn.add(feeAmount);

        payable(msg.sender).transfer(toReturn);
        delete _sellOrders[_at].bids[msg.sender];
        emit BidCancelled(_at, msg.sender, toReturn);
    }

    /// @notice The function allows anyone to fill sell order.
    /// @param _at The seller order index
    function performBuyOperation(address buyer, uint256 _at)
        external
        nonReentrant
        onlySellerOf(_at)
        validIndex(_at)
    {
        require(
            _sellOrders[_at].status == Status.PENDING,
            "NFTMarketplace: Order Is Filled / Rejected!"
        );
        require(
            block.timestamp <= _sellOrders[_at].expirationTime,
            "NFTMarketplace: Order Is Expired!"
        );

        uint256 price = _sellOrders[_at].bids[buyer];
        uint256 feeAmount = price.mul(feeInBps).div(MAX_FEE);
        _sellOrders[_at].paidFees = feeAmount;
        _sellOrders[_at].status = Status.FILLED;
        delete _sellOrders[_at].bids[buyer];

        nftOnSale.safeTransferFrom(
            address(this),
            buyer,
            _sellOrders[_at].tokenId
        );

            payable(_sellOrders[_at].seller).transfer(price);
        payable(feeReceiver).transfer(feeAmount);
        
        emit OrderFilled(_at, buyer, price);
    }
}
