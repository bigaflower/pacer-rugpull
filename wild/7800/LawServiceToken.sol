// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract LawServiceToken {
    string public name = "Law Service Token";
    string public symbol = "LST";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    address public owner;

    address public constant lockupWallet = 0x10aaEA5561002cF45DD48429f87683DCab6875a4; // 8억 락업 지갑 (예: Gnosis Safe)
    address public constant liquidityWallet = 0x47ee8d49AF8d263d17C46b0db6C3E2960c8C0660; // 2억 유동성 지갑

    uint256 public constant LOCKUP_AMOUNT = 800_000_000 * 10**18;
    uint256 public constant LIQUIDITY_AMOUNT = 200_000_000 * 10**18;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed burner, uint256 amount);
    event LockupAllocated(address indexed to, uint256 amount); // 🔔 락업 이벤트 추가

    constructor() {
        owner = msg.sender;
        totalSupply = LOCKUP_AMOUNT + LIQUIDITY_AMOUNT;

        balances[lockupWallet] = LOCKUP_AMOUNT;
        balances[liquidityWallet] = LIQUIDITY_AMOUNT;

        emit LockupAllocated(lockupWallet, LOCKUP_AMOUNT); // 🔔 락업 배정 이벤트 발생
        emit Transfer(address(0), lockupWallet, LOCKUP_AMOUNT);
        emit Transfer(address(0), liquidityWallet, LIQUIDITY_AMOUNT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner_, address spender) public view returns (uint256) {
        return allowances[owner_][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(allowances[from][msg.sender] >= amount, "Allowance exceeded");
        require(balances[from] >= amount, "Insufficient balance");
        allowances[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient balance to burn");
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        owner = newOwner;
    }

    // === 감사 용도 함수 ===
    function getUserBalance(address user) public view onlyOwner returns (uint256) {
        return balances[user];
    }
}