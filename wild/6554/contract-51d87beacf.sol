// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts@5.3.0/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts@5.3.0/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts@5.3.0/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts@5.3.0/token/ERC20/extensions/ERC20Votes.sol";
import {Nonces} from "@openzeppelin/contracts@5.3.0/utils/Nonces.sol";

/// @custom:security-contact contact@moss.land
contract MossCoin is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes {
    constructor(address recipient)
        ERC20("Moss Coin", "MOC")
        ERC20Permit("Moss Coin")
    {
        _mint(recipient, 500000000 * 10 ** decimals());
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Votes)
    {
        super._update(from, to, value);
    }

    function nonces(address owner)
        public
        view
        override(ERC20Permit, Nonces)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}
