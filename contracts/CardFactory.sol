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
        require(_optionId < 5, "invalidOptionId");
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
        require(startId < endId, "invalidBoundaries");
        _idBoundaries[optionId] = Boundaries({start: startId, end: endId});
    }

    // set CardRandomMinter as option minter
    function setMinterRole(address _minter, bool _status) external onlyOwner {
        isOptionMinter[_minter] = _status;
    }

    function setMintableToken(Card _card) external onlyOwner {
        card = _card;
    }

    function mint(uint8 optionId, address toAddress)
        external
        validOption(optionId)
        returns (bool)
    {
        require(isOptionMinter[msg.sender], "onlyOptionMinter");

        /// @dev Mark the start and the end of boundaries
        uint256 start  = _idBoundaries[optionId].start;
        uint256 end = _idBoundaries[optionId].end;
        for (uint256 i = start; i < end; i++) {
            /// @dev Mint 'end - start' cards
            card.mint(toAddress, i);
            /// @dev Update the start of the boundaries each time
            _idBoundaries[optionId].start = i;
        }

        /// @dev There is no scenario where it should return 'false'
        return true;
    }

    function availableTokens(uint8 optionId) public view returns (uint256) {
        return _idBoundaries[optionId].end - _idBoundaries[optionId].start;
    }
}
