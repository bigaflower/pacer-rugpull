// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CassaERC20 is ERC20 {
    uint8 immutable _decimals;
    address public parent;

    modifier onlyParent() {
        require(msg.sender == parent, "CassaERC20: only parent can call");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address parent_) ERC20(name_, symbol_) {
        _decimals = decimals_;
        parent = parent_;
    }

    /// @notice See {ICassaERC20-mint}
    function mint(address to, uint256 amount) external onlyParent {
        _mint(to, amount);
    }

    /// @notice See {ICassaERC20-burn}
    function burn(address from, uint256 amount) external onlyParent {
        _burn(from, amount);
    }

    /// @notice See {ICassaERC20-spendAllowance}
    function spendAllowance(address owner, address spender, uint256 amount) external onlyParent {
        _spendAllowance(owner, spender, amount);
    }

    /// @inheritdoc ERC20
    function decimals() public view virtual override returns (uint8 __decimals) {
        return _decimals;
    }
}
