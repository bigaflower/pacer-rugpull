// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {AccessControl} from "openzeppelin-contracts/contracts/access/AccessControl.sol";

import {SafeCast} from "openzeppelin-contracts/contracts/utils/math/SafeCast.sol";

import {Nonces} from "openzeppelin-contracts/contracts/utils/Nonces.sol";

import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Burnable} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

import {ERC20Votes, ERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract DAM is AccessControl, ERC20Burnable, ERC20Votes, ERC20Permit {
    bytes32 public constant GOVERNOR = keccak256(abi.encode("dam.governor"));

    uint256 private constant supply = 1_000_000_000e18;

    constructor(
        address admin,
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) ERC20Permit(name_) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);

        _mint(msg.sender, supply);
    }

    /// @notice Increase token total supply
    /// @param account Address to increment the token balance
    /// @param amount Quantity of token added
    function mint(address account, uint256 amount) external onlyRole(GOVERNOR) {
        _mint(account, amount);
    }

    /// @notice Flags checkpoints
    /// @return uint46 Block timestamp
    function clock() public view virtual override returns (uint48) {
        return SafeCast.toUint48(block.timestamp);
    }

    /// @notice Machine-readable description of the clock
    /// @return string Clock mode
    function CLOCK_MODE() public view virtual override returns (string memory) {
        return "mode=timestamp";
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal virtual override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// @notice Override nonces to resolve the conflict between ERC20Votes and ERC20Permit
    /// @param owner Address to return nonces for
    /// @return uint256 Nonces of the address
    function nonces(
        address owner
    ) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
