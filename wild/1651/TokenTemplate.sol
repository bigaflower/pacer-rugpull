// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PumpOTCTokenTemplate is ERC20, ERC20Permit, Ownable {

    uint8 private tokenDecimals;

    constructor(address _initialOwner, string memory _name, string memory _symbol, uint256 _numTotalTokens, uint8 _decimals)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
        Ownable(_initialOwner)
    {
        tokenDecimals = _decimals;
        _mint(msg.sender, _numTotalTokens * 10 ** _decimals);
    }

    //override
    function decimals() public view virtual override returns (uint8) {
        return tokenDecimals;
    }
}
