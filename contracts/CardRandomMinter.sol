//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./interfaces/IOptionMintable.sol";
import "./interfaces/ICardRandomMinter.sol";


/// @title Minter of random cards deck
contract CardRandomMinter is Ownable, ICardRandomMinter {
    /// @dev Event emitted when a card is minted
    event Minted(uint8 amount, address indexed to , string desc);

    /// @dev Factory that mints cards
    IOptionMintable public factory;

    /// @dev Options of cards to be minted
    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    /// @dev Two addresses of admins
    mapping(address => bool) private _admins;

    /// @dev Allows only admins to call functions with this modifier
    ///      Owner can add/remove admins
    modifier onlyAdmin() {
         require(_admins[msg.sender], "CardRandomMinter: caller is not an admin!");
         _;
    }

    /// @dev The list of supported tokens to iterate over
    address[] internal _supportedTokens;
    /// @dev The map of supported tokens to save gas
    mapping(address => bool) internal _supportedTokensMap;
    /// @dev The list of mint price in each of supported tokens
    mapping(address => uint256) internal pricesInTokens;

    uint256 public constant MAX_BPS = 10000;
    /// @dev Probability in bps made by golden ratio of 10k
    uint16[5] internal _classProbs = [6180, 2361, 902, 344, 213];
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
        // Two admin addresses from BTTC Mainnet are initialized
        addAdmin(0x1Ae3F0A9f468c4211d34f9018c24be148FeC9b9d);
        addAdmin(0x59BB5F8B697c642fE8CAC6195c6803f4a4809089);
    }

    /// @dev Allows the contracts to receive funds from other addresses
    receive() external payable {}

    /**
     * @notice Checks if provided address is an admin
     * @param adminAddress The address to check
     * @return True if address is an admin, false - if address is not an admin
     */
    function isAdmin(address adminAddress) public view returns(bool) {
        return _admins[adminAddress];
    }

    /**
     * @notice Adds a new admin address
     * @param newAdmin The address of the new admin to set
     */
    function addAdmin(address newAdmin) public onlyOwner {
        require(!isAdmin(newAdmin), "CardRandomMinter: address is already an admin!");
        require(newAdmin != address(0), "CardRandomMinter: zero address can not be an admin!");
        _admins[newAdmin] = true;
    }

    /** 
     * @notice Removes an address from admin list
     * @param adminAddress The address to remove from admin list
     */
    function removeAdmin(address adminAddress) public onlyOwner {
        require(isAdmin(adminAddress), "CardRandomMinter: no such admin!");
        _admins[adminAddress] = false;
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
    function addSupportedToken(address tokenAddress) public onlyAdmin {
        // It shouldn't be added yet. Cleaner usage
        require(!isSupported(tokenAddress), "CardRandomMinter: token has already been added!");
        _supportedTokens.push(tokenAddress);
        _supportedTokensMap[tokenAddress] = true;
    }

    /**
     * @notice Removes a supported token to pay for mint in
     * @param tokenAddress The address of the token to remove
     */
    function removeSupportedToken(address tokenAddress) public onlyAdmin {
        // It shouldn't be removed yet. Cleaner usage
        require(isSupported(tokenAddress), "CardRandomMinter: token is not supported!");
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
     *        For example, if a user wants to set the price of 0.5 BTTC (native token) per token, then `priceInTokens` parameter 
     *        should be eqaul to 0.5 * 10^18
     *        To set the price of 0.5 USDT per token, you have to set `priceInTokens` to 0.5 * 10^18 as well
     */
    function setMintPrice(address tokenAddress, uint256 priceInTokens) public onlyAdmin {
        require(isSupported(tokenAddress), "CardRandomMinter: token is not supported!");
        require(priceInTokens > 0, "CardRandomMinter: price can not be zero!");
        pricesInTokens[tokenAddress] = priceInTokens;
    }

    /**
     * @notice Gets the card mint price in provided tokens
     * @param tokenAddress The address of the token to check the card mint price in
     * @return A card mint price. Should be divided by `demicals` (18 in most cases) for UI
     */
    function getMintPrice(address tokenAddress) public view returns(uint256) {  
        require(isSupported(tokenAddress), "CardRandomMinter: token is not supported!");
        return pricesInTokens[tokenAddress];
    }


   /**
     * @notice Gives rights to call card mint function
     * @param who Address to be given rights to mint cards
     * @param status 'True' gives the address the right to mint cards, 'false' - forbids to mint cards
     */
    function setMinterRole(address who, bool status) external onlyAdmin {
        isMinter[who] = status;
    }

    /**
     * @notice Sets the amount of items that can be randomly minted
     * @param amount The amount of items that can be randomly minted
     * @param status 'True' allows to mint that amount of cards, 'false' - forbids to mint that amount of cards
     */
    function setAllowedAmountOfItemsPerRandomMint(uint8 amount, bool status)
        external
        onlyAdmin
    {
        require(amount > 0, "CardRandomMinter: can not mint zero cards!");
        allowedItemsPerRandomMint[amount] = status;
    }

    /**
     * @notice Changes the factory that mints cards
     * @param newFactoryAddress An address of a new factory
     */
    function setFactory(address newFactoryAddress) external onlyAdmin {
        require(newFactoryAddress != address(0), "CardRandomMinter: factory can not have a zero address!");
        factory = IOptionMintable(newFactoryAddress);
    }

    /**
     * @notice Changes the seed to change the source of randomness
     * @param newSeed A new seed to be set
     */
    function setCurrentSeed(uint256 newSeed) external onlyAdmin {
        _currentSeed = newSeed;
    }

    /**
     * @notice Sets probabilty of each class of cards to be randomly picked
     * @param classProbs List of probabilities for all classes of cards
     */
    function setProbabilitiesForClasses(uint16[5] memory classProbs)
        public
        onlyAdmin
    {
        _classProbs = classProbs;
    }

    /**
     *  @notice Generates card options different from the given one
     *  @param baseOption The option that is used to generate other options from
     *  @return List of different generated options
     */
    function _getOtherOptions(uint256 baseOption)
        internal
        pure
        returns (uint8[4] memory)
    {   
        // 0
        if (baseOption == COLORIZED_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        // 1
        if (baseOption == CARDS_WITH_EGGS_OPTION) {
            return [
                COLORIZED_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        // 2
        if (baseOption == CARDS_WITH_TEARS_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                COLORIZED_OPTION,
                JOKERS_OPTION,
                RARE_OPTION
            ];
        }
        // 3
        if (baseOption == JOKERS_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                COLORIZED_OPTION,
                RARE_OPTION
            ];
        }
        // 4
        if (baseOption == RARE_OPTION) {
            return [
                CARDS_WITH_EGGS_OPTION,
                CARDS_WITH_TEARS_OPTION,
                JOKERS_OPTION,
                COLORIZED_OPTION
            ];
        }
        revert("CardRandomMinter: invalid option that was picked randomly!");
    }

    /**
     * @notice Returns one random item (card)
     * @param seed Seed used to increase randomness
     * @return Random card option
     */
    function _getRandomSingleOption(uint256 seed) internal returns (uint8) {
        return _pickRandomSingleOption(seed, _classProbs);
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

    /**
     * @notice Mints a set of random items (cards)
     * @param numCards Number of cards to be minted
     * @param to  Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function _mintRandom(
        uint8 numCards,
        address to,
        string memory desc
    ) internal {
        require(
            allowedItemsPerRandomMint[numCards],
            "CardRandomMinter: this exact amount of tokens is not allowed to be minted!"
        );
        uint8 minted = 0;
        for (uint8 i = 0; i < numCards; i++) {
            uint8 randomOption = _getRandomSingleOption(_currentSeed);
            uint8[4] memory _otherOptions = _getOtherOptions(randomOption);
            if (factory.mint(randomOption, to)) {
                minted++;
            } else {
                for (uint256 j = 0; j < 4; j++) {
                    if (factory.mint(_otherOptions[j], to )) {
                        minted++;
                        break;
                    }
                }
            }
        }
        emit Minted(minted, to , desc);
    }

    /**
     * @notice Mints a set of random items (cards) for free
     * @param numCards Number of cards to be minted
     * @param to Receiver of minted cards
     * @param desc Description used in emitted event
     */
    function mintRandomFree(
        uint8 numCards,
        address to ,
        string memory desc
    ) external {
        require(isMinter[msg.sender], "CardRandomMinter: caller is not a minter!");
        _mintRandom(numCards, to, desc);
    }

    /**
     * @notice Mints a set of random items (cards) for provided funds
     * @param numCards Number of cards to be minted
     * @param tokenToPay Address of the token that will be paid to mint a card
     *                    NOTE: Zero address for native tokens
     */            
    function mintRandom(uint8 numCards, address tokenToPay) external payable {
        require(numCards > 0, "CardRandomMinter: can not mint zero cards!");
        require(isSupported(tokenToPay), "CardRandomMinter: token is not supported!");
        require(pricesInTokens[tokenToPay] != 0, "CardRandomMinter: mint price was not set for this token!");
        if (tokenToPay == address(0)) {
            // If user wishes to pay in native tokens, he should send them with the transaction
            require( 
                msg.value >= pricesInTokens[tokenToPay] * uint256(numCards), 
                "CardRandomMinter: not enough native tokens were provided to pay for mint!"
            );
        } else {
            // If user wishes to pay in ERC20 tokens he first needs to call this token's `approve` method to 
            // allow `CardRandomMinter` to transfer his tokens
            require(
                IERC20(tokenToPay).balanceOf(msg.sender) >= pricesInTokens[tokenToPay] * uint256(numCards),
                "CardRandomMinter: not enough ERC20 tokens to pay for the mint!"
            );
            IERC20(tokenToPay).transferFrom(msg.sender, address(this), pricesInTokens[tokenToPay] * uint256(numCards));

        }
        _mintRandom(numCards, msg.sender, "");

    }


    /// @notice Transfers all funds to the owner
    function getRevenue() external onlyAdmin {
        for (uint256 i = 0; i < _supportedTokens.length; i++) {
            address token = _supportedTokens[i];
            if (token == address(0)) {
                // Transfer all native tokens
                payable(owner()).transfer(address(this).balance);     
            } else {   
                uint256 tokenBalance = IERC20(token).balanceOf(address(this));
                if (tokenBalance > 0) {
                    // Transfer all ERC20 tokens
                    IERC20(token).transfer(payable(owner()), tokenBalance);
                }
            }
        }
    }

}
