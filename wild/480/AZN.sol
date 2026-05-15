// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title AZN Token
 * @notice Простой токен ERC-20 с функциональностью владельца, паузы и черного списка.
 *         Важно: blacklist/pause — централизованные функции. Уберите их, если они не нужны.
 *         Мы добавили улучшения безопасности и контроля доступа.
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

    // Ошибки с четкими сообщениями для улучшения отладки
    error NotOwner(string message);
    error PausedError(string message);
    error Blacklisted(string message);
    error ZeroAddress();
    error InsufficientBalance(string message);
    error InsufficientAllowance(string message);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner("Only the owner can execute this function.");
        _;
    }

    modifier notPaused() {
        if (paused) revert PausedError("The contract is paused.");
        _;
    }

    modifier notBlacklisted(address user) {
        if (blacklist[user]) revert Blacklisted("The address is blacklisted.");
        _;
    }

    constructor(uint256 _initialSupply) {
        owner = msg.sender;
        totalSupply = _initialSupply * 10 ** uint256(decimals); // Например: 3 миллиона токенов = 3,000,000 * 10^18
        _balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    // Стандартная функция transfer
    function transfer(address to, uint256 amount) external notPaused notBlacklisted(msg.sender) notBlacklisted(to) returns (bool) {
        if (_balances[msg.sender] < amount) revert InsufficientBalance("Not enough balance to transfer.");
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    // Стандартная функция approve
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // Стандартная функция transferFrom
    function transferFrom(address from, address to, uint256 amount) external notPaused notBlacklisted(from) notBlacklisted(to) returns (bool) {
        if (_balances[from] < amount) revert InsufficientBalance("Not enough balance to transfer.");
        if (allowance[from][msg.sender] < amount) revert InsufficientAllowance("Allowance is not enough.");
        _balances[from] -= amount;
        _balances[to] += amount;
        allowance[from][msg.sender] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }

    // Функция для приостановки контракта (владельцем)
    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    // Функция для возобновления контракта (владельцем)
    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    // Функции для работы с черным списком
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