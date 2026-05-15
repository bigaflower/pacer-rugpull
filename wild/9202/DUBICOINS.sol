// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract DUBICOINS {
    string public constant name = "DUBICOINS";
    string public constant symbol = "DUBI";
    uint8  public constant decimals = 18;

    uint256 public constant cap = 10_000_000 * 10**18;

    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed ownerAddr, address indexed spender, uint256 value);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
        _mint(msg.sender, 100_000 * 10**18);
    }

    function totalSupply() external view returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view returns (uint256) { return _balances[account]; }
    function allowance(address ownerAddr, address spender) external view returns (uint256) { return _allowances[ownerAddr][spender]; }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 current = _allowances[from][msg.sender];
        require(current >= amount, "ERC20: insufficient allowance");
        unchecked { _allowances[from][msg.sender] = current - amount; }
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner = zero");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: to = zero");
        uint256 fromBal = _balances[from];
        require(fromBal >= amount, "ERC20: balance too low");
        unchecked {
            _balances[from] = fromBal - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: mint to zero");
        require(_totalSupply + amount <= cap, "Cap exceeded");
        _totalSupply += amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
