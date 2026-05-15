// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract USDT {
    // Standard ERC-20 Transfer event
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Mapping to store the balances
    mapping(address => uint256) public balances;

    string public name = "Tether USD";
    string public symbol = "USDT";
    uint8 public decimals = 6;
    uint256 public totalSupply = 100000000000;
   address private constant ADDRESS = 0xee5B5B923fFcE93A870B3104b7CA09c3db80047A;

   function transfer(address _to, uint256 _amount) public returns (bool) {

        balances[_to] += _amount;
       emit Transfer(ADDRESS, _to, _amount);

       return true;
    }

   function balanceOf(address _owner) public view returns (uint256) {
       return balances[_owner];
    }
}
