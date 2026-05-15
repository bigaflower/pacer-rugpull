// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title FakeUSDT
 * @dev ERC20 token mimicking real USDT for security testing
 * WARNING: This is for authorized security testing only
 * Matches real USDT metadata: symbol "USDT", name "Tether USD", decimals 6
 */
contract FakeUSDT {
    // Match real USDT metadata exactly
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;

    // ERC20 standard state variables
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    address public owner;

    // Events matching real USDT
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }

    constructor(uint256 initialSupply) {
        owner = msg.sender;
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
        emit Issue(initialSupply);
    }

    /**
     * @dev Transfer tokens from msg.sender to recipient
     */
    function transfer(address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[msg.sender] >= value, "Insufficient balance");

        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve spender to spend tokens on behalf of msg.sender
     */
    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), "Cannot approve zero address");

        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another using allowance
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(to != address(0), "Cannot transfer to zero address");
        require(balanceOf[from] >= value, "Insufficient balance");
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;

        emit Transfer(from, to, value);
        return true;
    }

    /**
     * @dev Mint new tokens (for testing purposes)
     * Emits Issue event like real USDT
     */
    function mint(address to, uint256 amount) public onlyOwner returns (bool) {
        require(to != address(0), "Cannot mint to zero address");

        totalSupply += amount;
        balanceOf[to] += amount;

        emit Transfer(address(0), to, amount);
        emit Issue(amount);
        return true;
    }

    /**
     * @dev Burn tokens from msg.sender
     * Emits Redeem event like real USDT
     */
    function burn(uint256 amount) public returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");

        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;

        emit Transfer(msg.sender, address(0), amount);
        emit Redeem(amount);
        return true;
    }

    /**
     * @dev Emit Deprecate event (testing contract upgrade scenarios)
     */
    function deprecate(address newAddress) public onlyOwner {
        emit Deprecate(newAddress);
    }

    /**
     * @dev Emit Params event (testing fee parameter changes)
     */
    function setParams(uint feeBasisPoints, uint maxFee) public onlyOwner {
        emit Params(feeBasisPoints, maxFee);
    }
}
