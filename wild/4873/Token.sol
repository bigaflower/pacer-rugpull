/*
When in the course of crypto events, it becomes necessary for a token to dissolve the chains of bureaucracy and assume among the chains of blocks a station befitting true scarcity, respect for degens requires a candid declaration of its mechanics.
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

contract Token is ERC20, ERC20Burnable, Ownable2Step, Initializable {
     
    uint16[3] public autoBurnFees;

    mapping (address => bool) public isExcludedFromFees;

    uint16[3] public totalFees;
    bool private _swapping;

    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;
 
    error CannotExceedMaxTotalFee(uint16 buyFee, uint16 sellFee, uint16 transferFee);

    error InvalidAMM(address AMM);
 
    event AutoBurnFeesUpdated(uint16 buyFee, uint16 sellFee, uint16 transferFee);
    event AutoBurned(uint256 amount);

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);
 
    constructor()
        ERC20(unicode"ERC-47", unicode"ERC-47")
        Ownable(msg.sender)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0x2Ff8F4CAfEfbA49963740f3e230200b109C21C0c;
        
        autoBurnFeesSetup(47, 47, 0);

        excludeFromFees(supplyRecipient, true);
        excludeFromFees(address(this), true); 

        _mint(supplyRecipient, 470000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x2Ff8F4CAfEfbA49963740f3e230200b109C21C0c);
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
    
    function autoBurnFeesSetup(uint16 _buyFee, uint16 _sellFee, uint16 _transferFee) public onlyOwner {
        totalFees[0] = totalFees[0] - autoBurnFees[0] + _buyFee;
        totalFees[1] = totalFees[1] - autoBurnFees[1] + _sellFee;
        totalFees[2] = totalFees[2] - autoBurnFees[2] + _transferFee;
        if (totalFees[0] > 2500 || totalFees[1] > 2500 || totalFees[2] > 2500) revert CannotExceedMaxTotalFee(totalFees[0], totalFees[1], totalFees[2]);

        autoBurnFees = [_buyFee, _sellFee, _transferFee];

        emit AutoBurnFeesUpdated(_buyFee, _sellFee, _transferFee);
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
                    
                    uint256 autoBurnPortion = 0;

                    fees = amount * totalFees[txType] / 10000;
                    amount -= fees;
                    
                    if (autoBurnFees[txType] > 0) {
                        autoBurnPortion = fees * autoBurnFees[txType] / totalFees[txType];
                        super._update(from, address(0), autoBurnPortion);
                        emit AutoBurned(autoBurnPortion);
                    }

                    fees = fees - autoBurnPortion;
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
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}
