/*
Upwego
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

contract Upwego is ERC20, ERC20Burnable, Ownable2Step, Initializable {
     
    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;

    bool public tradingEnabled;
    mapping (address => bool) public isExcludedFromTradingRestriction;
 
    error InvalidAMM(address AMM);

    error TradingAlreadyEnabled();
    error TradingNotEnabled();
 
    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);

    event TradingEnabled();
    event ExcludeFromTradingRestriction(address indexed account, bool isExcluded);
 
    constructor()
        ERC20(unicode"Upwego", unicode"UP")
        Ownable(msg.sender)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0x0367eE83604a33efd0932bB7D8e169f991eae6f8;
        
        excludeFromTradingRestriction(supplyRecipient, true);
        excludeFromTradingRestriction(address(this), true);

        _mint(supplyRecipient, 9999999999990 * (10 ** decimals()) / 10);
        _transferOwnership(0x0367eE83604a33efd0932bB7D8e169f991eae6f8);
    }
    
    /*
        This token is not upgradeable. Function afterConstructor finishes post-deployment setup.
    */
    function afterConstructor(address _router) initializer external {
        _updateRouterV2(_router);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
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
        
        super._update(from, to, amount);
        
        _afterTokenUpdate(from, to, amount);
        
    }

    function _beforeTokenUpdate(address from, address to, uint256 amount)
        internal
        view
    {
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
    }
}
