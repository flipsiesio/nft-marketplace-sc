//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IOptionMintable.sol";
import "./interfaces/IRandomMinter.sol";


/// @title Minter of random cards deck
contract CardRandomMinter is Ownable, IRandomMinter {
    /// @dev Event emitted when a card is minted
    event Minted(uint8 _amount, address indexed _to, string desc);

    /// @dev Factory that mints cards
    IOptionMintable public factory;

    /// @dev Options of cards to be minted
    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    /// @dev Price of mint of a single card
    uint256 public price;


    uint256 public constant MAX_BPS = 10000;
    /// @dev Probability in bps made by golden ratio of 10k
    uint16[5] internal __classProbs = [6180, 2361, 902, 344, 213];
    int256 internal _currentSeed = -125026;

    /// @dev List of items any of which can be picked and minted (others can't)
    mapping(uint8 => bool) public allowedItemsPerRandomMint;
    /// @dev List of addresses that have enough rights to mint cards
    mapping(address => bool) public isMinter;

    constructor(IOptionMintable _factory) {
        factory = _factory;
        allowedItemsPerRandomMint[1] = true;
        allowedItemsPerRandomMint[3] = true;
        allowedItemsPerRandomMint[5] = true;
    }


    /**
     *  @notice Generates card options different from the given one
     *  @param _baseOption The option that is used to generate other options from
     *  @return List of different generated options
     */
    function _getOtherOptions(uint256 _baseOption)
        internal
        pure
        returns (uint8[4] memory)
    {
        if (_baseOption == COLORIZED_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        if (_baseOption == CARDS_WITH_EGGS_OPTION) {
            return [
                COLORIZED_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        if (_baseOption == CARDS_WITH_TEARS_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                COLORIZED_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        if (_baseOption == JOKERS_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                COLORIZED_OPTION,
                RARE_OPTION
            ];
        }
        if (_baseOption == RARE_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                COLORIZED_OPTION
            ];
        }
        revert("CardRandomMinter: Invalid Option That Was Picked Randomly!");
    }

    /**
     * @notice Mints a set of random items (cards)
     * @param _itemsPerRandomMint Number of cards to be minted
     * @param _to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function _mintRandom(
        uint8 _itemsPerRandomMint,
        address _to,
        string memory desc
    ) internal {
        require(
            allowedItemsPerRandomMint[_itemsPerRandomMint],
            "CardRandomMinter: Amount of items to mint is too large. Not allowed!"
        );
        uint8 minted = 0;
        for (uint8 i = 0; i < _itemsPerRandomMint; i++) {
            uint8 randomOption = _getRandomSingleOption(_currentSeed);
            uint8[4] memory _otherOptions = _getOtherOptions(randomOption);
            if (factory.mint(randomOption, _to)) {
                minted++;
            } else {
                for (uint256 j = 0; j < 4; j++) {
                    if (factory.mint(_otherOptions[j], _to)) {
                        minted++;
                        break;
                    }
                }
            }
        }
        emit Minted(minted, _to, desc);
    }

    /**
     * @notice Mints a set of random items (cards) for free
     * @param _itemsPerRandomMint Number of cards to be minted
     * @param _to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function mintRandomFree(
        uint8 _itemsPerRandomMint,
        address _to,
        string memory desc
    ) external {
        require(isMinter[msg.sender], "CardRandomMinter: Caller Is Not a Minter!");
        _mintRandom(_itemsPerRandomMint, _to, desc);
    }

    /**
     * @notice Mints a set of random items (cards) for provided funds
     * @param _itemsPerRandomMint Number of cards to be minted
     */
    function mintRandom(uint8 _itemsPerRandomMint) external payable {
        require(
            msg.value >= price * uint256(_itemsPerRandomMint),
            "notEnoughAmountSent"
        );
        _mintRandom(_itemsPerRandomMint, msg.sender, "");
    }

    /**
     * @notice Returns one random item (card)
     * @param _seed Seed used to increase randomness
     * @return Random card option
     */
    function _getRandomSingleOption(int256 _seed) internal returns (uint8) {
        return _pickRandomSingleOption(_seed, __classProbs);
    }

    /**
     * @notice Generates a random number using current blockchain state
     * @param seed Seed used to increase randomness
     * @return Random number
     */
    function _random(int256 seed) internal returns (uint256) {
        bytes32 res = keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                seed,
                block.difficulty
            )
        );
        _currentSeed = int256(uint(res));
        return uint256(res);
    }

    /**
     * @notice Returns one random item (card)
     * @param seed Seed used to increase randomness
     * @param classProbabilities Probability of card of each class to be picked
     * @return Random card option
     */
    function _pickRandomSingleOption(
        int256 seed,
        uint16[5] memory classProbabilities
    ) internal returns (uint8) {
        uint16 value = uint16(_random(seed) % MAX_BPS);
        // Start at top class (length - 1)
        // skip common (0), we default to it
        // i = classProbabilities.length - 1
        for (uint8 i = 4; i > 0; i--) {
            uint16 probability = classProbabilities[i];
            if (value < probability) {
                return i;
            } else {
                value = value - probability;
            }
        }
        return COLORIZED_OPTION;
    }


    /// @notice Transfers all funds to the owner
    function getRevenue() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Sets the new price for card mint
     * @param _price A new card mint price
     */
    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    /**
     * @notice Gives rights to call card mint function
     * @param who Address to be given rights to mint cards
     * @param status 'True' gives the address the right to mint cards, 'false' - forbids to mint cards
     */
    function setMinter(address who, bool status) external onlyOwner {
        isMinter[who] = status;
    }

    /**
     * @notice Sets the amount of items that can be randomly minted
     * @param _amount The amount of items that can be randomly minted
     * @param _status 'True' allows to mint that amount of cards, 'false' - forbids to mint that amount of cards
     */
    function setAllowedAmountOfItemsPerRandomMint(uint8 _amount, bool _status)
        external
        onlyOwner
    {
        allowedItemsPerRandomMint[_amount] = _status;
    }

    /**
     * @notice Changes the factory that mints cards
     * @param newFactoryAddress An address of a new factory
     */
    function setFactory(address newFactoryAddress) external onlyOwner {
        factory = IOptionMintable(newFactoryAddress);
    }

    /**
     * @notice Changes the seed to change the source of randomness
     * @param _newSeed A new seed to be set
     */
    function setCurrentSeed(int256 _newSeed) external onlyOwner {
        _currentSeed = _newSeed;
    }

    /**
     * @notice Sets probabilty of each class of cards to be randomly picked
     * @param _classProbs List of probabilities for all classes of cards
     */
    function setProbabilitiesForClasses(uint16[5] memory _classProbs)
        public
        onlyOwner
    {
        __classProbs = _classProbs;
    }

    /// @dev Allows the contracts to receive funds from other addresses
    receive() external payable {}
}
