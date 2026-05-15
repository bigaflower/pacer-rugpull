/*

  CONNECT by BIG Ecosystem

  BigEcosystem addresses the current fragmentation in the cryptocurrency market by creating a unified platform that merges premier technologies and services. This cohesive approach significantly eases the management of crypto assets and improves the user experience by offering a streamlined and user-friendly interface. 
  
  Web: https://bigecosystem.com/
  X: https://x.com/BigEcosystem
  Telegram: https://t.me/BigEcosystemOfficial

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";
import "./CF_ERC20.sol";
import "./CF_Recoverable.sol";
import "./CF_Burnable.sol";
import "./CF_Whitelist.sol";
import "./CF_MaxBalance.sol";
import "./CF_Taxable.sol";
import "./CF_DEXRouterV2.sol";

contract BIGECOSYSTEM_CONNECT_ERC20 is CF_Common, CF_Ownable, CF_ERC20, CF_Recoverable, CF_Burnable, CF_Whitelist, CF_MaxBalance, CF_Taxable, CF_DEXRouterV2 {
  constructor() {
    _name = unicode"Connect";
    _symbol = unicode"CNCT";
    _decimals = 18;
    _totalSupply = 100000000000000000000000000; // 100,000,000 CNCT
    _transferOwnership(0x165Af5744f60b1124eF0554B5006A23Ba29CFb83);
    _transferInitialSupply(0xf641a8d39E09bCa90d0fAcd4D66A6E470AEBf0c4, 60000); // 60%
    _transferInitialSupply(0xf06197d4eb3b549Fd3B2A9Ff403317Ef9902E863, 20000); // 20%
    _transferInitialSupply(0xE6533F8BC543Fb9B943e5C33E42249C39aF1D891, 20000); // 20%
    _setDEXRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    _setEarlyPenaltyTime(600); // 10min
    _setTaxToken(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    _autoSwapEnabled = true;
    _setAutoSwapPercent(50, 250); // 0.05% -> 0.25% of total supply
    _setAutoAddLiquidityPercent(100, 100000); // 0.1% -> 100% of total supply
    _setTaxBeneficiary(0, 0x8881d9869aC7C7840971cAac043D7f4D144Abd10, [ uint24(0), uint24(0), uint24(0) ], [ uint24(0), uint24(4600), uint24(4600) ]); // ChainFactory Anti-Sniper revenue (10%)
    _setTaxBeneficiary(1, 0x0fA44D1E1cD8E4fc3A9267Bfc9048321A052BB60, [ uint24(0), uint24(4000), uint24(4000) ], [ uint24(0), uint24(37000), uint24(37000) ]); // TTAX
    _setTaxBeneficiary(2, 0xF2C8872a76cF030b58174231e97259Ba1BB8F242, [ uint24(0), uint24(1000), uint24(1000) ], [ uint24(0), uint24(9000), uint24(9000) ]); // DTAX
    _initialWhitelist([ 0x165Af5744f60b1124eF0554B5006A23Ba29CFb83, 0xE6533F8BC543Fb9B943e5C33E42249C39aF1D891, 0xf06197d4eb3b549Fd3B2A9Ff403317Ef9902E863, 0xf641a8d39E09bCa90d0fAcd4D66A6E470AEBf0c4, 0x87DB399583eA6dcb8b902e2f353cf7309bDfA991 ]);
    _setMaxBalancePercent(1000); // 1% of total supply
    _domainSeparator = keccak256(abi.encode(keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"), keccak256(bytes(_name)), keccak256(bytes("1")), block.chainid, address(this)));

    _initialized = true;
  }

  function _transfer(address from, address to, uint256 amount) internal virtual override {
    if (to == address(0xdEaD)) {
      _burn(from, amount);

      return;
    }

    if (!_distributing && !_swapping && (from != _dex.pair && from != _dex.router)) {
      _autoSwap(false);
      _autoTaxDistribute();
    }

    if (amount > 0 && !_whitelisted[from] && !_whitelisted[to] && from != address(this) && to != address(this) && to != _dex.router) {
      require((from != _dex.pair && to != _dex.pair) || ((from == _dex.pair || to == _dex.pair) && _tradingEnabled > 0), "Trading disabled");

      unchecked {
        require(to == address(this) || (to == _dex.pair || to == _dex.router) || _balance[to] + amount <= _maxBalanceAmount, "Exceeds maxBalance");

        if (!_suspendTaxes && !_distributing && !_swapping) {
          uint256 appliedTax;
          uint8 taxType;

          if (from == _dex.pair || to == _dex.pair) { taxType = from == _dex.pair ? 1 : 2; }

          address _account = taxType == 1 ? to : from;

          if (_tradingEnabled + _earlyPenaltyTime >= _timestamp() && !_holder[_account].penalty) { _holder[_account].penalty = true; }

          for (uint8 i; i < 6; i++) {
            uint256 percent = uint256(taxType > 0 ? (taxType == 1 ? (_holder[_account].penalty ? _taxBeneficiary[i].penalty[1] : _taxBeneficiary[i].percent[1]) : (_holder[_account].penalty ? _taxBeneficiary[i].penalty[2] : _taxBeneficiary[i].percent[2])) : (_holder[_account].penalty ? _taxBeneficiary[i].penalty[0] : _taxBeneficiary[i].percent[0]));

            if (percent == 0) { continue; }

            uint256 taxAmount = _percentage(amount, percent);

            super._transfer(from, address(this), taxAmount);

            if (_taxBeneficiary[i].account == _dex.pair) {
              _amountForLiquidity += taxAmount;
            } else if (_taxBeneficiary[i].account == address(0xdEaD)) {
              _burn(address(this), taxAmount);
            } else {
              _taxBeneficiary[i].unclaimed += taxAmount;
              _amountForTaxDistribution += taxAmount;
              _totalTaxUnclaimed += taxAmount;
            }

            appliedTax += taxAmount;
          }

          if (appliedTax > 0) {
            _totalTaxCollected += appliedTax;

            amount -= appliedTax;
          }
        }
      }
    }

    super._transfer(from, to, amount);
  }

  function _burn(address account, uint256 amount) internal virtual override {
    super._burn(account, amount);

    _setMaxBalancePercent(_maxBalancePercent);
    _setAutoSwapPercent(_minAutoSwapPercent, _maxAutoSwapPercent);
    _setAutoAddLiquidityPercent(_minAutoAddLiquidityPercent, _maxAutoAddLiquidityPercent);
  }

  function _transferInitialSupply(address account, uint24 percent) private {
    require(!_initialized);

    uint256 amount = _percentage(_totalSupply, uint256(percent));

    _balance[account] = amount;

    emit Transfer(address(0), account, amount);
  }

  /// @notice Returns a list specifying the renounce status of each feature
  function renounced() external view returns (bool Whitelist, bool MaxBalance, bool DEXRouterV2, bool Taxable) {
    return (_renounced.Whitelist, _renounced.MaxBalance, _renounced.DEXRouterV2, _renounced.Taxable);
  }

  /// @notice Returns basic information about this Smart-Contract
  function info() external view returns (string memory name, string memory symbol, uint8 decimals, address owner, uint256 totalSupply, string memory version) {
    return (_name, _symbol, _decimals, _owner, _totalSupply, _version);
  }

  receive() external payable { }
  fallback() external payable { }
}


