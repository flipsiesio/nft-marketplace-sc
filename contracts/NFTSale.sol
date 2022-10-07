//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./Management.sol";

/// @title A contract of the marketplace.
/// @author Integral Team
contract NFTSale is Management {
    using SafeMath for uint256;

    /// @notice This event is fired when seller create the sell order
    event OrderCreated(
        uint256 indexed tokenId,
        uint256 indexed orderIndex,
        address seller,
        uint256 expirationTime
    );

    /// @notice This event is fired when seller fill the sell order
    event OrderFilled(uint256 indexed orderIndex, address buyer);

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
    /// @param at The index of the given sell roder in which seller is checked
    modifier onlySellerOf(uint256 at) {
        require(_sellOrders[at].seller == msg.sender, "NFTSale: Caller Is Not a Seller!");
        _;
    }

    constructor(
        address _nftOnSale,
        address feeReceiver,
        uint256 minExpirationDuration,
        uint256 maxExpirationDuration,
        uint256 feeInBps
    )
        Management(
            _nftOnSale,
            feeReceiver,
            minExpirationDuration,
            maxExpirationDuration,
            feeInBps
        )
    {}

    /// @notice The standard getter to return an amount of the sell orders
    /// @return Amount of the sell orders
    function getSellOrdersAmount() external view returns (uint256) {
        return _length;
    }

    /// @notice The standard getter to return a token ID of the given sell order
    /// @param at The index of the sell order
    /// @return The ID of the selling token
    function getSellOrderTokenId(uint256 at)
        external
        view
        validIndex(at)
        returns (uint256)
    {
        return _sellOrders[at].tokenId;
    }

    /// @notice The standard getter to return a seller address of the given sell order
    /// @param at The index of the sell order
    /// @return The seller address of the sell order
    function getSellOrderSeller(uint256 at)
        external
        view
        validIndex(at)
        returns (address)
    {
        return _sellOrders[at].seller;
    }

    /// @notice The standard getter to return a price in ETH of the given sell order
    /// @param at The index of the sell order
    /// @return Price in ETH
    function getSellOrderPrice(uint256 at)
        external
        view
        validIndex(at)
        returns (uint256)
    {
        return _sellOrders[at].price;
    }

    /// @notice The standard getter to return a fees to pay amount of the given sell order
    /// @param at The index of the sell order
    /// @return Amount fees to pay
    function getSellOrderFeesPaid(uint256 at)
        external
        view
        validIndex(at)
        returns (uint256)
    {
        return _sellOrders[at].paidFees;
    }

    /// @notice The standard getter to return an expiration time of the given sell order
    /// @param at The index of the sell order
    /// @return Expiration timestamp in future
    function getSellOrderExpirationTime(uint256 at)
        external
        view
        validIndex(at)
        returns (uint256)
    {
        return _sellOrders[at].expirationTime;
    }

    /// @notice The standard getter to return a status of the given sell order
    /// @param at The index of the auction
    /// @return Status enumeration member as uint256
    function getSellOrderStatus(uint256 at)
        external
        view
        validIndex(at)
        returns (uint256)
    {
        return uint256(_sellOrders[at].status);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param at The index of the sell order
    function getBackFromSale(uint256 at) external onlySellerOf(at) {
        require(_sellOrders[at].status == Status.PENDING, "NFTSale: Possible Only While Pending!");
        
        if (block.timestamp <= _sellOrders[at].expirationTime) {
            _sellOrders[at].status = Status.REJECTED;
        } else {
            _sellOrders[at].status = Status.EXPIRED;
        }
        
        nftOnSale.safeTransferFrom(
            address(this),
            msg.sender,
            _sellOrders[at].tokenId
        );
        
        emit OrderRejected(at);
    }

    /// @notice The function cancel the sell order and return the token in the sell order to the seller.
    /// @param nftToSell The token ID to sell through sell order
    /// @param price The price of the sell order
    /// @param expirationDuration The duration of the sell order, and when it passed the sell order could not be filled without restarting of the sell order.
    function acceptTokenToSell(
        uint256 nftToSell,
        uint256 price,
        uint256 expirationDuration
    ) external validExpirationDuration(expirationDuration) {
        nftOnSale.safeTransferFrom(msg.sender, address(this), nftToSell);
        _sellOrders[_length] = SellOrder({
            tokenId: nftToSell,
            seller: msg.sender,
            price: price,
            status: Status.PENDING,
            expirationTime: block.timestamp.add(expirationDuration),
            paidFees: 0
        });
        emit OrderCreated(
            nftToSell,
            _length,
            msg.sender,
            block.timestamp.add(expirationDuration)
        );
        _length = _length.add(1);
    }

    /// @notice The function allows seller to change price.
    /// @param at The seller order index
    /// @param price The new price for the sell order
    function setPriceFor(uint256 at, uint256 price)
        external
        validIndex(at)
        onlySellerOf(at)
    {
        _sellOrders[at].price = price;
    }

    /// @notice The function allows seller continue selling by expanding the expiration time of the sell order.
    /// @param at The seller order index
    /// @param expirationTime The new expiration time for the sell order
    function setExpirationTimeFor(uint256 at, uint256 expirationTime)
        external
        validIndex(at)
        onlySellerOf(at)
    {
        require(
            _sellOrders[at].expirationTime <= expirationTime,
            "NFTSale: onlyFutureTimeAllowed!"
        );
        _sellOrders[at].expirationTime = expirationTime;
    }

    /// @notice The function allows anyone to fill sell order.
    /// @param at The seller order index
    function buy(uint256 at) external payable nonReentrant validIndex(at) {
        uint256 price = _sellOrders[at].price;
        uint256 feeAmount = price.mul(feeInBps).div(MAX_FEE);
        require(msg.value >= price.add(feeAmount), "NFTSale: Not Enough Funds!");
        require(
            _sellOrders[at].status == Status.PENDING,
            "NFTSale: Order Is Filled / Rejected!"
        );
        require(
            block.timestamp <= _sellOrders[at].expirationTime,
            "NFTSale: Order Is Expired!"
        );

        _sellOrders[at].paidFees = feeAmount;
        _sellOrders[at].status = Status.FILLED;

        nftOnSale.safeTransferFrom(
            address(this),
            msg.sender,
            _sellOrders[at].tokenId
        );
        payable(_sellOrders[at].seller).transfer(_sellOrders[at].price);
        payable(feeReceiver).transfer(feeAmount);
        
        emit OrderFilled(at, msg.sender);
    }
}
