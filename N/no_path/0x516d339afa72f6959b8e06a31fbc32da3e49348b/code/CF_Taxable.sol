// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";

abstract contract CF_Taxable is CF_Common, CF_Ownable, CF_ERC20 {
  event SetTaxBeneficiary(uint8 slot, address account, uint24[3] percent, uint24[3] penalty);
  event SetEarlyPenaltyTime(uint32 time);
  event TaxDistributed(uint256 amount);
  event RenouncedTaxable();

  struct taxBeneficiaryView {
    address account;
    uint24[3] percent;
    uint24[3] penalty;
    uint256 unclaimed;
  }

  modifier lockDistributing {
    _distributing = true;
    _;
    _distributing = false;
  }

  /// @notice Permanently renounce and prevent the owner from being able to update the tax features
  /// @dev Existing settings will continue to be effective
  function renounceTaxable() external onlyOwner {
    _renounced.Taxable = true;

    emit RenouncedTaxable();
  }

  /// @notice Total amount of taxes collected so far
  function totalTaxCollected() external view returns (uint256) {
    return _totalTaxCollected;
  }
  /// @notice Tax applied per transfer
  /// @dev Taking in consideration your wallet address
  function txTax() external view returns (uint24) {
    return txTax(msg.sender);
  }

  /// @notice Tax applied per transfer
  /// @param from Sender address
  function txTax(address from) public view returns (uint24) {
    unchecked {
      return from == address(this) || _whitelisted[from] || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyTxTax : _totalTxTax);
    }
  }

  /// @notice Tax applied for buying
  /// @dev Taking in consideration your wallet address
  function buyTax() external view returns (uint24) {
    return buyTax(msg.sender);
  }

  /// @notice Tax applied for buying
  /// @param from Buyer's address
  function buyTax(address from) public view returns (uint24) {
    if (_suspendTaxes) { return 0; }

    unchecked {
      return from == address(this) || _whitelisted[from] || from == _dex.pair ? 0 : (_holder[from].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltyBuyTax : _totalBuyTax);
    }
  }
  /// @notice Tax applied for selling
  /// @dev Taking in consideration your wallet address
  function sellTax() external view returns (uint24) {
    return sellTax(msg.sender);
  }

  /// @notice Tax applied for selling
  /// @param to Seller's address
  function sellTax(address to) public view returns (uint24) {
    if (_suspendTaxes) { return 0; }

    unchecked {
      return to == address(this) || _whitelisted[to] || to == _dex.pair || to == _dex.router ? 0 : (_holder[to].penalty || _tradingEnabled + _earlyPenaltyTime >= _timestamp() ? _totalPenaltySellTax : _totalSellTax);
    }
  }

  /// @notice List of all tax beneficiaries and their assigned percentage, according to type of transfer
  /// @custom:return `list[].account` Beneficiary address
  /// @custom:return `list[].percent[3]` Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @custom:return `list[].penalty[3]` Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function listTaxBeneficiaries() external view returns (taxBeneficiaryView[] memory list) {
    list = new taxBeneficiaryView[](6);

    unchecked {
      for (uint8 i; i < 6; i++) { list[i] = taxBeneficiaryView(_taxBeneficiary[i].account, _taxBeneficiary[i].percent, _taxBeneficiary[i].penalty, _taxBeneficiary[i].unclaimed); }
    }
  }

  /// @notice Sets a tax beneficiary
  /// @dev Maximum of 5 wallets can be assigned
  /// @dev Slot 0 is reserved for ChainFactory revenue
  /// @param slot Slot number (1 to 5)
  /// @param account Beneficiary address
  /// @param percent[3] Index 0 is for tx tax, 1 is for buy tax, 2 is for sell tax, multiplied by denominator
  /// @param penalty[3] Index 0 is for tx penalty, 1 is for buy penalty, 2 is for sell penalty, multiplied by denominator
  function setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) external onlyOwner {
    require(!_renounced.Taxable);
    require(slot >= 1 && slot <= 5, "Reserved");

    _setTaxBeneficiary(slot, account, percent, penalty);
  }

  function _setTaxBeneficiary(uint8 slot, address account, uint24[3] memory percent, uint24[3] memory penalty) internal {
    require(slot <= 5);
    require(account != address(this) && account != address(0));

    taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[slot];

    if (slot > 0 && account == address(0xdEaD) && taxBeneficiarySlot.unclaimed > 0) { revert("Unclaimed taxes"); }

    unchecked {
      _totalTxTax += percent[0] - taxBeneficiarySlot.percent[0];
      _totalBuyTax += percent[1] - taxBeneficiarySlot.percent[1];
      _totalSellTax += percent[2] - taxBeneficiarySlot.percent[2];
      _totalPenaltyTxTax += penalty[0] - taxBeneficiarySlot.penalty[0];
      _totalPenaltyBuyTax += penalty[1] - taxBeneficiarySlot.penalty[1];
      _totalPenaltySellTax += penalty[2] - taxBeneficiarySlot.penalty[2];

      require(_totalTxTax <= 25 * _denominator && ((_totalBuyTax <= 25 * _denominator && _totalSellTax <= 25 * _denominator) && (_totalBuyTax + _totalSellTax <= 25 * _denominator)), "High Tax");
      require(_totalPenaltyTxTax <= 90 * _denominator && _totalPenaltyBuyTax <= 90 * _denominator && _totalPenaltySellTax <= 90 * _denominator, "Invalid Penalty");

      taxBeneficiarySlot.account = account;
      taxBeneficiarySlot.percent = percent;

      if (_initialized && slot > 0) { _setTaxBeneficiary(0, _taxBeneficiary[0].account, [ uint24(0), uint24(0), uint24(0) ], [ _taxBeneficiary[0].penalty[0] + uint24((penalty[0] * 10 / 100) - (taxBeneficiarySlot.penalty[0] * 10 / 100)), _taxBeneficiary[0].penalty[1] + uint24((penalty[1] * 10 / 100) - (taxBeneficiarySlot.penalty[1] * 10 / 100)), _taxBeneficiary[0].penalty[2] + uint24((penalty[2] * 10 / 100) - (taxBeneficiarySlot.penalty[2] * 10 / 100)) ]); }

      taxBeneficiarySlot.penalty = penalty;
    }

    if (!taxBeneficiarySlot.exists) { taxBeneficiarySlot.exists = true; }

    emit SetTaxBeneficiary(slot, account, percent, penalty);
  }

  /// @notice Triggers the tax distribution
  /// @dev Will only be executed if there is no ongoing swap or tax distribution
  function autoTaxDistribute() external {
    require(msg.sender == _owner || _whitelisted[msg.sender], "Unauthorized");
    require(!_swapping && !_distributing);

    _autoTaxDistribute();
  }

  function _autoTaxDistribute() internal lockDistributing {
    if (_totalTaxUnclaimed == 0) { return; }

    unchecked {
      uint256 distributedTaxes;

      for (uint8 i; i < 6; i++) {
        taxBeneficiary storage taxBeneficiarySlot = _taxBeneficiary[i];
        address account = taxBeneficiarySlot.account;

        if (taxBeneficiarySlot.unclaimed == 0 || account == address(0xdEaD) || account == _dex.pair) { continue; }

        uint256 unclaimed = _percentage(address(_taxToken) == address(this) ? _amountForTaxDistribution : _amountSwappedForTaxDistribution, (100 * uint256(_denominator) * taxBeneficiarySlot.unclaimed) / _totalTaxUnclaimed);
        uint256 _distributedTaxes = _distribute(account, unclaimed);

        if (_distributedTaxes > 0) {
          taxBeneficiarySlot.unclaimed -= _distributedTaxes;
          distributedTaxes += _distributedTaxes;
        }
      }

      _lastTaxDistribution = _timestamp();

      if (distributedTaxes > 0) {
        _totalTaxUnclaimed -= distributedTaxes;

        emit TaxDistributed(distributedTaxes);
      }
    }
  }

  function _distribute(address account, uint256 unclaimed) private returns (uint256) {
    if (unclaimed == 0) { return 0; }

    unchecked {
      if (address(_taxToken) == address(this)) {
        if (_balance[account] + unclaimed > _maxBalanceAmount && !_whitelisted[account]) {
          unclaimed = _maxBalanceAmount > _balance[account] ? _maxBalanceAmount - _balance[account] : 0;

          if (unclaimed == 0) { return 0; }
        }

        super._transfer(address(this), account, unclaimed);

        _amountForTaxDistribution -= unclaimed;
      } else {
        uint256 percent = (100 * uint256(_denominator) * unclaimed) / _amountSwappedForTaxDistribution;
        uint256 amount;

        if (address(_taxToken) == _dex.WETH) {
          amount = _percentage(_ethForTaxDistribution, percent);

          (bool success, ) = payable(account).call{ value: amount, gas: 30000 }("");

          if (!success) { return 0; }

          _ethForTaxDistribution -= amount;
        } else {
          amount = _percentage(_tokensForTaxDistribution[address(_taxToken)], percent);

          try _taxToken.transfer(account, amount) { _tokensForTaxDistribution[address(_taxToken)] -= amount; } catch { return 0; }
        }

        _amountSwappedForTaxDistribution -= unclaimed;
      }
    }

    return unclaimed;
  }

  /// @notice Suspend or reinstate tax collection
  /// @dev Also applies to early penalties
  /// @param status True to suspend, False to reinstate existent taxes
  function suspendTaxes(bool status) external onlyOwner {
    require(!_renounced.Taxable);

    _suspendTaxes = status;
  }

  /// @notice Checks if tax collection is currently suspended
  function taxesSuspended() external view returns (bool) {
    return _suspendTaxes;
  }

  /// @notice Removes the penalty status of a wallet
  /// @param account Address to depenalize
  function removePenalty(address account) external onlyOwner {
    require(!_renounced.Taxable);

    _holder[account].penalty = false;
  }

  /// @notice Check if a wallet is penalized due to an early transaction
  /// @param account Address to check
  function isPenalized(address account) external view returns (bool) {
    return _holder[account].penalty;
  }

  /// @notice Returns the period of time during which early buyers will be penalized from the time trading was enabled
  function getEarlyPenaltyTime() external view returns (uint32) {
    return _earlyPenaltyTime;
  }

  /// @notice Defines the period of time during which early buyers will be penalized from the time trading was enabled
  /// @dev Must be less or equal to 1 hour
  /// @param time Time, in seconds
  function setEarlyPenaltyTime(uint32 time) external onlyOwner {
    require(!_renounced.Taxable);
    require(time <= 600);

    _setEarlyPenaltyTime(time);
  }

  function _setEarlyPenaltyTime(uint32 time) internal {
    _earlyPenaltyTime = time;

    emit SetEarlyPenaltyTime(time);
  }
}
