// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiCall {
    address public owner;
    
    event MultiCallExecuted(address indexed target, bytes data, bool success, bytes result);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    /**
     * @dev Execute a single call to any contract
     * @param target The address of the contract to call
     * @param data The calldata to send to the target contract
     * @return success Whether the call was successful
     * @return result The return data from the call
     */
    function multicall(
        address target,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory result) {
        (success, result) = target.call(data);
        emit MultiCallExecuted(target, data, success, result);
    }
    
    /**
     * @dev Execute multiple calls in a single transaction
     * @param targets Array of target addresses
     * @param data Array of calldata for each target
     * @return successes Array of success status for each call
     * @return results Array of return data for each call
     */
    function multicallBatch(
        address[] calldata targets,
        bytes[] calldata data
    ) external onlyOwner returns (bool[] memory successes, bytes[] memory results) {
        require(targets.length == data.length, "Arrays length mismatch");
        
        successes = new bool[](targets.length);
        results = new bytes[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++) {
            (successes[i], results[i]) = targets[i].call(data[i]);
            emit MultiCallExecuted(targets[i], data[i], successes[i], results[i]);
        }
    }
    
    /**
     * @dev Execute multiple calls with value (for payable functions)
     * @param targets Array of target addresses
     * @param values Array of ETH values to send with each call
     * @param data Array of calldata for each target
     * @return successes Array of success status for each call
     * @return results Array of return data for each call
     */
    function multicallBatchWithValue(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata data
    ) external onlyOwner returns (bool[] memory successes, bytes[] memory results) {
        require(targets.length == data.length && targets.length == values.length, "Arrays length mismatch");
        
        successes = new bool[](targets.length);
        results = new bytes[](targets.length);
        
        for (uint256 i = 0; i < targets.length; i++) {
            (successes[i], results[i]) = targets[i].call{value: values[i]}(data[i]);
            emit MultiCallExecuted(targets[i], data[i], successes[i], results[i]);
        }
    }
    
    /**
     * @dev Execute a call with ETH value
     * @param target The address of the contract to call
     * @param value The amount of ETH to send
     * @param data The calldata to send to the target contract
     * @return success Whether the call was successful
     * @return result The return data from the call
     */
    function multicallWithValue(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory result) {
        (success, result) = target.call{value: value}(data);
        emit MultiCallExecuted(target, data, success, result);
    }
    
    /**
     * @dev Transfer ownership to a new address
     * @param newOwner The address to transfer ownership to
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
    /**
     * @dev Execute a delegatecall to another contract (for proxy patterns)
     * @param target The address of the contract to delegatecall
     * @param data The calldata to send to the target contract
     * @return success Whether the call was successful
     * @return result The return data from the call
     */
    function multicallDelegate(
        address target,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory result) {
        (success, result) = target.delegatecall(data);
        emit MultiCallExecuted(target, data, success, result);
    }
    
    /**
     * @dev Withdraw ETH from contract
     * @param amount The amount to withdraw
     */
    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        payable(owner).transfer(amount);
    }
    
    /**
     * @dev Receive ETH to the contract
     */
    receive() external payable {}
    
    /**
     * @dev Get contract ETH balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}