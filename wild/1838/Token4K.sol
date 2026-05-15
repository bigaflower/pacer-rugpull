// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Token4K {
    string public name = "Token4K";
    string public symbol = "4K";
    uint8 public decimals = 18;
    uint256 public immutable maxSupply;
    uint256 public totalSupply;
    uint256 public burnRate = 10;  // 0,0001% spalane przy każdej transakcji
    uint256 public taxRate = 20;   // 0,02% podatek od transakcji
    address public taxWallet;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public isExcludedFromFees;
    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TaxPaid(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event BurnRateUpdated(uint256 newRate);
    event TaxRateUpdated(uint256 newRate);
    event TaxWalletUpdated(address newWallet);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    constructor(uint256 initialSupply, uint256 _maxSupply, address _taxWallet) {
        require(initialSupply <= _maxSupply, "Initial supply exceeds max supply");
        require(_taxWallet != address(0), "Invalid tax wallet address");

        maxSupply = _maxSupply * (10 ** decimals);
        totalSupply = initialSupply * (10 ** decimals);
        balanceOf[msg.sender] = totalSupply;
        owner = msg.sender;
        taxWallet = _taxWallet;

        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        allowance[sender][msg.sender] -= amount;
        _transfer(sender, recipient, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(balanceOf[sender] >= amount, "Insufficient balance");

        uint256 _burnRate = burnRate;
        uint256 _taxRate = taxRate;

        uint256 burnAmount = (amount * _burnRate) / 1_000_000;
        uint256 taxAmount = (amount * _taxRate) / 1_000_000;
        uint256 transferAmount = amount - burnAmount - taxAmount;

        balanceOf[sender] -= amount;
        balanceOf[recipient] += transferAmount;

        if (burnAmount > 0) {
            totalSupply -= burnAmount;
            emit Burn(sender, burnAmount);
        }

        if (taxAmount > 0) {
            balanceOf[taxWallet] += taxAmount;
            emit TaxPaid(sender, taxWallet, taxAmount);
        }

        emit Transfer(sender, recipient, transferAmount);
    }

    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance to burn");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Burn(msg.sender, amount);
    }

    function setBurnRate(uint256 rate) external onlyOwner {
        require(rate <= 1000, "Burn rate too high");
        burnRate = rate;
        emit BurnRateUpdated(rate);
    }

    function setTaxRate(uint256 rate) external onlyOwner {
        require(rate <= 1000, "Tax rate too high");
        taxRate = rate;
        emit TaxRateUpdated(rate);
    }

    function setTaxWallet(address wallet) external onlyOwner {
        require(wallet != address(0), "Invalid wallet address");
        taxWallet = wallet;
        emit TaxWalletUpdated(wallet);
    }

    function setExcludedFromFees(address account, bool excluded) external onlyOwner {
        isExcludedFromFees[account] = excluded;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner cannot be zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}