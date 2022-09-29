//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Card.sol";
import "./interfaces/IOptionMintable.sol";


/// @title Poker card minting factory
contract CardFactory is Ownable, IOptionMintable {
    
    /// @dev List of addresses with rights of option minters
    mapping(address => bool) public isOptionMinter;

    /// @dev A card to be minted
    Card public card;

    /// @dev Special cards options
    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    /// @dev Minimum and maximum number of cards to be minted
    struct Boundaries {
        uint256 start;
        uint256 end;
    }

    /// @dev Each card option has a limited number of cards to be minted
    mapping(uint8 => Boundaries) internal _idBoundaries;

    modifier validOption(uint8 _optionId) {
        require(_optionId < 5, "CardFactory: Invalid Option ID!");
        _;
    }

    /// @dev Caller gets the option minter's rights
    constructor(Card _card) {
        card = _card;
        isOptionMinter[msg.sender] = true;
    }

    /**
     * @notice Sets boundaries for card options
     * @notice Boundaries MUST be set before contract deploy
     * @param optionId Number of card option
     * @param startId The lower boundary for option
     * @param endId The upper boundary for option
     */
    function setIdBoundaryForOption(
        uint8 optionId,
        uint256 startId,
        uint256 endId
    ) external onlyOwner validOption(optionId) {
        /// @dev Boundary collisions must be checked offchain!
        require(startId < endId, "CardFactory: Invalid Boundaries!");
        _idBoundaries[optionId] = Boundaries({start: startId, end: endId});
    }

    /**
     * @notice Gives the '_minter' address a right to call factory 'mint' function (that calls card 'mint' function)
     * @notice Usually you have to call this function oт CardRandomMinter instance
     * @param _minter The address that gets the rights to mint cards
     * @param _status If 'true' - allows to mint cards, if 'false - forbids to do that
     */
    function setOptionMinter(address _minter, bool _status) external onlyOwner {
        isOptionMinter[_minter] = _status;
    }

    /**
     * @notice Sets token for factory to mint
     * @param _card Address of the deployed token
     */
    function setMintableToken(Card _card) external onlyOwner {
        card = _card;
    }
    
    /**
     * @notice Shows the token thas is set to be minted by factory
     * @return Address of the token that is set to be minted
     */
    function getMintableToken() public view returns(address) {
        return address(card);
    }
    
    /**
     * @notice Mints a card with provided card option ID
     * @dev Mints one card at a time but not more than _idBoundaries[optionId].end
     * @param optionId ID of card option
     * @param toAddress Address of receiver of minted card
     * @return 'True' if mint was successful, 'false' - if mint failed
     */
    function mint(uint8 optionId, address toAddress)
        external
        validOption(optionId)
        returns (bool)
    {
        require(isOptionMinter[msg.sender], "CardFactory: Caller Is Not an Option Minter!");

        // If no tokens available in group we need to return false
        // This way random minter will try to mint tokens of other groups
        if(_idBoundaries[optionId].start >= _idBoundaries[optionId].end)  {
            return false;
        }

        // start will be equal to end if group fully minted, so we need to check it before
        require(card.ownerOf(_idBoundaries[optionId].start) == address(0), string.concat(
            "CardFactory: Invalid Boundaries! Token ID ",
            Strings.toString(_idBoundaries[optionId].start)
        ));

        card.mint(toAddress, _idBoundaries[optionId].start);
        _idBoundaries[optionId].start += 1;
        return true;
    }

    /**
     * @notice Shows the number of cards of specific option that can be minted
     * @param optionId ID of card option
     * @return Number of tokens that can be minted
     */
    function availableTokens(uint8 optionId) public view returns (uint256) {
        return _idBoundaries[optionId].end - _idBoundaries[optionId].start;
    }
}
