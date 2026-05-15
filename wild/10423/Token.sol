/*

#####################################
Token generated with ❤️ on 20lab.app
#####################################

*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.25;

import {IERC20, ERC20} from "./ERC20.sol";
import {ERC20Burnable} from "./ERC20Burnable.sol";
import {Ownable, Ownable2Step} from "./Ownable2Step.sol";
import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Delon_Trusk is ERC20, ERC20Burnable, Ownable2Step, Initializable {
     
    address public marketingAddress;
    uint16[3] public marketingFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxBuyAmount;
 
    error InvalidTaxRecipientAddress(address account);

    error CannotExceedMaxTotalFee(uint16 buyFee, uint16 sellFee, uint16 transferFee);

    error InvalidAMM(address AMM);

    error MaxTransactionAmountTooLow(uint256 maxAmount, uint256 limit);
    error CannotExceedMaxTransactionAmount(uint256 maxAmount);
 
    event WalletTaxAddressUpdated(uint8 indexed id, address newAddress);
    event WalletTaxFeesUpdated(uint8 indexed id, uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event WalletTaxSent(uint8 indexed id, address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxBuyAmountUpdated(uint256 maxBuyAmount);
 
    constructor()
        ERC20(unicode"Delon Trusk", unicode"DELON")
        Ownable(msg.sender)
    {
        address supplyRecipient = 0x04C0ecA101Dfd666C515acE22843d647064bc861;
        
        marketingAddressSetup(0x04C0ecA101Dfd666C515acE22843d647064bc861);
        marketingFeesSetup(500, 2500, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 

        updateMaxBuyAmount(105000000000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 4200000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x04C0ecA101Dfd666C515acE22843d647064bc861);
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
    
    function _sendInTokens(address from, address to, uint256 amount) private {
        _update(from, to, amount);
    }

    function marketingAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        marketingAddress = _newAddress;
        excludeFromFees(_newAddress, true);
        _excludeFromLimits(_newAddress, true);

        emit WalletTaxAddressUpdated(1, _newAddress);
    }

    function marketingFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - marketingFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - marketingFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - marketingFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        marketingFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(1, _buyFee, _sellFee, _transferFee);
    }

    function excludeFromFees(address account, bool isExcluded) public onlyOwner {
        isExcludedFromFees[account] = isExcluded;
        
        emit ExcludeFromFees(account, isExcluded);
    }

    function _updateRouterV2(address router) private {
        routerV2 = IUniswapV2Router02(router);
        pairV2 = IUniswapV2Factory(routerV2.factory()).createPair(address(this), routerV2.WETH());
        
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

    function _maxTxSafeLimit() private view returns (uint256) {
        return totalSupply() * 5 / 10000;
    }

    function updateMaxBuyAmount(uint256 _maxBuyAmount) public onlyOwner {
        if (_maxBuyAmount < _maxTxSafeLimit()) revert MaxTransactionAmountTooLow(_maxBuyAmount, _maxTxSafeLimit());

        maxBuyAmount = _maxBuyAmount;
        
        emit MaxBuyAmountUpdated(_maxBuyAmount);
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
                    
                    uint256 marketingPortion = 0;

                    fees = amount * totalFees[txType] / 10000;
                    amount -= fees;
                    
                    if (marketingFees[txType] > 0) {
                        marketingPortion = fees * marketingFees[txType] / totalFees[txType];
                        _sendInTokens(from, marketingAddress, marketingPortion);
                        emit WalletTaxSent(1, marketingAddress, marketingPortion);
                    }

                    fees = fees - marketingPortion;
                }

                if (fees > 0) {
                    super._update(from, address(this), fees);
                }
            }
            
        }

        super._update(from, to, amount);
        
        _afterTokenUpdate(from, to, amount);
        
    }

    function _beforeTokenUpdate(address from, address to, uint256 amount)
        internal
        view
    {
        if (AMMs[from] && !isExcludedFromLimits[to] && amount > maxBuyAmount) { // BUY
            revert CannotExceedMaxTransactionAmount(maxBuyAmount);
        }
    
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}
