// SPDX-License-Identifier: MIT
/*
 █████╗ ██╗              
██╔══██╗██║              
███████║██║              
██╔══██║██║              
██║  ██║██║              
╚═╝  ╚═╝╚═╝              
██╗███████╗              
██║██╔════╝              
██║███████╗              
██║╚════██║              
██║███████║              
╚═╝╚══════╝              
██████╗ ███████╗██╗   ██╗
██╔══██╗██╔════╝██║   ██║
██║  ██║█████╗  ██║   ██║
██║  ██║██╔══╝  ╚██╗ ██╔╝
██████╔╝███████╗ ╚████╔╝ 
╚═════╝ ╚══════╝  ╚═══╝  
*/
// This token was generated AND deployed using GPT-3.5 and DALLE-2 for FREE on https://aiis.dev! 
// All tokens deployed from this website adhere to basic token standards, ensuring secure code and compatibility among the blockchain ecosystem.
// Check it out now! https://aiis.dev

pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Ownable.sol";

contract AIToken is IERC20, Ownable {
    string public symbol;
    uint8 public decimals = 18;
    uint256 internal _totalSupply;
    string public name;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    address public factory;

   constructor() Ownable(_msgSender()){
        factory = msg.sender;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        uint256 _initialSupply,
        address _initialHolder
    ) external {
        require(msg.sender == factory, "only f");
        // Set the token details and credit the initial supply to _initialHolder
        name = _name;
        symbol = _symbol;
        _totalSupply = _initialSupply * (10 ** uint256(decimals));
        _balances[_initialHolder] = _totalSupply;
        emit Transfer(address(0), _initialHolder, _totalSupply);

        // Transfer ownership to the dead address
        transferOwnership(0x000000000000000000000000000000000000dEaD);
    }


    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) external virtual returns (bool) {
        require(msg.sender != address(0), "from 0"); // "ERC20: transfer from the zero address" -> "from 0"
        require(recipient != address(0), "to 0"); // "ERC20: transfer to the zero address" -> "to 0"
        require(_balances[msg.sender] >= amount, "low bal"); // "ERC20: insufficient balance" -> "low bal"

        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(msg.sender != address(0), "from 0"); // "ERC20: approve from the zero address" -> "from 0"
        require(spender != address(0), "to 0"); // "ERC20: approve to the zero address" -> "to 0"

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool) {
        require(sender != address(0), "from 0"); // "ERC20: transfer from the zero address" -> "from 0"
        require(recipient != address(0), "to 0"); // "ERC20: transfer to the zero address" -> "to 0"
        require(_balances[sender] >= amount, "low bal"); // "ERC20: insufficient balance" -> "low bal"
        require(allowances[sender][msg.sender] >= amount, ">allowance"); // Shortened but kept clear

        _balances[sender] -= amount;
        _balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "under 0"); // "ERC20: decreased allowance below zero" -> "under 0"
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "from 0"); // "ERC20: approve from the zero address" -> "from 0"
        require(spender != address(0), "to 0"); // "ERC20: approve to the zero address" -> "to 0"

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
