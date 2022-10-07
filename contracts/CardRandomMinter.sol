//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IOptionMintable.sol";
import "./interfaces/ICardRandomMinter.sol";


/// @title Minter of random cards deck
contract CardRandomMinter is Ownable, ICardRandomMinter {
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


    /// @dev The list of supported tokens to iterate over
    address[] internal _supportedTokens;
    /// @dev The map of supported tokens to save gas
    mapping(address => bool) _supportedTokensMap;
    /// @dev The list of mint price in each of supported tokens
    mapping(address => uint256) internal _pricesInTokens;

    uint256 public constant MAX_BPS = 10000;
    /// @dev Probability in bps made by golden ratio of 10k
    uint16[5] internal __classProbs = [6180, 2361, 902, 344, 213];
    uint256 internal _currentSeed = 125026;

    /// @dev List of items any of which can be picked and minted (others can't)
    mapping(uint8 => bool) public allowedItemsPerRandomMint;
    /// @dev List of addresses that have enough rights to mint cards
    mapping(address => bool) public isMinter;

    constructor(IOptionMintable _factory) {
        factory = _factory;
        allowedItemsPerRandomMint[1] = true;
        allowedItemsPerRandomMint[3] = true;
        allowedItemsPerRandomMint[5] = true;
        // These addresses must be supported by default
        // TODO move it to JSON file
        // TODO zero address (native) is not a must have, it can be either supported or not
        // native
        _supportedTokens.push(address(0));
        _supportedTokensMap[address(0)] = true;
        // ETH
        _supportedTokens.push(0x1249C65AfB11D179FFB3CE7D4eEDd1D9b98AD006);
        _supportedTokensMap[0x1249C65AfB11D179FFB3CE7D4eEDd1D9b98AD006] = true;
        // BNB
        _supportedTokens.push(0x185a4091027E2dB459a2433F85f894dC3013aeB5);
        _supportedTokensMap[0x185a4091027E2dB459a2433F85f894dC3013aeB5] = true;
        // TRX
        _supportedTokens.push(0xEdf53026aeA60f8F75FcA25f8830b7e2d6200662);
        _supportedTokensMap[0x185a4091027E2dB459a2433F85f894dC3013aeB5] = true;
        // USDT (Ethereum)
        _supportedTokens.push(0xE887512ab8BC60BcC9224e1c3b5Be68E26048B8B);
        _supportedTokensMap[0xE887512ab8BC60BcC9224e1c3b5Be68E26048B8B] = true;
        // USDC (Ethereum)
        _supportedTokens.push(0xAE17940943BA9440540940DB0F1877f101D39e8b);
        _supportedTokensMap[0xAE17940943BA9440540940DB0F1877f101D39e8b] = true;
    }

    /** 
     * @notice Checks if provided token is supported
     * @param tokenAddress The address of the token to check
     * @return True if token is supported. False - if token is not supported.
     */
    function isSupported(address tokenAddress) public view returns(bool) {
        return _supportedTokensMap[tokenAddress];
    }

    /**
     * @notice Adds a supported token to pay for mint in
     * @param tokenAddress The address of the token to add
     */
    function addSupportedToken(address tokenAddress) public onlyOwner {
        // It shouldn't be added yet. Cleaner usage
        require(!isSupported(tokenAddress), "CardRandomMinter: token has already been added!");
        _supportedTokens.push(tokenAddress);
        _supportedTokensMap[tokenAddress] = true;
    }

    /**
     * @notice Removes a supported token to pay for mint in
     * @param tokenAddress The address of the token to remove
     */
    function removeSupportedToken(address tokenAddress) public onlyOwner {
        // It shouldn't be removed yet. Cleaner usage
        require(isSupported(tokenAddress), "CardRandomMinter: trying to remove non-existent token!");
        _supportedTokensMap[tokenAddress] = false;
        // There should not be too many chains, so its ok to iterate through the array
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            if (_supportedTokens[i] == tokenAddress) {
                delete _supportedTokens[i];
            }
        }

    }


    /**
     * @notice Returns the number of supported tokens
     * @return The number of supported tokens
     */
    function getSupportedLength() public view returns(uint256) {
        return _supportedTokens.length;
    }

    /**
     * @notice Sets the mint price for each supported token
     * @param tokenAddress The address of the token to set the price in
     * @param priceInTokens The price in tokens to set
     *        NOTE: In UI the `priceInTokens` value is divided in `decimals` (10^18 im most cases)
     *        For example, to set the price of 0.5 BTTC (native token) per token, you have to set `priceInTokens` to 0.5 * 10^18 (in wei)
     *        To set the price of 0.5 USDT per token, you have to set `priceInTokens` to 0.5 * 10^18 as well
     * TODO not sure about ERC20 here. Can we spend a half of ERC20???
     */
    function setMintPrice(address tokenAddress, uint256 priceInTokens) public onlyOwner {
        require(isSupported(tokenAddress), "CardRandomMinter: token is not supported!");
        require(priceInTokens > 0, "CardRandomMinter: price can not be zero!");
        _pricesInTokens[tokenAddress] = priceInTokens;
    }

    /**
     * @notice Gets the card mint price in provided tokens
     * @param tokenAddress The address of the token to check the card mint price in
     * @return A card mint price. Should be divided by `demicals` (18 in most cases) for UI
     */
    function getMintPrice(address tokenAddress) public view returns(uint256) {  
        return _pricesInTokens[tokenAddress];
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
     * @param _numCards Number of cards to be minted
     * @param _to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function _mintRandom(
        uint8 _numCards,
        address _to,
        string memory desc
    ) internal {
        require(
            allowedItemsPerRandomMint[_numCards],
            "CardRandomMinter: Amount of items to mint is too large. Not allowed!"
        );
        uint8 minted = 0;
        for (uint8 i = 0; i < _numCards; i++) {
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
     * @param _numCards Number of cards to be minted
     * @param _to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function mintRandomFree(
        uint8 _numCards,
        address _to,
        string memory desc
    ) external {
        require(isMinter[msg.sender], "CardRandomMinter: Caller Is Not a Minter!");
        _mintRandom(_numCards, _to, desc);
    }

    /**
     * @notice Mints a set of random items (cards) for provided funds
     * @param _numCards Number of cards to be minted
     * @param _tokenToPay Address of the token that will be payed to mint a card
     *                    NOTE: Zero address for native tokens
     */            
    function mintRandom(uint8 _numCards, address _tokenToPay) external payable {
        require(_numCards > 0, "CardRandomMinter: can not mint zero cards!");
        require(isSupported(_tokenToPay), "CardRandomMinter: token is not supported!");
        if (_tokenToPay == address(0)) {
            // If user wishes to pay in native tokens, he should send them with the transaction
            require( 
                msg.value >= _pricesInTokens[_tokenToPay] * uint256(_numCards), 
                "CardRandomMinter: not enough native tokens were provided to pay for mint!"
            );
        } else {
            // If user wishes to pay in ERC20 tokens he first needs to call this token's `approve` method to 
            // allow `CardRandomMinter` to transfer his tokens
            IERC20(_tokenToPay).transferFrom(msg.sender, address(this), _pricesInTokens[_tokenToPay]);

        }
        _mintRandom(_numCards, msg.sender, "");

    }

    /**
     * @notice Returns one random item (card)
     * @param _seed Seed used to increase randomness
     * @return Random card option
     */
    function _getRandomSingleOption(uint256 _seed) internal returns (uint8) {
        return _pickRandomSingleOption(_seed, __classProbs);
    }

    /**
     * @notice Generates a random number using current blockchain state
     * @param seed Seed used to increase randomness
     * @return Random number
     */
    function _random(uint256 seed) internal returns (uint256) {
        uint256 res = uint256(keccak256(
            abi.encodePacked(
                blockhash(block.number - 1),
                msg.sender,
                seed,
                block.difficulty
            )
        ));
        _currentSeed = res;
        return res;
    }

    /**
     * @notice Returns one random item (card)
     * @param seed Seed used to increase randomness
     * @param classProbabilities Probability of card of each class to be picked
     * @return Random card option
     */
    function _pickRandomSingleOption(
        uint256 seed,
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
     * @notice Gives rights to call card mint function
     * @param who Address to be given rights to mint cards
     * @param status 'True' gives the address the right to mint cards, 'false' - forbids to mint cards
     */
    function setMinterRole(address who, bool status) external onlyOwner {
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
    function setCurrentSeed(uint256 _newSeed) external onlyOwner {
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
