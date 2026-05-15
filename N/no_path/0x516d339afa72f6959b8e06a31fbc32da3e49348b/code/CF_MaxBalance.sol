// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";

abstract contract CF_MaxBalance is CF_Common, CF_Ownable {
  event SetMaxBalancePercent(uint24 percent);
  event RenouncedMaxBalance();

  /// @notice Permanently renounce and prevent the owner from being able to update the max. balance
  /// @dev Existing settings will continue to be effective
  function renounceMaxBalance() external onlyOwner {
    _renounced.MaxBalance = true;

    emit RenouncedMaxBalance();
  }

  /// @notice Percentage of the max. balance per wallet, depending on total supply
  function getMaxBalancePercent() external view returns (uint24) {
    return _maxBalancePercent;
  }

  /// @notice Set the max. percentage of a wallet balance, depending on total supply
  /// @param percent Desired percentage, multiplied by denominator (min. 0.1% of total supply)
  function setMaxBalancePercent(uint24 percent) external onlyOwner {
    require(!_renounced.MaxBalance);

    _setMaxBalancePercent(percent);

    emit SetMaxBalancePercent(percent);
  }

  function _setMaxBalancePercent(uint24 percent) internal {
    unchecked {
      require(percent >= 100 && percent <= 100 * _denominator);
    }

    _maxBalancePercent = percent;
    _maxBalanceAmount = _percentage(_totalSupply, uint256(percent));

    if (!_initialized) { emit SetMaxBalancePercent(percent); }
  }
}
