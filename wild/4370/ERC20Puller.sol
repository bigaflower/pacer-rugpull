// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20PullTarget {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

/// @title ERC20Puller
/// @notice Platform-owned spender contract for pulling approved ERC-20 tokens from user wallets.
contract ERC20Puller {
    address public owner;
    address public operator;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OperatorUpdated(address indexed previousOperator, address indexed newOperator);
    event TokenPulled(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        address caller
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || msg.sender == operator, "Caller is not authorized");
        _;
    }

    constructor(address initialOwner, address initialOperator) {
        require(initialOwner != address(0), "Owner cannot be zero address");
        require(initialOperator != address(0), "Operator cannot be zero address");

        owner = initialOwner;
        operator = initialOperator;

        emit OwnershipTransferred(address(0), initialOwner);
        emit OperatorUpdated(address(0), initialOperator);
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "Operator cannot be zero address");
        emit OperatorUpdated(operator, newOperator);
        operator = newOperator;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function pullToken(address token, address from, address to, uint256 amount) external onlyAuthorized returns (bool) {
        require(token != address(0), "Token cannot be zero address");
        require(from != address(0), "Source cannot be zero address");
        require(to != address(0), "Destination cannot be zero address");
        require(amount > 0, "Amount must be greater than zero");

        (bool ok, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20PullTarget.transferFrom.selector, from, to, amount)
        );
        require(ok && (data.length == 0 || abi.decode(data, (bool))), "ERC20 transferFrom failed");

        emit TokenPulled(token, from, to, amount, msg.sender);
        return true;
    }
}
