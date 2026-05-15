// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

contract Pinbo {
    
    event MessagePosted(address indexed sender, bytes message, uint256 timestamp);
    event FeeRecipientChanged(address indexed oldRecipient, address indexed newRecipient);

    uint256 public latestMessageBlock;

    // This fee is collected to fund future development of Pinbo.
    // By posting a message, you contribute to the sustainability of this decentralized app.
    address public feeRecipient;
    uint256 public fee = 0.0001 ether;

    constructor() {
        // Set the deployer as the initial fee recipient
        feeRecipient = msg.sender;
    }

    function postMessage(bytes memory message) public payable {
        require(msg.value == fee, "Exact fee required");
        require(message.length > 0, "Message cannot be empty");
        latestMessageBlock = block.number;
        
        // Transfer fee to fee recipient
        (bool success, ) = payable(feeRecipient).call{value: msg.value}("");
        require(success, "Transfer failed");
        
        emit MessagePosted(msg.sender, message, block.timestamp);
    }

    function setFeeRecipient(address newRecipient) public {
        require(msg.sender == feeRecipient, "Only fee recipient");
        require(newRecipient != address(0), "Cannot set to zero address");
        
        address oldRecipient = feeRecipient;
        feeRecipient = newRecipient;
        
        emit FeeRecipientChanged(oldRecipient, newRecipient);
    }

    function setFee(uint256 newFee) public {
        require(msg.sender == feeRecipient, "Only fee recipient");
        require(newFee > 0, "Fee must be positive");
        fee = newFee;
    }

    function withdrawStuckETH() public {
        require(msg.sender == feeRecipient, "Only fee recipient");
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        (bool success, ) = payable(feeRecipient).call{value: balance}("");
        require(success, "Withdrawal failed");
    }
}
