//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './openzeppelin/ownership/Ownable.sol';

import "./interfaces/IOptionMintable.sol";
import "./interfaces/IRandomMinter.sol";

contract CardRandomMinter is Ownable, IRandomMinter {

    event Minted(uint8 _amount, address indexed _to);

    IOptionMintable public factory;

    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    uint256 public price;

    uint256 public constant MAX_BPS = 10000;
    uint16[5] internal __classProbs = [6180, 2361, 902, 344, 213]; // probability in bps made by golden ratio of 10k
    int256 internal _currentSeed = -125026;

    mapping(uint8 => bool) public allowedItemsPerRandomMint;
    mapping(address => bool) public isMinter;

    constructor(IOptionMintable _factory) public {
        factory = _factory;
        allowedItemsPerRandomMint[1] = true;
        allowedItemsPerRandomMint[3] = true;
        allowedItemsPerRandomMint[5] = true;
    }

    function _getOtherOptions(uint256 _baseOption) internal pure returns(uint8[4] memory) {
        if (_baseOption == COLORIZED_OPTION) {
            return [CARDS_WITH_EGGS_OPTION, CARDS_WITH_TEARS_OPTION, JOKERS_OPTION, RARE_OPTION];
        }
        if (_baseOption == CARDS_WITH_EGGS_OPTION) {
            return [COLORIZED_OPTION, CARDS_WITH_TEARS_OPTION, JOKERS_OPTION, RARE_OPTION];
        }
        if (_baseOption == CARDS_WITH_TEARS_OPTION) {
            return [CARDS_WITH_EGGS_OPTION, COLORIZED_OPTION, JOKERS_OPTION, RARE_OPTION];
        }
        if (_baseOption == JOKERS_OPTION) {
            return [CARDS_WITH_EGGS_OPTION, CARDS_WITH_TEARS_OPTION, COLORIZED_OPTION, RARE_OPTION];
        }
        if (_baseOption == RARE_OPTION) {
            return [CARDS_WITH_EGGS_OPTION, CARDS_WITH_TEARS_OPTION, JOKERS_OPTION, COLORIZED_OPTION];
        }
        revert('invalidOptionPickedRandomly');
    }

    function _mintRandom(uint8 _itemsPerRandomMint, address _to) internal {
        require(allowedItemsPerRandomMint[_itemsPerRandomMint], "amountIsNotAllowed");
        uint8 minted = 0;
        for (uint8 i = 0; i < _itemsPerRandomMint; i++) {
            // Mint the ERC721 item(s).
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
        emit Minted(minted, _to);
    }

    function mintRandomFree(uint8 _itemsPerRandomMint, address _to) external {
        require(isMinter[msg.sender], "onlyMinter");
        _mintRandom(_itemsPerRandomMint, _to);
    }

    function mintRandom(uint8 _itemsPerRandomMint) external payable {
        require(msg.value >= price * uint256(_itemsPerRandomMint), "notEnoughAmountSent");
        _mintRandom(_itemsPerRandomMint, msg.sender);
    }

    function _getRandomSingleOption(int256 _seed) internal view returns(uint8) {
        return _pickRandomSingleOption(
          _seed,
          __classProbs
        );
    }

    function _random(int256 seed) internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, seed, block.difficulty)));
    }

    function _pickRandomSingleOption(
        int256 seed,
        uint16[5] memory classProbabilities
    ) internal view returns(uint8) {
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

    function getRevenue() external onlyOwner {
        owner.transfer(address(this).balance);
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMinter(address who, bool status) external onlyOwner {
        isMinter[who] = status;
    }

    function setAllowedAmountOfItemsPerRandomMint(uint8 _amount, bool _status) external onlyOwner {
        allowedItemsPerRandomMint[_amount] = _status;
    }

    function setFactory(address newFactoryAddress) external onlyOwner {
        factory = IOptionMintable(newFactoryAddress);
    }

    function setCurrentSeed(int256 _newSeed) external onlyOwner {
        _currentSeed = _newSeed;
    }

    function setProbabilitiesForClasses(uint16[5] memory _classProbs) public onlyOwner {
        __classProbs = _classProbs;
    }

    function() external payable {}

}
