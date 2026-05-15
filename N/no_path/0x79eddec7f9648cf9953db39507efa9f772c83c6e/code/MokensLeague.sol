// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {IMokensLeagueErrors} from "./IMokensLeagueErrors.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MokensLeague is
    ERC20,
    ERC20Burnable,
    ERC20Pausable,
    Ownable,
    ERC20Permit,
    IMokensLeagueErrors
{
    constructor(
        uint256 cap,
        address initialHolder
    )
        ERC20("Mokens League", "MOKA")
        Ownable(msg.sender)
        ERC20Permit("Mokens League")
    {
        if (initialHolder == address(0)) {
            revert MokensLeagueInvalidInitialHolder(address(0));
        }

        _mint(initialHolder, cap);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Pausable) {
        super._update(from, to, value);
    }
}
