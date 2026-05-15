// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

contract  BaseERC20  {
    uint public constant  MAX_INT = 2**256 - 1;

    string public name;
    string public symbol;
    uint public  decimals = 18;
    uint public _totalSupply;
    mapping(address => uint256) public  _balanceOf;
    mapping(address => mapping(address => uint256)) public _allowance;

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor(string memory _name){
        name = _name;
        symbol = _name;
        
    }
    
    function _mint(address to, uint256 value) internal {
        _totalSupply +=  value;
        _balanceOf[to] +=  value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        _balanceOf[from] -=  value;
        _totalSupply -=  value;
        emit Transfer(from, address(0), value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal {
        _balanceOf[from] -= value;
        _balanceOf[to] += value;
        emit Transfer(from, to, value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        _allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
    function balanceOf(address account) public virtual view returns (uint256){
        return _balanceOf[account];
    }
    function totalSupply() public virtual view returns (uint256){
        return _totalSupply;
    }
    function allowance(address owner, address spender) public virtual view returns (uint256){
        return _allowance[owner][spender];
    }
    function approve(address spender, uint256 value) public virtual returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    
}