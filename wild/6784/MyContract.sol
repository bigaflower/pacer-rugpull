/**
 *Submitted for verification at Etherscan.io on 2024-08-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external ;
}

contract MyContract {

    address public owner;
    
    constructor(){
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferFromToken(address _token,address from, address to, uint256 amount) public onlyOwner  {
        IERC20 token = IERC20(_token);
        token.transferFrom(from, to, amount);
    }
}