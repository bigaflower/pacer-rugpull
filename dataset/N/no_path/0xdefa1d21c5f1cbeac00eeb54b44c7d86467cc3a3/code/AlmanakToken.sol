// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    ERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

import {
    ERC20Burnable
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Standard ERC20 token with permit functionality for gasless approvals.
 */
contract AlmanakToken is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        address owner,
        uint256 initialSupply
    ) ERC20(name, symbol) ERC20Permit(name) Ownable(owner) {
        require(owner != address(0), "AT: owner cannot be zero address");

        // Mint the initial supply to the owner.
        _mint(owner, initialSupply);
    }
}
