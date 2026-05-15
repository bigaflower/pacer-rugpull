// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";

abstract contract CF_DEXRouterV2 is CF_Common, CF_Ownable, CF_ERC20 {
  event AddedLiquidity(uint256 tokenAmount, uint256 ethAmount, uint256 liquidity);
  event SwappedTokensForTokens(address token, uint256 token0Amount, uint256 token1Amount);
  event SwappedTokensForNative(uint256 tokenAmount, uint256 ethAmount);
  event SetDEXRouterV2(address indexed router, address indexed pair);
  event TradingEnabled();
  event RenouncedDEXRouterV2();

  modifier lockSwapping {
    _swapping = true;
    _;
    _swapping = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the DEX features
  /// @dev Existing settings will continue to be effective
  function renounceDEXRouterV2() external onlyOwner {
    _renounced.DEXRouterV2 = true;

    emit RenouncedDEXRouterV2();
  }

  function _setDEXRouterV2(address router, address token0) internal {
    IDEXRouterV2 _router = IDEXRouterV2(router);
    IDEXFactoryV2 factory = IDEXFactoryV2(_router.factory());
    address pair = factory.createPair(address(this), token0);

    _dex = DEXRouterV2(router, pair, token0, _router.WETH(), address(0));

    emit SetDEXRouterV2(router, _dex.pair);
  }

  /// @notice Returns the DEX router currently in use
  function getDEXRouterV2() external view returns (address) {
    return _dex.router;
  }

  /// @notice Returns the trading pair
  function getDEXPairV2() external view returns (address) {
    return _dex.pair;
  }

  /// @notice Checks whether the token can be traded through the assigned DEX
  function isTradingEnabled() external view returns (bool) {
    return _tradingEnabled > 0;
  }

  /// @notice Returns address of the LP tokens receiver
  /// @dev Used for automated liquidity injection through taxes
  function getDEXLPTokenReceiver() external view returns (address) {
    return _dex.receiver;
  }

  /// @notice Set the address of the LP tokens receiver
  /// @dev Used for automated liquidity injection through taxes
  function setDEXLPTokenReceiver(address receiver) external onlyOwner {
    _setDEXLPTokenReceiver(receiver);
  }

  function _setDEXLPTokenReceiver(address receiver) internal {
    _dex.receiver = receiver;
  }

  /// @notice Checks the status of the auto-swapping feature
  function isAutoSwapEnabled() external view returns (bool) {
    return _autoSwapEnabled;
  }

  /// @notice Returns the percentage range of the total supply over which the auto-swap will operate when accumulating taxes in the contract balance
  function getAutoSwapPercent() external view returns (uint24 min, uint24 max) {
    return (_minAutoSwapPercent, _maxAutoSwapPercent);
  }

  /// @notice Sets the percentage range of the total supply over which the auto-swap will operate when accumulating taxes in the contract balance
  /// @param min Desired min. percentage to trigger the auto-swap, multiplied by denominator (0.001% to 1% of total supply)
  /// @param max Desired max. percentage to limit the auto-swap, multiplied by denominator (0.001% to 1% of total supply)
  function setAutoSwapPercent(uint24 min, uint24 max) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(min >= 1 && min <= 1000, "0.001% to 1%");
    require(max >= min && max <= 1000, "0.001% to 1%");

    _setAutoSwapPercent(min, max);
  }

  function _setAutoSwapPercent(uint24 min, uint24 max) internal {
    _minAutoSwapPercent = min;
    _maxAutoSwapPercent = max;
    _minAutoSwapAmount = _percentage(_totalSupply, uint256(min));
    _maxAutoSwapAmount = _percentage(_totalSupply, uint256(max));
  }

  /// @notice Enables or disables the auto-swap function
  /// @param status True to enable, False to disable
  function enableAutoSwap(bool status) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(!status || _dex.router != address(0), "No DEX");

    _autoSwapEnabled = status;
  }

  /// @notice Swaps the assigned amount to inject liquidity and prepare collected taxes for its distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached
  function autoSwap() external {
    require(_autoSwapEnabled && !_swapping && !_distributing);

    _autoSwap(false);
  }

  /// @notice Swaps the assigned amount to inject liquidity and prepare collected taxes for its distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution and the min. threshold has been reached unless forced
  /// @param force Ignore the min. and max. threshold amount
  function autoSwap(bool force) external {
    require(msg.sender == _owner || _whitelisted[msg.sender], "Unauthorized");
    require((force || _autoSwapEnabled) && !_swapping && !_distributing);

    _autoSwap(force);
  }

  function _autoSwap(bool force) internal lockSwapping {
    if (!force && !_autoSwapEnabled) { return; }

    unchecked {
      uint256 amountForLiquidityToSwap = _amountForLiquidity > 0 ? _amountForLiquidity / 2 : 0;
      uint256 amountForTaxDistributionToSwap = (address(_taxToken) == _dex.WETH ? _amountForTaxDistribution : 0);
      uint256 amountToSwap = amountForTaxDistributionToSwap + amountForLiquidityToSwap;

      if (!force && amountToSwap > _maxAutoSwapAmount) {
        amountForLiquidityToSwap = amountForLiquidityToSwap > 0 ? _percentage(_maxAutoSwapAmount, (100 * uint256(_denominator) * amountForLiquidityToSwap) / amountToSwap) : 0;
        amountForTaxDistributionToSwap = amountForTaxDistributionToSwap > 0 ? _percentage(_maxAutoSwapAmount, (100 * uint256(_denominator) * amountForTaxDistributionToSwap) / amountToSwap) : 0;
        amountToSwap = amountForTaxDistributionToSwap + amountForLiquidityToSwap;
      }

      if ((force || amountToSwap >= _minAutoSwapAmount) && _balance[address(this)] >= amountToSwap + amountForLiquidityToSwap) {
        uint256 ethBalance = address(this).balance;
        address[] memory pathToSwapExactTokensForNative = new address[](2);
        pathToSwapExactTokensForNative[0] = address(this);
        pathToSwapExactTokensForNative[1] = _dex.WETH;

        _approve(address(this), _dex.router, amountToSwap);

        try IDEXRouterV2(_dex.router).swapExactTokensForETHSupportingFeeOnTransferTokens(amountToSwap, 0, pathToSwapExactTokensForNative, address(this), block.timestamp) {
          if (_amountForLiquidity > 0) { _amountForLiquidity -= amountForLiquidityToSwap; }

          uint256 ethAmount = address(this).balance - ethBalance;

          emit SwappedTokensForNative(amountToSwap, ethAmount);

          if (ethAmount > 0) {
            _ethForLiquidity += _percentage(ethAmount, (100 * uint256(_denominator) * amountForLiquidityToSwap) / amountToSwap);

            if (address(_taxToken) == _dex.WETH) {
              _ethForTaxDistribution += _percentage(ethAmount, (100 * uint256(_denominator) * amountForTaxDistributionToSwap) / amountToSwap);
              _amountSwappedForTaxDistribution += amountForTaxDistributionToSwap;
              _amountForTaxDistribution -= amountForTaxDistributionToSwap;
            }
          }
        } catch {
          _approve(address(this), _dex.router, 0);
        }
      }

      if (address(_taxToken) != address(this) && address(_taxToken) != _dex.WETH) {
        amountForTaxDistributionToSwap = _amountForTaxDistribution;

        if (!force && amountForTaxDistributionToSwap > _maxAutoSwapAmount) { amountForTaxDistributionToSwap = _maxAutoSwapAmount; }

        if ((force || amountForTaxDistributionToSwap >= _minAutoSwapAmount) && _balance[address(this)] >= amountForTaxDistributionToSwap) {
          uint256 tokenAmount = _swapTokensForTokens(_taxToken, amountForTaxDistributionToSwap);

          if (tokenAmount > 0) {
            _tokensForTaxDistribution[address(_taxToken)] += tokenAmount;
            _amountSwappedForTaxDistribution += amountForTaxDistributionToSwap;
            _amountForTaxDistribution -= amountForTaxDistributionToSwap;
          }
        }
      }
    }

    _addLiquidity(force);
    _lastSwap = _timestamp();
  }

  function _swapTokensForTokens(IERC20 token, uint256 amount) private returns (uint256 tokenAmount) {
    uint256 tokenBalance = token.balanceOf(address(this));
    address[] memory pathToSwapExactTokensForTokens = new address[](3);
    pathToSwapExactTokensForTokens[0] = address(this);
    pathToSwapExactTokensForTokens[1] = _dex.WETH;
    pathToSwapExactTokensForTokens[2] = address(token);

    _approve(address(this), _dex.router, amount);

    try IDEXRouterV2(_dex.router).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, 0, pathToSwapExactTokensForTokens, address(this), block.timestamp) {
      tokenAmount = token.balanceOf(address(this)) - tokenBalance;

      emit SwappedTokensForTokens(address(token), amount, tokenAmount);
    } catch {
      _approve(address(this), _dex.router, 0);
    }
  }

  function _addLiquidity(bool force) private {
    if (!force && (_amountForLiquidity < _minAutoAddLiquidityAmount || _ethForLiquidity == 0)) { return; }

    unchecked {
      uint256 amountForLiquidityToAdd = !force && _amountForLiquidity > _maxAutoAddLiquidityAmount ? _maxAutoAddLiquidityAmount : _amountForLiquidity;
      uint256 ethForLiquidityToAdd = !force && _amountForLiquidity > _maxAutoAddLiquidityAmount ? _percentage(_ethForLiquidity, 100 * uint256(_denominator) * (_maxAutoAddLiquidityAmount / _amountForLiquidity)) : _ethForLiquidity;

      _approve(address(this), _dex.router, amountForLiquidityToAdd);

      try IDEXRouterV2(_dex.router).addLiquidityETH{ value: ethForLiquidityToAdd }(address(this), amountForLiquidityToAdd, 0, 0, _dex.receiver, block.timestamp) returns (uint256 tokenAmount, uint256 ethAmount, uint256 liquidity) {
        emit AddedLiquidity(tokenAmount, ethAmount, liquidity);

        _amountForLiquidity -= amountForLiquidityToAdd;
        _ethForLiquidity -= ethForLiquidityToAdd;
      } catch {
        _approve(address(this), _dex.router, 0);
      }
    }
  }

  /// @notice Returns the percentage range of the total supply over which the auto add liquidity will operate when accumulating taxes in the contract balance
  /// @dev Applies only if a Tax Beneficiary is the liquidity pool
  function getAutoAddLiquidityPercent() external view returns (uint24 min, uint24 max) {
    return (_minAutoAddLiquidityPercent, _maxAutoAddLiquidityPercent);
  }

  /// @notice Sets the percentage range of the total supply over which the auto add liquidity will operate when accumulating taxes in the contract balance
  /// @param min Desired min. percentage to trigger the auto add liquidity, multiplied by denominator (0.01% to 100% of total supply)
  /// @param max Desired max. percentage to limit the auto add liquidity, multiplied by denominator (0.01% to 100% of total supply)
  function setAutoAddLiquidityPercent(uint24 min, uint24 max) external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(min >= 10 && min <= 100 * _denominator, "0.01% to 100%");
    require(max >= min && max <= 100 * _denominator, "0.01% to 100%");

    _setAutoAddLiquidityPercent(min, max);
  }

  function _setAutoAddLiquidityPercent(uint24 min, uint24 max) internal {
    _minAutoAddLiquidityPercent = min;
    _maxAutoAddLiquidityPercent = max;
    _minAutoAddLiquidityAmount = _percentage(_totalSupply, uint256(min));
    _maxAutoAddLiquidityAmount = _percentage(_totalSupply, uint256(max));
  }

  /// @notice Returns the token for tax distribution
  function getTaxToken() external view returns (address) {
    return address(_taxToken);
  }

  function _setTaxToken(address token) internal {
    require((!_initialized && token == address(0)) || token == address(this) || token == _dex.WETH || IDEXFactoryV2(IDEXRouterV2(_dex.router).factory()).getPair(_dex.WETH, token) != address(0), "No Pair");

    _taxToken = IERC20(token == address(0) ? address(this) : token);
  }

  /// @notice Enables the trading capability via the DEX set up
  /// @dev Once enabled, it cannot be reverted
  function enableTrading() external onlyOwner {
    require(!_renounced.DEXRouterV2);
    require(_tradingEnabled == 0, "Already enabled");

    _tradingEnabled = _timestamp();

    emit TradingEnabled();
  }
}
