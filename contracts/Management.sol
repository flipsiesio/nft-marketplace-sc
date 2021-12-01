//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './Ownable.sol';
import './ReentrancyGuard.sol';
import './interfaces/IERC721.sol';

/// @title A contract for holding management functions and modifiers.
/// @author Integral Team
contract Management is Ownable, ReentrancyGuard {

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
    /// @param _nftOnSale The NFT which could be sold in marketplace or auction
    constructor(address _nftOnSale) public {
        nftOnSale = IERC721(_nftOnSale);
    }

    /// @notice This custom modifier is to validate index of either sell order or auction
    /// @param _at An index in the mapping of auctions or sell orders
    modifier validIndex(uint256 _at) {
        require(_at < _length, "invalidIndex");
        _;
    }

    /// @notice This custom modifier is to validate expiration duration of either sell order or auction
    /// @param _expirationDuration The duration which about to be used in auction or sell order
    modifier validExpirationDuration(uint256 _expirationDuration) {
        require(_expirationDuration >= minExpirationDuration && _expirationDuration <= maxExpirationDuration, "invalidExpirationDuration");
        _;
    }

    /// @notice A standard setter for the fee receiver address which available only for user
    /// @param _feeReceiver The new fee receiver address
    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    /// @notice A standard setter for the fee BPS amount which available only for user
    /// @param _fee The new amount of fee in BPS
    function setFee(uint256 _fee) external onlyOwner {
        feeInBps = _fee;
    }

    /// @notice A standard setter for the minimum expiration duration which available only for user
    /// @param _minExpirationDuration The new minimum expiration duration in seconds
    function setMinExpirationDuration(uint256 _minExpirationDuration) external onlyOwner {
        minExpirationDuration = _minExpirationDuration;
    }

    /// @notice A standard setter for the maximum expiration duration which available only for user
    /// @param _maxExpirationDuration The new maximum expiration duration in seconds
    function setMaxExpirationDuration(uint256 _maxExpirationDuration) external onlyOwner {
        maxExpirationDuration = _maxExpirationDuration;
    }

    /// @notice Default fallback function which allows the contract to accept ether
    function() external payable {}
}
