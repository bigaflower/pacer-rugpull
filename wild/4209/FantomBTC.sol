// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract FantomBTC {
    string public constant name = "Fantom BTC";
    string public constant symbol = "fBTC";
    uint8 public constant decimals = 8;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    address public owner;
    bool public ownershipRenounced = false;

    // Hard-coded minter (watcher address)
    address public constant MINTER = 0xa7C9AD11a85844a4f05979b5604f8fF5B5394668;

    uint256 public taxRate = 10;
    bool public tradingEnabled = true;
    bool public swapEnabled = true;

    string[5] private reserveAddresses = [
        "3FuhQLprN9s9MR3bZzR5da7mw75fuahsaU",
        "3EMVdMehEq5SFipQ5UfbsfMsH223sSz9A9",
        "38UmuUqPCrFmQo4khkomQwZ4VbY2nZMJ67",
        "1Ki3WTEEqTLPNsN5cGTsMkL2sJ4m5mdCXT",
        "1LdRcdxfbSnmCYYNdeYpUnztiYzVfBEQeC"
    ];

    modifier onlyOwner() {
        require(msg.sender == owner && !ownershipRenounced, "Not owner");
        _;
    }

    modifier onlyMinter() {
        require(msg.sender == MINTER, "Not minter");
        _;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;

        // Initial supply: 1,000,000,000 fBTC (scaled to 8 decimals)
        uint256 initialSupply = 1_000_000_000 * 10**uint256(decimals);
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Allowance too low");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(tradingEnabled, "Trading disabled");
        require(balanceOf[from] >= amount, "Balance too low");

        uint256 fee = amount * taxRate / 100;
        uint256 net = amount - fee;

        balanceOf[from] -= amount;
        balanceOf[to] += net;
        balanceOf[address(this)] += fee;

        emit Transfer(from, to, net);
        emit Transfer(from, address(this), fee);
    }

    function mint(address to, uint256 amount) external onlyMinter {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function burnFees() external onlyOwner {
        uint256 fees = balanceOf[address(this)];
        require(fees > 0, "No fees to burn");
        balanceOf[address(this)] = 0;
        totalSupply -= fees;
        emit Transfer(address(this), address(0), fees);
    }

    function withdrawFees(address to, uint256 amount) external onlyOwner {
        require(balanceOf[address(this)] >= amount, "Not enough fees");
        balanceOf[address(this)] -= amount;
        balanceOf[to] += amount;
        emit Transfer(address(this), to, amount);
    }

    function toggleTrading(bool _enabled) external onlyOwner {
        tradingEnabled = _enabled;
    }

    function toggleSwap(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
    }

    function renounceOwnership() external onlyOwner {
        ownershipRenounced = true;
        owner = address(0);
    }

    function getReserveAddresses() external view returns (string[5] memory) {
        return reserveAddresses;
    }
}