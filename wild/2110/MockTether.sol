// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MockTether {
    string public constant name = "Mock Tether USD";
    string public constant symbol = "mUSDT";
    uint8 public constant decimals = 6;

    uint256 public totalSupply;
    address public owner;
    bool public paused;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) public blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed holder, address indexed spender, uint256 value);
    event Paused(address indexed account);
    event Unpaused(address indexed account);
    event BlacklistStatus(address indexed account, bool banned);

    modifier onlyOwner() {
        require(msg.sender == owner, "MockTether: only owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "MockTether: paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        uint256 initialSupply = 1_000_000 * 10 ** decimals;
        totalSupply = initialSupply;
        balances[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address holder, address spender) external view returns (uint256) {
        return allowances[holder][spender];
    }

    function approve(address spender, uint256 value) external whenNotPaused returns (bool) {
        _requireNotBlacklisted(msg.sender);
        _requireNotBlacklisted(spender);
        allowances[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external whenNotPaused returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external whenNotPaused returns (bool) {
        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= value, "MockTether: allowance exceeded");
        allowances[from][msg.sender] = currentAllowance - value;
        _transfer(from, to, value);
        return true;
    }

    function mint(address to, uint256 value) external onlyOwner {
        _requireNotBlacklisted(to);
        totalSupply += value;
        balances[to] += value;
        emit Transfer(address(0), to, value);
    }

    function burn(uint256 value) external {
        _requireNotBlacklisted(msg.sender);
        require(balances[msg.sender] >= value, "MockTether: insufficient balance");
        balances[msg.sender] -= value;
        totalSupply -= value;
        emit Transfer(msg.sender, address(0), value);
    }

    function setBlacklist(address account, bool status) external onlyOwner {
        blacklist[account] = status;
        emit BlacklistStatus(account, status);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function _transfer(address from, address to, uint256 value) private {
        require(to != address(0), "MockTether: zero address");
        _requireNotBlacklisted(from);
        _requireNotBlacklisted(to);
        require(balances[from] >= value, "MockTether: insufficient balance");

        balances[from] -= value;
        balances[to] += value;
        emit Transfer(from, to, value);
    }

    function _requireNotBlacklisted(address account) private view {
        require(!blacklist[account], "MockTether: blacklisted");
    }
}
