// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

/**
 * Minimal ERC-20 token for OTTERY fund recovery.
 * Deploy this, then use setToken() on OTTERY to point to it.
 * mint() lets you increase your balance between rounds to satisfy
 * the "balance must have increased" check in enter().
 */
contract DummyToken {
    string public name = "RecoveryToken";
    string public symbol = "REC";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        // Mint 200,000 tokens to deployer (well above the 50,000 minimum)
        uint256 initialSupply = 200_000 * 10**18;
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    /**
     * @dev Call this between lottery rounds to increase your balance,
     *      so enter() passes the "balance must have increased" check.
     */
    function mint(uint256 amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        require(balanceOf[msg.sender] >= value, "Insufficient balance");
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        balanceOf[from] -= value;
        allowance[from][msg.sender] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
}
