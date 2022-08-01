//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Card.sol";
import "./interfaces/IOptionMintable.sol";

contract CardFactory is Ownable, IOptionMintable {
    mapping(address => bool) public isOptionMinter;

    Card public card;

    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    struct Boundaries {
        uint256 start;
        uint256 end;
    }

    // option id => interval of ids in class (option)
    mapping(uint8 => Boundaries) internal _idBoundaries;

    modifier validOption(uint8 _optionId) {
        require(_optionId < 5, "CardFactory: Invalid Option ID!");
        _;
    }

    constructor(Card _card) {
        card = _card;
        isOptionMinter[msg.sender] = true;
    }

    // SET UP BOUNDARIES FOR EVERY TOKENS BEFORE DEPLOY!
    function setIdBoundaryForOption(
        uint8 optionId,
        uint256 startId,
        uint256 endId
    ) external onlyOwner validOption(optionId) {
        // WARNING: BOUNDARY COLLISION MUST BE CHECKED ON ADMIN SIDE OFFCHAIN!!!
        require(startId < endId, "CardFactory: Invalid Boundaries!");
        _idBoundaries[optionId] = Boundaries({start: startId, end: endId});
    }

    // Set CardRandomMinter instance as minter
    function setOptionMinter(address _minter, bool _status) external onlyOwner {
        isOptionMinter[_minter] = _status;
    }

    function setMintableToken(Card _card) external onlyOwner {
        card = _card;
    }

    function getMintableToken() public view returns(address) {
        return address(card);
    }

    /// @dev Mints one card at a time but not more than _idBoundaries[optionId].end
    function mint(uint8 optionId, address toAddress)
        external
        validOption(optionId)
        returns (bool)
    {
        require(isOptionMinter[msg.sender], "CardFactory: Caller Is Not an Option Minter!");
        require(_idBoundaries[optionId].start < _idBoundaries[optionId].end, "CardFactory: No More Cards Are Left to Mint!");
        for (uint256 i = _idBoundaries[optionId].start; i < _idBoundaries[optionId].end; i++) {
            card.mint(toAddress, _idBoundaries[optionId].start);
            _idBoundaries[optionId].start = i + 1;
            return true;
        }

        return false;
    }

    function availableTokens(uint8 optionId) public view returns (uint256) {
        return _idBoundaries[optionId].end - _idBoundaries[optionId].start;
    }
}
