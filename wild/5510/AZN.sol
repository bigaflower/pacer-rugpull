/** 
 * Submitted for verification at Etherscan.io on 2025-12-24
 */

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AZN Token
 * @notice Простой токен ERC-20 с функциональностью владельца, паузы и черного списка.
 *         Важно: blacklist/pause — централизованные функции. Уберите их, если они не нужны.
 */
contract AZN {
    // Метаданные ERC-20
    string public name = "AZN";
    string public symbol = "AZN";
    uint8 public immutable decimals = 18; // стандарт для большинства токенов ERC-20

    // Общее количество токенов
    uint256 public totalSupply;

    // Административные функции
    address public owner;
    bool public paused;

    // Хранение данных
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public blacklist;

    // События ERC-20
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    // События для администраторов
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Paused(address indexed by);
    event Unpaused(address indexed by);
    event BlacklistUpdated(address indexed user, bool status);

    error NotOwner();
    error PausedError();
    error Blacklisted(address user);
    error ZeroAddress();
    error InsufficientBalance();
    error InsufficientAllowance();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier notPaused() {
        if (paused) revert PausedError();
        _;
    }

    modifier notBlacklisted(address user) {
        if (blacklist[user]) revert Blacklisted(user);
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals); // Например: 3 миллиона токенов = 3,000,000 * 10^18
        _balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function transfer(address to, uint256 amount) external notPaused notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        if (_balances[msg.sender] < amount) revert InsufficientBalance();
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external notPaused notBlacklisted(from) notBlacklisted(to) returns (bool) {
        if (_balances[from] < amount) revert InsufficientBalance();
        if (allowance[from][msg.sender] < amount) revert InsufficientAllowance();
        _balances[from] -= amount;
        _balances[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function addToBlacklist(address user) external onlyOwner {
        blacklist[user] = true;
        emit BlacklistUpdated(user, true);
    }

    function removeFromBlacklist(address user) external onlyOwner {
        blacklist[user] = false;
        emit BlacklistUpdated(user, false);
    }

    // Функция для получения баланса пользователя
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    // Функция для получения разрешений (allowance) для спендера
    function allowanceOf(address tokenOwner, address spender) external view returns (uint256) {
        return allowance[tokenOwner][spender];
    }

    // Функции для управления контрактом (только для владельца)
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    // Добавлен URL логотипа
    // Логотип токена для отображения в кошельках, например, в MetaMask.
    // Адрес логотипа: https://russo-studio.ru/AZNlogo.png
}