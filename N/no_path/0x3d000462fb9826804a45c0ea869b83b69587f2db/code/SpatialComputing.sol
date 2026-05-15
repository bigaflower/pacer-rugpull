// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "./ERC20.sol";
import {Owned} from "./Owned.sol";

contract SpatialComputing is ERC20, Owned {
    mapping(address => bool) public blacklists;
    bool public canBlacklist = true;

    constructor(
        address deployer,
        uint256 supply
    ) ERC20("SpatialComputing", "CMPT", 18) Owned(deployer) {
        _mint(deployer, supply);
    }

    function renounceOwnership() external onlyOwner {
        transferOwnership(address(0));
    }

    function renounceBlacklistAbility() external onlyOwner {
        canBlacklist = false;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        require(canBlacklist, "blacklisting renounced already");
        blacklists[_address] = _isBlacklisting;
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blacklists[to] && !blacklists[msg.sender], "Blacklisted");
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max)
            allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }
}
