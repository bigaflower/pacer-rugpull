// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LittleRabbitToken is IBEP20 {
    string private _name = "Little Rabbit";
    string private _symbol = "LTRBT";
    uint8 private _decimals = 18;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    address public owner;
    uint256 public gasFeePercentage = 1; // 1% gas fee
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event GasFeeUpdated(uint256 previousPercentage, uint256 newPercentage);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor(uint256 initialSupply) {
        owner = msg.sender;
        _totalSupply = initialSupply * 10**uint256(_decimals);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function name() public view returns (string memory) {
        return _name;
    }
    
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view override returns (uint256) {
        return _allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        
        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_balances[sender] >= amount, "BEP20: transfer amount exceeds balance");
        
        // Calculate gas fee (percentage of the transfer amount)
        uint256 gasFee = (amount * gasFeePercentage) / 100;
        uint256 netAmount = amount - gasFee;
        
        // Deduct from sender
        _balances[sender] -= amount;
        
        // Transfer net amount to recipient (automatically appears in their wallet)
        _balances[recipient] += netAmount;
        
        // Burn the gas fee (remove from total supply)
        _totalSupply -= gasFee;
        
        emit Transfer(sender, recipient, netAmount);
        emit Transfer(sender, address(0), gasFee); // Burn event
    }
    
    function _approve(address _owner, address spender, uint256 amount) internal {
        require(_owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");
        
        _allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function setGasFeePercentage(uint256 newPercentage) external onlyOwner {
        require(newPercentage <= 10, "Gas fee cannot exceed 10%");
        emit GasFeeUpdated(gasFeePercentage, newPercentage);
        gasFeePercentage = newPercentage;
    }
    
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    // Safety function to recover any accidentally sent BNB
    function recoverBNB() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
    
    // Accept BNB (for potential future functionalities)
    receive() external payable {}
}