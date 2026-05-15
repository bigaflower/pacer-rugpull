// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes calldata data) external;
}

contract TweetDeploy {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    address public owner;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // âœ… Name and symbol passed at deploy time by the bot
    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        totalSupply = 1_000_000_000 * (10 ** 18);
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address player) public view returns (uint256) {
        return balances[player];
    }

    function allowance(address player, address spender) public view returns (uint256) {
        return allowed[player][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(to != address(0), "Zero address");
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function Transfers(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            transfer(receivers[i], amounts[i]);
        }
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Zero address");
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function approveAndCall(address spender, uint256 tokens, bytes calldata data) external returns (bool) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Zero address");
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), "Zero address");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), "Zero address");
        allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function burn(uint256 amount) external {
        require(amount != 0, "Zero amount");
        require(amount <= balances[msg.sender], "Insufficient balance");
        totalSupply = totalSupply.sub(amount);
        balances[msg.sender] = balances[msg.sender].sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "Overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Underflow");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Overflow");
        return c;
    }
}
