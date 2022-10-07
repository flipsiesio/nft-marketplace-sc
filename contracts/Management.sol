//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title A contract for holding management functions and modifiers.
/// @author Integral Team
contract Management is Ownable, ReentrancyGuard, ERC721Holder {
    // This enumeration is describing different statuses of the different orders
    enum Status {
        PENDING,
        FILLED,
        REJECTED,
        EXPIRED
    }

    /// @notice This is max of the basis points
    uint256 public constant MAX_FEE = 10000;

    /// @notice This is a fee amount in basis points using in sell orders and auctions
    uint256 public feeInBps;

    /// @notice This is the address which will receive any kind of fees (either in marketplace or auction)
    address public feeReceiver;

    /// @notice This is the lower border of the expiration duration that used in orders of marketplace and in auctions
    uint256 public minExpirationDuration;

    /// @notice This is the upper border of the expiration duration that used in orders of marketplace and in auctions
    uint256 public maxExpirationDuration;

    /// @notice This is the amount of either sell orders or auctions
    uint256 internal _length;

    /// @notice This is a NFT which could be sold in marketplace or auction
    IERC721 public nftOnSale;

    /// @notice This is a standard constructor with one argument
    /// @param nftOnSale_ The NFT which could be sold in marketplace or auction
    constructor(
        address nftOnSale_,
        address feeReceiver_,
        uint256 minExpirationDuration_,
        uint256 maxExpirationDuration_,
        uint256 feeInBps_
    ) {
        nftOnSale = IERC721(nftOnSale_);
        feeReceiver = feeReceiver_;
        minExpirationDuration = minExpirationDuration_;
        maxExpirationDuration = maxExpirationDuration_;
        feeInBps = feeInBps_;
    }

    /// @notice This custom modifier is to validate index of either sell order or auction
    /// @param at An index in the mapping of auctions or sell orders
    modifier validIndex(uint256 at) {
        require(at < _length, "invalidIndex");
        _;
    }

    /// @notice This custom modifier is to validate expiration duration of either sell order or auction
    /// @param expirationDuration The duration which about to be used in auction or sell order
    modifier validExpirationDuration(uint256 expirationDuration) {
        require(
            expirationDuration >= minExpirationDuration &&
                expirationDuration <= maxExpirationDuration,
            "invalidExpirationDuration"
        );
        _;
    }

    /// @notice A standard setter for the working NFT which available only for user
    /// @param newNFTOnSale The new NFT token address
    function setWorkingNFT(address newNFTOnSale) external onlyOwner {
        nftOnSale = IERC721(newNFTOnSale);
    }

    /// @notice A standard setter for the fee receiver address which available only for user
    /// @param feeReceiver_ The new fee receiver address
    function setFeeReceiver(address feeReceiver_) external onlyOwner {
        feeReceiver = feeReceiver_;
    }

    /// @notice A standard setter for the fee BPS amount which available only for user
    /// @param fee The new amount of fee in BPS
    function setFee(uint256 fee) external onlyOwner {
        feeInBps = fee;
    }

    /// @notice A standard setter for the minimum expiration duration which available only for user
    /// @param minExpirationDuration_ The new minimum expiration duration in seconds
    function setMinExpirationDuration(uint256 minExpirationDuration_)
        external
        onlyOwner
    {
        minExpirationDuration = minExpirationDuration_;
    }

    /// @notice A standard setter for the maximum expiration duration which available only for user
    /// @param maxExpirationDuration_ The new maximum expiration duration in seconds
    function setMaxExpirationDuration(uint256 maxExpirationDuration_)
        external
        onlyOwner
    {
        maxExpirationDuration = maxExpirationDuration_;
    }

    /// @notice Default fallback function which allows the contract to accept ether
    receive() external payable {}
}
