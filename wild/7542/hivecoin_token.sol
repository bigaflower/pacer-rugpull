// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract HiveCoin is ERC20, Ownable, ERC20Permit {
    // --- Operator management ---
    mapping(address => bool) private operators;

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);

    modifier onlyOperator() {
        require(operators[msg.sender], "HC: caller is not operator");
        _;
    }

    /// @dev Set up name/symbol, ownership and bootstrap the first operator.
    constructor(address initialOwner)
        ERC20("HiveCoin", "HIVE")
        Ownable(initialOwner)
        ERC20Permit("HiveCoin")
    {
        operators[initialOwner] = true;
        emit OperatorAdded(initialOwner);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /// @notice Owner can add a new operator who may mint/burn.
    function addOperator(address operator) external onlyOwner {
        require(operator != address(0), "HC: operator is the zero address");
        require(!operators[operator], "HC: already an operator");
        operators[operator] = true;
        emit OperatorAdded(operator);
    }

    /// @notice Owner can remove an existing operator.
    function removeOperator(address operator) external onlyOwner {
        require(operators[operator], "HC: not an operator");
        operators[operator] = false;
        emit OperatorRemoved(operator);
    }

    /// @notice Check if an address is an operator.
    function isOperator(address operator) external view returns (bool) {
        return operators[operator];
    }

    // --- Minting & Burning (operator-only) ---

    /// @notice Creates `amount` tokens and assigns them to `to`. Only operators can call.
    function mint(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    /// @notice Burns `amount` tokens from `account`. Only operators can call.
    function burnFrom(address account, uint256 amount) external onlyOperator {
        _burn(account, amount);
    }

    // --- Ownership transfer ---

    /// @notice Transfer contract ownership to `newOwner`. Only current owner can call.
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "HC: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // --- Disable all user transfers ---

    /// @dev Override OpenZeppelin’s internal hook to revert on any real transfer.
    ///      Allows only mint (from == 0) and burn (to == 0).
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            revert("HC: transfers disabled");
        }
        super._update(from, to, amount);
    }
}