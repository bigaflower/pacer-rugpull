// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ArabCoins {
    // ERC20 metadata
    string public constant name = "ARABCOINS";
    string public constant symbol = "ARBC";
    uint8  public constant decimals = 18;

    // Supply / cap
    uint256 public constant CAP = 1000000000 * 10**18; // 1,000,000,000
    uint256 public totalSupply;

    // Ownership
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner(){ require(msg.sender == owner, "not owner"); _; }

    // ERC20 storage
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // ERC20 events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(){
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        _mint(msg.sender, 100000 * 10**18); // initial 100,000 ARBC
    }

    // Views
    function balanceOf(address a) public view returns (uint256){ return _balances[a]; }
    function allowance(address o, address s) public view returns (uint256){ return _allowances[o][s]; }

    // Transfers/approvals
    function transfer(address to, uint256 amt) public returns (bool){ _transfer(msg.sender, to, amt); return true; }
    function approve(address s, uint256 amt) public returns (bool){ _approve(msg.sender, s, amt); return true; }
    function transferFrom(address f, address t, uint256 amt) public returns (bool){
        uint256 al = _allowances[f][msg.sender];
        require(al >= amt, "insufficient allowance");
        unchecked { _approve(f, msg.sender, al - amt); }
        _transfer(f, t, amt);
        return true;
    }

    // Mint (owner only) with hard cap
    function mint(address to, uint256 amt) external onlyOwner { _mint(to, amt); }

    // Ownership
    function transferOwnership(address n) external onlyOwner {
        require(n != address(0), "zero addr");
        emit OwnershipTransferred(owner, n);
        owner = n;
    }

    // Internals
    function _transfer(address f, address t, uint256 amt) internal {
        require(t != address(0), "transfer to zero");
        uint256 fb = _balances[f];
        require(fb >= amt, "balance too low");
        unchecked { _balances[f] = fb - amt; }
        _balances[t] += amt;
        emit Transfer(f, t, amt);
    }

    function _approve(address o, address s, uint256 amt) internal {
        require(s != address(0), "approve to zero");
        _allowances[o][s] = amt;
        emit Approval(o, s, amt);
    }

    function _mint(address to, uint256 amt) internal {
        require(to != address(0), "mint to zero");
        uint256 ns = totalSupply + amt;
        require(ns <= CAP, "cap exceeded");
        totalSupply = ns;
        _balances[to] += amt;
        emit Transfer(address(0), to, amt);
    }
}
