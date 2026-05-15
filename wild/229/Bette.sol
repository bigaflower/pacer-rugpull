// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error CooldownPeriodActive();
error LiquidityNotAdded();

struct Transaction {
    uint256 amount;
    uint256 timestamp;
}

contract Bette is ERC20, Ownable {

    bool public liquidityAdded = false;
    bool public idoEnded = false;
    uint256 public totalETHReceived;
    uint256 public totalTokensMinted;
    uint256 public transactionCooldown = 30 minutes;

    mapping(address => Transaction[]) public transactions;
    mapping(address => bool) public whitelist;

    event TokensPurchased(address indexed buyer, uint256 ethAmount, uint256 tokenAmount);
    event TransferRecorded(address indexed sender, uint256 value);

    modifier onlyDuringIDO() {
        require(!idoEnded, "IDO has ended");
        _;
    }

    modifier onlyAfterLiquidityAddedOrOwner(address from) {
        if (!liquidityAdded && from != owner()) revert LiquidityNotAdded();
        _;
    }

    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Only EOA can call this function");
        _;
    }

    constructor() ERC20("Bette", "Bette") Ownable(msg.sender) {

    }

    // IDO
    function mintTokens(address _referrer) external payable onlyDuringIDO onlyEOA {
        require(msg.value > 0, "Must send ETH to purchase tokens");

        uint256 tokenAmount = msg.value * 1 gwei;

        _mint(msg.sender, tokenAmount);
        totalTokensMinted += tokenAmount;
        totalETHReceived += msg.value;

        if (_referrer == address(0) || _referrer == msg.sender) {
            _referrer = owner();
        }

        uint256 reward = (tokenAmount * 10 + 5) / 100;
        _mint(_referrer, reward);
        totalTokensMinted += reward;

        emit TokensPurchased(msg.sender, msg.value, tokenAmount);
    }

    function endIDOAndMintLPTokens() external onlyOwner onlyDuringIDO {
        idoEnded = true;
        uint256 lpTokens = totalTokensMinted;
        _mint(owner(), lpTokens);
    }

    function confirmLiquidityAdded() external onlyOwner {
        require(idoEnded, "IDO must end before adding liquidity");
        require(!liquidityAdded, "Liquidity already added");
        liquidityAdded = true;
    }

    function addToWhitelistBatch(address[] calldata addresses) external onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            address addr = addresses[i];
            if (!whitelist[addr]) {
                whitelist[addr] = true;
            }
        }
    }

    function removeFromWhitelist(address _address) external onlyOwner {
        whitelist[_address] = false;
    }

    function withdrawERC20(address tokenAddress, uint256 amount, address to) external onlyOwner {
        IERC20(tokenAddress).transfer(to, amount);
    }

    function withdrawETH() external onlyOwner {
        uint256 amount = address(this).balance;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function transfer(address to, uint256 value) public override onlyAfterLiquidityAddedOrOwner(_msgSender()) returns (bool) {
        address sender = _msgSender();

        _beforeTokenTransfer(sender, to, value);
        super._transfer(sender, to, value);

        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override onlyAfterLiquidityAddedOrOwner(from) returns (bool) {
        address spender = _msgSender();

        _beforeTokenTransfer(from, to, value);
        super._spendAllowance(from, spender, value);
        super._transfer(from, to, value);

        return true;
    }

    function availableBalance(address user) public view returns (uint256) {
        uint256 totalAvailable = balanceOf(user);
        uint256 currentTime = block.timestamp;

        for (uint256 i = 0; i < transactions[user].length; i++) {
            Transaction memory txRecord = transactions[user][i];
            if (txRecord.timestamp + transactionCooldown > currentTime) {
                totalAvailable -= txRecord.amount;
            }
        }

        return totalAvailable;
    }

    function _beforeTokenTransfer(address from, address to, uint256 value) internal {
        if (!whitelist[from]) {
            _cleanupTransactions(from);
            if (!whitelist[from] && availableBalance(from) < value) revert CooldownPeriodActive();
        }

        if (!whitelist[to]) {
            _recordTransaction(to, value);
        }
    }

    function _recordTransaction(address user, uint256 value) internal {
        transactions[user].push(Transaction(value, block.timestamp));
        emit TransferRecorded(user, value);
    }

    function _cleanupTransactions(address user) internal {
        Transaction[] storage userTxs = transactions[user];
        uint256 length = userTxs.length;
        uint256 i;

        while (i < length && userTxs[i].timestamp + transactionCooldown <= block.timestamp) {
            i++;
        }

        if (i > 0) {
            for (uint256 j = i; j < length; j++) {
                userTxs[j - i] = userTxs[j];
            }
            for (uint256 k = length - i; k < length; k++) {
                userTxs.pop();
            }
        }
    }

}
