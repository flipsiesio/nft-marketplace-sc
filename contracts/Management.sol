//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './Ownable.sol';
import './ReentrancyGuard.sol';

abstract contract Management is Ownable, ReentrancyGuard {
    uint256 public constant MAX_FEE = 10000;
    uint256 public feeInBps;
    address public feeReceiver;

    uint256 public minExpirationDuration;
    uint256 public maxExpirationDuration;

    uint256 internal _length;

    IERC721 public nftOnSale;

    constructor(address _nftOnSale) public {
        nftOnSale = IERC721(_nftOnSale);
    }

    modifier validIndex(uint256 _at) {
        require(_at < _length, "invalidIndex");
        _;
    }

    modifier validExpirationDuration(uint256 _expirationDuration) {
        require(_expirationDuration >= minExpirationDuration && _expirationDuration <= maxExpirationDuration, "invalidExpirationDuration");
        _;
    }

    modifier onlySellerOf(uint256 _at) {
        require(_sellOrders[_at].seller == msg.sender, "onlySeller");
        _;
    }

    function setFeeReceiver(address _feeReceiver) external onlyOwner {
        feeReceiver = _feeReceiver;
    }

    function setFee(uint256 _fee) external onlyOwner {
        feeInBps = _fee;
    }

    function setMinExpirationDuration(uint256 _minExpirationDuration) external onlyOwner {
        minExpirationDuration = _minExpirationDuration;
    }

    function setMaxExpirationDuration(uint256 _maxExpirationDuration) external onlyOwner {
        maxExpirationDuration = _maxExpirationDuration;
    }

    function() external payable {}
}
