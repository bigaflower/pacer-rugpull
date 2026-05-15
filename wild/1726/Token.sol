/*
https://www.alphatechtoken.com/
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.25;

import {IERC20, ERC20} from "./ERC20.sol";
import {ERC20Burnable} from "./ERC20Burnable.sol";
import {Ownable, Ownable2Step} from "./Ownable2Step.sol";
import {SafeERC20Remastered} from "./SafeERC20Remastered.sol";

import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract Alpha_Technologies_Token is ERC20, ERC20Burnable, Ownable2Step, Initializable {
    
    using SafeERC20Remastered for IERC20;
 
    uint16 public swapThresholdRatio;
    
    uint256 private _treasuryPending;
    uint256 private _ePending;
    uint256 private _akusdPending;
    uint256 private _akethPending;

    address public treasuryAddress;
    uint16[3] public treasuryFees;

    address public eAddress;
    uint16[3] public eFees;

    address public akusdAddress;
    uint16[3] public akusdFees;

    address public akethAddress;
    uint16[3] public akethFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;
 
    error InvalidAmountToRecover(uint256 amount, uint256 maxAmount);

    error InvalidToken(address tokenAddress);

    error CannotDepositNativeCoins(address account);

    error InvalidSwapThresholdRatio(uint16 swapThresholdRatio);

    error InvalidTaxRecipientAddress(address account);

    error CannotExceedMaxTotalFee(uint16 buyFee, uint16 sellFee, uint16 transferFee);

    error InvalidAMM(address AMM);
 
    event SwapThresholdUpdated(uint16 swapThresholdRatio);

    event WalletTaxAddressUpdated(uint8 indexed id, address newAddress);
    event WalletTaxFeesUpdated(uint8 indexed id, uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event WalletTaxSent(uint8 indexed id, address recipient, uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);
 
    constructor()
        ERC20(unicode"Alpha Technologies Token", unicode"ATT")
        Ownable(msg.sender)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0xbFb5FED116Db2557Cb21f3E00aF4A5Db3ED463E9;
        
        updateSwapThreshold(1);

        treasuryAddressSetup(0x88a32107C5d771aaC4e7cBd9058DC617cfa0F544);
        treasuryFeesSetup(100, 100, 0);

        eAddressSetup(0x4caB04ed7bc3e96eA221981Feeab5825AF366e5c);
        eFeesSetup(100, 100, 0);

        akusdAddressSetup(0x5D696c23d81BcBf2F3a303e1B2378B97d8CC2228);
        akusdFeesSetup(50, 50, 0);

        akethAddressSetup(0xB6A2803049942e937c59dE9bE674f8A0CA2e388f);
        akethFeesSetup(50, 50, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 100000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xbFb5FED116Db2557Cb21f3E00aF4A5Db3ED463E9);
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
        return 0 + _treasuryPending + _ePending + _akusdPending + _akethPending;
    }

    function treasuryAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        treasuryAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit WalletTaxAddressUpdated(1, _newAddress);
    }

    function treasuryFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - treasuryFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - treasuryFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - treasuryFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        treasuryFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(1, _buyFee, _sellFee, _transferFee);
    }

    function eAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        eAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit WalletTaxAddressUpdated(2, _newAddress);
    }

    function eFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - eFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - eFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - eFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        eFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(2, _buyFee, _sellFee, _transferFee);
    }

    function akusdAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        akusdAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit WalletTaxAddressUpdated(3, _newAddress);
    }

    function akusdFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - akusdFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - akusdFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - akusdFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        akusdFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(3, _buyFee, _sellFee, _transferFee);
    }

    function akethAddressSetup(address _newAddress) public onlyOwner {
        if (_newAddress == address(0)) revert InvalidTaxRecipientAddress(address(0));

        akethAddress = _newAddress;
        excludeFromFees(_newAddress, true);

        emit WalletTaxAddressUpdated(4, _newAddress);
    }

    function akethFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - akethFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - akethFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - akethFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        akethFees = [_buyFee, _sellFee, _transferFee];

        emit WalletTaxFeesUpdated(4, _buyFee, _sellFee, _transferFee);
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
        }

        emit AMMUpdated(AMM, isAMM);
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
                    
                    _treasuryPending += fees * treasuryFees[txType] / totalFees[txType];

                    _ePending += fees * eFees[txType] / totalFees[txType];

                    _akusdPending += fees * akusdFees[txType] / totalFees[txType];

                    _akethPending += fees * akethFees[txType] / totalFees[txType];

                    
                }

                if (fees > 0) {
                    super._update(from, address(this), fees);
                }
            }
            
            bool canSwap = getAllPending() >= getSwapThresholdAmount() && balanceOf(pairV2) > 0;
            
            if (!_swapping && from != pairV2 && from != address(routerV2) && canSwap) {
                _swapping = true;
                
                if (false || _treasuryPending > 0 || _ePending > 0 || _akusdPending > 0 || _akethPending > 0) {
                    uint256 token2Swap = 0 + _treasuryPending + _ePending + _akusdPending + _akethPending;
                    bool success = false;

                    _swapTokensForCoin(token2Swap);
                    uint256 coinsReceived = address(this).balance;
                    
                    uint256 treasuryPortion = coinsReceived * _treasuryPending / token2Swap;
                    if (treasuryPortion > 0) {
                        (success,) = payable(treasuryAddress).call{value: treasuryPortion, gas: 20000}("");
                        if (success) {
                            emit WalletTaxSent(1, treasuryAddress, treasuryPortion);
                        }
                    }
                    _treasuryPending = 0;

                    uint256 ePortion = coinsReceived * _ePending / token2Swap;
                    if (ePortion > 0) {
                        (success,) = payable(eAddress).call{value: ePortion, gas: 20000}("");
                        if (success) {
                            emit WalletTaxSent(2, eAddress, ePortion);
                        }
                    }
                    _ePending = 0;

                    uint256 akusdPortion = coinsReceived * _akusdPending / token2Swap;
                    if (akusdPortion > 0) {
                        (success,) = payable(akusdAddress).call{value: akusdPortion, gas: 20000}("");
                        if (success) {
                            emit WalletTaxSent(3, akusdAddress, akusdPortion);
                        }
                    }
                    _akusdPending = 0;

                    uint256 akethPortion = coinsReceived * _akethPending / token2Swap;
                    if (akethPortion > 0) {
                        (success,) = payable(akethAddress).call{value: akethPortion, gas: 20000}("");
                        if (success) {
                            emit WalletTaxSent(4, akethAddress, akethPortion);
                        }
                    }
                    _akethPending = 0;

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
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}
