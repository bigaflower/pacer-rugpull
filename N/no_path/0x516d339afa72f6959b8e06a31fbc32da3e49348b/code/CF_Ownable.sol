// SPDX-License-Identifier: MIT

import "./CF_Common.sol";

pragma solidity 0.8.25;

abstract contract CF_Ownable is CF_Common {
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner() {
    require(_owner == msg.sender, "Unauthorized");

    _;
  }

  function owner() external view returns (address) {
    return _owner;
  }

  function renounceOwnership() external onlyOwner {
    _renounced.Whitelist = true;
    _renounced.MaxBalance = true;
    _renounced.Taxable = true;
    _renounced.DEXRouterV2 = true;

    _transferOwnership(address(0));
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0));

    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;

    emit OwnershipTransferred(oldOwner, newOwner);
  }
}
