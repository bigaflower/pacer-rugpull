// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Pausable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SaharaToken is ERC20, ERC20Pausable, Ownable, ERC20Permit {
    constructor(
        address initialTreasury,
        uint256 initialSupply
    )
        ERC20("Sahara AI", "SAHARA")
        Ownable(msg.sender)
        ERC20Permit("Sahara AI")
    {
        require(
            initialTreasury != address(0),
            "Treasury cannot be zero address"
        );
        require(initialSupply > 0, "Initial supply must be greater than zero");

        _mint(initialTreasury, initialSupply);
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
