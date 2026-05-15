// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;


interface IUpgradedToken{
    
    function transferByLegacy (address sender,address to,uint256 value) external returns (bool) ;
    
    function transferFromByLegacy (address sender,address from,address to,uint256 value) external returns (bool);

    function balanceOf(address account) external view returns (uint);

    function approveByLegacy (address sender,address to,uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function totalSupply() external view returns (uint);
    
} 

   
    
  

