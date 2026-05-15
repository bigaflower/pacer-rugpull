// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
/**
* @dev Interface of the ERC20 standard as defined in the EIP.
*/
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
/**
* @dev Optional functions from the ERC20 standard.
*/
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
/**
* @dev Provides information about the current execution context.
*/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
/**
* @dev Ownable contract to manage ownership.
*/
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        require(initialOwner != address(0), "Ownable: invalid owner");
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}
contract Xfer is Context, IERC20Metadata, Ownable {
    string private _name = "1Xfer";
    string private _symbol = "XFX";
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 50_000_000_000 * 1e18;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public whitelist;
    bool public trading;
    event WhitelistUpdated(address indexed user, bool status);
    constructor(address initialOwner) Ownable(initialOwner) {
        whitelist[initialOwner] = true;
        _balances[owner()] = _totalSupply;
 
        emit Transfer(address(0), owner(), _totalSupply);
    }
    // ERC20 Metadata
    function name() public view override returns (string memory) {
        return _name;
    }
    function symbol() public view override returns (string memory) {
        return _symbol;
    }
    function decimals() public view override returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "1Xfer: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
 
    function activateTrading() external onlyOwner {
        require(!trading, "1Xfer: Trading already enabled");
        trading = true;
    }
    function updateWhitelist(address user, bool status) external onlyOwner {
        whitelist[user] = status;
        emit WhitelistUpdated(user, status);
    }
    // Internal logic
    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "1Xfer: approve from zero address");
        require(spender != address(0), "1Xfer: approve to zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "1Xfer: Transfer from zero address");
        require(to != address(0), "1Xfer: Transfer to zero address");
        require(amount > 0, "1Xfer: Transfer amount must be greater than zero");
        if (!whitelist[from] && !whitelist[to]) {
            require(trading, "1Xfer: Trading is disabled");
        }
        uint256 senderBalance = _balances[from];
        require(senderBalance >= amount, "1Xfer: Insufficient balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }
}