//SPDX-License-Identifier: Unlicense
pragma solidity ^0.4.0;

import './openzeppelin/ownership/Ownable.sol';
import './openzeppelin/token/ERC721/ERC721Token.sol';

import "./interfaces/IOptionMintable.sol";
import "./interfaces/IMintable.sol";

contract CardFactory is Ownable, IOptionMintable {

    mapping(address => bool) public isOptionMinter;

    IMintable public mintableToken;

    uint8 public constant COLORIZED_OPTION = 0;
    uint8 public constant CARDS_WITH_EGGS_OPTION = 1;
    uint8 public constant CARDS_WITH_TEARS_OPTION = 2;
    uint8 public constant JOKERS_OPTION = 3;
    uint8 public constant RARE_OPTION = 4;

    struct Boundaries {
        uint256 start;
        uint256 end;
        mapping(uint256 => bool) isMinted;
    }

    // option id => interval of ids in class (option)
    mapping(uint8 => Boundaries) internal _idBoundaries;

    modifier validOption(uint8 _optionId) {
        require(_optionId < 5, "invalidOptionId");
        _;
    }

    // SET UP BOUNDARIES FOR EVERY TOKENS BEFORE DEPLOY!
    function setIdBoundaryForOption(
        uint8 optionId,
        uint256 startId,
        uint256 endId
    )
        external
        onlyOwner
        validOption(optionId)
    {
        // WARNING: BOUNDARY COLLISION MUST BE CHECKED ON ADMIN SIDE OFFCHAIN!!!
        require(startId < endId, "invalidBoundaries");
        _idBoundaries[optionId] = Boundaries({
          start: startId,
          end: endId
        });
    }

    // set CardRandomMinter as option minter
    function setOptionMinter(address _minter, bool _status) external onlyOwner {
        isOptionMinter[_minter] = _status;
    }

    function mint(uint8 optionId, address toAddress)
        external
        validOption(optionId)
        returns(bool)
    {
        require(isOptionMinter[msg.sender], "onlyMinter");
        uint256 endId = _idBoundaries[optionId].end;
        if (!_idBoundaries[optionId].isMinted[endId]) {
            for (uint256 i = _idBoundaries[optionId].start; i < endId; i++) {
                if (!_idBoundaries[optionId].isMinted[i]) {
                    mintableToken.mint(toAddress, i);
                    _idBoundaries[optionId].isMinted[i] = true;
                    break;
                }
            }
            return true;
        } else {
            return false;
        }
    }
}
