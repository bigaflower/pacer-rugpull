/*
*************************
BlueRed 
*************************
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.25;

import {IERC20, ERC20} from "./ERC20.sol";
import {ERC20Burnable} from "./ERC20Burnable.sol";
import {Ownable, Ownable2Step} from "./Ownable2Step.sol";
import {Mintable} from "./Mintable.sol";
import {SafeERC20Remastered} from "./SafeERC20Remastered.sol";

import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract BlueRedCoin is ERC20, ERC20Burnable, Ownable2Step, Mintable, Initializable {
    
    using SafeERC20Remastered for IERC20;
 
    mapping (address => bool) public blacklisted;

    uint16 public swapThresholdRatio;
    
    uint256 private _hiperPending;

    address public hiperAddress;
    uint16[3] public hiperFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;

    mapping (address => bool) public isExcludedFromLimits;

    mapping (address => uint256) public lastTrade;
    uint256 public tradeCooldownTime;

    bool public tradingEnabled;
    mapping (address => bool) public isExcludedFromTradingRestriction;
 
    error InvalidAmountToRecover(uint256 amount, uint256 maxAmount);

    error InvalidToken(address tokenAddress);

    error TransactionBlacklisted(address from, address to);

    error CannotDepositNativeCoins(address account);

    error InvalidSwapThresholdRatio(uint16 swapThresholdRatio);

    error InvalidTaxRecipientAddress(address account);

    error CannotExceedMaxTotalFee(uint16 buyFee, uint16 sellFee, uint16 transferFee);

    error InvalidAMM(address AMM);

    error InvalidTradeCooldownTime(uint256 tradeCooldownTime);
    error AddressInCooldown(address account);

    error TradingAlreadyEnabled();
    error TradingNotEnabled();
 
    event BlacklistUpdated(address indexed account, bool isBlacklisted);

    event SwapThresholdUpdated(uint16 swapThresholdRatio);

    event WalletTaxAddressUpdated(uint8 indexed id, address newAddress);
    event WalletTaxFeesUpdated(uint8 indexed id, uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event WalletTaxSent(uint8 indexed id, address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event TradeCooldownTimeUpdated(uint256 tradeCooldownTime);

    event TradingEnabled();
    event ExcludeFromTradingRestriction(address indexed account, bool isExcluded);
 
    constructor()
        ERC20(unicode"BlueRedCoin", unicode"BRC")
        Ownable(msg.sender)
        Mintable(20000000000)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0x035a979cBbbE75f1224BCec5Fb89A5d870ebE5E0;
        
        updateSwapThreshold(50);

        hiperAddressSetup(0x1D8d6A3cBE9b76bfD703f253A7BadBBc9999Ab94);
        hiperFeesSetup(0, 0, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 

        updateTradeCooldownTime(120);

        excludeFromTradingRestriction(supplyRecipient, true);
        excludeFromTradingRestriction(address(this), true);

        _mint(supplyRecipient, 10000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x035a979cBbbE75f1224BCec5Fb89A5d870ebE5E0);
    }
    
    /*
        This token is not upgradeable. Function afterConstructor finishes post-deployment setup.
    */
    function afterConstructor(address _router) initializer external {
        _updateRouterV2(_router);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
    
    function recoverToken(uint256 amount) external onlyOwner {
        uint256 maxRecoverable = balanceOf(address(this)) - getAllPending();
        if (amount > maxRecoverable) revert InvalidAmountToRecover(amount, maxRecoverable);

        _update(address(this), msg.sender, amount);
    }

    function recoverForeignERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(this)) revert InvalidToken(tokenAddress);

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
    }

    function blacklist(address account, bool isBlacklisted) external onlyOwner {
        blacklisted[account] = isBlacklisted;

        emit BlacklistUpdated(account, isBlacklisted);
    }

    // Prevent unintended coin transfers
    receive() external payable {
        if (msg.sender != address(routerV2)) revert CannotDepositNativeCoins(msg.sender);
    }

    function _swapTokensForCoin(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = routerV2.WETH();
        
        routerV2.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function updateSwapThreshold(uint16 _swapThresholdRatio) public onlyOwner {
        if (_swapThresholdRatio == 0 || _swapThresholdRatio > 500) revert InvalidSwapThresholdRatio(_swapThresholdRatio);

        swapThresholdRatio = _swapThresholdRatio;
        
        emit SwapThresholdUpdated(_swapThresholdRatio);
    }

    function getSwapThresholdAmount() public view returns (uint256) {
        return balanceOf(pairV2) * swapThresholdRatio / 10000;
    }

    function getAllPending() public view returns (uint256) {
        return 0 + _hiperPending;
    }

    function hiperAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        hiperAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit WalletTaxAddressUpdated(1, _newAddress);
    }

    function hiperFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - hiperFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - hiperFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - hiperFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        hiperFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(1, _buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());

        _approve(address(this), router, type(uint256).max);
        _setAMM(router, true);
        _setAMM(pairV2, true);

        emit RouterV2Updated(router);
    }

    function setAMM(address AMM, bool isAMM) external onlyOwner {
        if (AMM == pairV2 || AMM == address(routerV2)) revert InvalidAMM(AMM);

        _setAMM(AMM, isAMM);
    }

    function _setAMM(address AMM, bool isAMM) private {
        AMMs[AMM] = isAMM;

        if (isAMM) { 
            _excludeFromLimits(AMM, true);

        }

        emit AMMUpdated(AMM, isAMM);
    }

    function excludeFromLimits(address account, bool isExcluded) external onlyOwner {
        _excludeFromLimits(account, isExcluded);
    }

    function _excludeFromLimits(address account, bool isExcluded) internal {
        isExcludedFromLimits[account] = isExcluded;

        emit ExcludeFromLimits(account, isExcluded);
    }

    function updateTradeCooldownTime(uint256 _tradeCooldownTime) public onlyOwner {
        if (_tradeCooldownTime > 12 hours) revert InvalidTradeCooldownTime(_tradeCooldownTime);
            
        tradeCooldownTime = _tradeCooldownTime;
        
        emit TradeCooldownTimeUpdated(_tradeCooldownTime);
    }

    function enableTrading() external onlyOwner {
        if (tradingEnabled) revert TradingAlreadyEnabled();

        tradingEnabled = true;
        
        emit TradingEnabled();
    }

    function excludeFromTradingRestriction(address account, bool isExcluded) public onlyOwner {
        isExcludedFromTradingRestriction[account] = isExcluded;
        
        emit ExcludeFromTradingRestriction(account, isExcluded);
    }


    function _update(address from, address to, uint256 amount)
        internal
        override
    {
        _beforeTokenUpdate(from, to, amount);
        
        if (from != address(0) && to != address(0)) {
            if (!_swapping && amount > 0 && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
                uint256 fees = 0;
                uint8 txType = 3;
                
                if (AMMs[from] && !AMMs[to]) {
                    if (totalFees[0] > 0) txType = 0;
                }
                else if (AMMs[to] && !AMMs[from]) {
                    if (totalFees[1] > 0) txType = 1;
                }
                else if (!AMMs[from] && !AMMs[to]) {
                    if (totalFees[2] > 0) txType = 2;
                }
                
                if (txType < 3) {
                    
                    fees = amount * totalFees[txType] / 10000;
                    amount -= fees;
                    
                    _hiperPending += fees * hiperFees[txType] / totalFees[txType];

                    
                }

                if (fees > 0) {
                    super._update(from, address(this), fees);
                }
            }
            
            bool canSwap = getAllPending() >= getSwapThresholdAmount() && balanceOf(pairV2) > 0;
            
            if (!_swapping && from != pairV2 && from != address(routerV2) && canSwap) {
                _swapping = true;
                
                if (false || _hiperPending > 0) {
                    uint256 token2Swap = 0 + _hiperPending;
                    bool success = false;

                    _swapTokensForCoin(token2Swap);
                    uint256 coinsReceived = address(this).balance;
                    
                    uint256 hiperPortion = coinsReceived * _hiperPending / token2Swap;
                    if (hiperPortion > 0) {
                        (success,) = payable(hiperAddress).call{value: hiperPortion, gas: 20000}("");
                        if (success) {
                            emit WalletTaxSent(1, hiperAddress, hiperPortion);
                        }
                    }
                    _hiperPending = 0;

                }

                _swapping = false;
            }

        }

        super._update(from, to, amount);
        
        _afterTokenUpdate(from, to, amount);
        
    }

    function _beforeTokenUpdate(address from, address to, uint256 amount)
        internal
        view
    {
        if (blacklisted[from] || blacklisted[to]) revert TransactionBlacklisted(from, to);

        if(!isExcludedFromLimits[from] && lastTrade[from] + tradeCooldownTime > block.timestamp) revert AddressInCooldown(from);
        if(!isExcludedFromLimits[to] && lastTrade[to] + tradeCooldownTime > block.timestamp) revert AddressInCooldown(to);

        // Interactions with DEX are disallowed prior to enabling trading by owner
        if (!tradingEnabled) {
            if ((AMMs[from] && !AMMs[to] && !isExcludedFromTradingRestriction[to]) || (AMMs[to] && !AMMs[from] && !isExcludedFromTradingRestriction[from])) {
                revert TradingNotEnabled();
            }
        }

    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
        if (from == address(0)) {
        }

        if (AMMs[from] && !isExcludedFromLimits[to]) lastTrade[to] = block.timestamp;
        else if (AMMs[to] && !isExcludedFromLimits[from]) lastTrade[from] = block.timestamp;

    }
}
