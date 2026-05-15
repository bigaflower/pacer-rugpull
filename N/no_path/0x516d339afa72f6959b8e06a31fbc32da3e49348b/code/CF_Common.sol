// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./IDEXV2.sol";
import "./IERC20.sol";
import "./IERC721.sol";

abstract contract CF_Common {
  string internal constant _version = "1.0.3";

  mapping(address => uint256) internal _balance;
  mapping(address => mapping(address => uint256)) internal _allowance;
  mapping(address => bool) internal _whitelisted;
  mapping(address => holderAccount) internal _holder;
  mapping(uint8 => taxBeneficiary) internal _taxBeneficiary;
  mapping(address => uint256) internal _tokensForTaxDistribution;

  address[] internal _holders;

  bool internal _autoSwapEnabled;
  bool internal _swapping;
  bool internal _suspendTaxes;
  bool internal _distributing;
  bool internal immutable _initialized;

  uint8 internal immutable _decimals;
  uint24 internal constant _denominator = 1000;
  uint24 internal _maxBalancePercent;
  uint24 internal _totalTxTax;
  uint24 internal _totalBuyTax;
  uint24 internal _totalSellTax;
  uint24 internal _totalPenaltyTxTax;
  uint24 internal _totalPenaltyBuyTax;
  uint24 internal _totalPenaltySellTax;
  uint24 internal _minAutoSwapPercent;
  uint24 internal _maxAutoSwapPercent;
  uint24 internal _minAutoAddLiquidityPercent;
  uint24 internal _maxAutoAddLiquidityPercent;
  uint32 internal _lastTaxDistribution;
  uint32 internal _tradingEnabled;
  uint32 internal _lastSwap;
  uint32 internal _earlyPenaltyTime;
  uint256 internal _totalSupply;
  uint256 internal _totalBurned;
  uint256 internal _maxBalanceAmount;
  uint256 internal _minAutoSwapAmount;
  uint256 internal _maxAutoSwapAmount;
  uint256 internal _minAutoAddLiquidityAmount;
  uint256 internal _maxAutoAddLiquidityAmount;
  uint256 internal _amountForLiquidity;
  uint256 internal _ethForLiquidity;
  uint256 internal _totalTaxCollected;
  uint256 internal _totalTaxUnclaimed;
  uint256 internal _amountForTaxDistribution;
  uint256 internal _amountSwappedForTaxDistribution;
  uint256 internal _ethForTaxDistribution;

  struct Renounced {
    bool Whitelist;
    bool MaxBalance;
    bool Taxable;
    bool DEXRouterV2;
  }

  struct holderAccount {
    bool exists;
    bool penalty;
  }

  struct taxBeneficiary {
    bool exists;
    address account;
    uint24[3] percent; // 0: tx, 1: buy, 2: sell
    uint24[3] penalty;
    uint256 unclaimed;
  }

  struct DEXRouterV2 {
    address router;
    address pair;
    address token0;
    address WETH;
    address receiver;
  }

  Renounced internal _renounced;
  IERC20 internal _taxToken;
  DEXRouterV2 internal _dex;

  function _percentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    unchecked {
      return (amount * bps) / (100 * uint256(_denominator));
    }
  }

  function _timestamp() internal view returns (uint32) {
    unchecked {
      return uint32(block.timestamp % 2**32);
    }
  }

  function denominator() external pure returns (uint24) {
    return _denominator;
  }

  function version() external pure returns (string memory) {
    return _version;
  }
}
