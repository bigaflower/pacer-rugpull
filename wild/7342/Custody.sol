// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./interfaces/IAaveV3Pool.sol";
import "./libraries/SafeToken.sol";

/// @title Custody - ETH 网络单合约（USDT + Aave）
contract Custody {
    using SafeToken for address;

    // Ethereum Mainnet: USDT / aEthUSDT
    address public immutable usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public immutable pool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public immutable aToken = 0x23878914EFE38d27C4D67Ab83ed1b93A74D4086a;

    address public owner;
    bool    public paused;

    mapping(address => bool) public managers;

    uint256 private constant BUFFER = 1_000_000; // 1 USDT (Ethereum USDT has 6 decimals)

    modifier onlyOwner() {
        require(msg.sender == owner, "Custody: not owner");
        _;
    }

    modifier onlyManager() {
        require(managers[msg.sender], "Custody: not manager");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Custody: paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        managers[msg.sender] = true;

        usdt.safeApprove(pool, type(uint256).max);
        emit ManagerAdded(msg.sender);
    }

    /// @notice 存款：用户 USDT 转入本合约，留 1 USDT 缓冲，其余存入 Aave
    function deposit(uint256 amount) external whenNotPaused {
        require(amount > BUFFER, "Custody: min deposit 1 USDT");
        usdt.safeTransferFrom(msg.sender, address(this), amount);
        IAaveV3Pool(pool).supply(usdt, amount - BUFFER, address(this), 0);
        emit Deposited(msg.sender, amount);
    }

    /// @notice USDT 调拨：先从 Aave 取回 amount，再转出 amount
    function withdraw(address to, uint256 amount) external onlyManager whenNotPaused {
        require(amount > 0, "Custody: zero amount");
        require(to != address(0), "Custody: zero addr");

        IAaveV3Pool(pool).withdraw(usdt, amount, address(this));
        uint256 balanceAfter = IERC20(usdt).balanceOf(address(this));
        require(balanceAfter >= amount, "Custody: redeem insufficient");

        usdt.safeTransfer(to, amount);
        emit USDTWithdrawn(msg.sender, to, amount);
    }

    /// @notice ERC20 调拨（任意代币）
    function transferToken(address token, address to, uint256 amount) external onlyManager whenNotPaused {
        require(amount > 0, "Custody: zero amount");
        require(to != address(0), "Custody: zero addr");
        token.safeTransfer(to, amount);
        emit TokenTransferred(msg.sender, token, to, amount);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function addManager(address m) external onlyOwner {
        require(m != address(0), "Custody: zero addr");
        managers[m] = true;
        emit ManagerAdded(m);
    }

    function removeManager(address m) external onlyOwner {
        managers[m] = false;
        emit ManagerRemoved(m);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Custody: zero addr");
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function usdtBalance() external view returns (uint256) {
        return IERC20(usdt).balanceOf(address(this));
    }

    function aTokenBalance() external view returns (uint256) {
        return IERC20(aToken).balanceOf(address(this));
    }

    event Deposited(address indexed user, uint256 amount);
    event USDTWithdrawn(address indexed manager, address indexed to, uint256 amount);
    event TokenTransferred(address indexed manager, address indexed token, address indexed to, uint256 amount);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event ManagerAdded(address indexed manager);
    event ManagerRemoved(address indexed manager);
    event OwnershipTransferred(address indexed prev, address indexed next_);
}
