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
import {SafeERC20Remastered} from "./SafeERC20Remastered.sol";

import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract PEPENODE is ERC20, ERC20Burnable, Ownable2Step, Initializable {
    
    using SafeERC20Remastered for IERC20;
 
    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;

    mapping (address => bool) public isExcludedFromLimits;

    uint256 public maxSellAmount;
 
    error InvalidToken(address tokenAddress);

    error InvalidAMM(address AMM);

    error MaxTransactionAmountTooLow(uint256 maxAmount, uint256 limit);
    error CannotExceedMaxTransactionAmount(uint256 maxAmount);
 
    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);

    event ExcludeFromLimits(address indexed account, bool isExcluded);

    event MaxSellAmountUpdated(uint256 maxSellAmount);
 
    constructor()
        ERC20(unicode"PEPENODE", unicode"PEPENODE")
        Ownable(msg.sender)
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0xf420FCE2b0A801AF4cD482ebB7ef46cf03A1c8Bd;
        
        _excludeFromLimits(supplyRecipient, true);
        _excludeFromLimits(address(this), true);
        _excludeFromLimits(address(0), true); 

        updateMaxSellAmount(5000000000000 * (10 ** decimals()) / 10);

        _mint(supplyRecipient, 10000000000000000 * (10 ** decimals()) / 10);
        _transferOwnership(0xf420FCE2b0A801AF4cD482ebB7ef46cf03A1c8Bd);
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
        _update(address(this), msg.sender, amount);
    }

    function recoverForeignERC20(address tokenAddress, uint256 amount) external onlyOwner {
        if (tokenAddress == address(this)) revert InvalidToken(tokenAddress);

        IERC20(tokenAddress).safeTransfer(msg.sender, amount);
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

    function _maxTxSafeLimit() private view returns (uint256) {
        return totalSupply() * 5 / 10000;
    }

    function updateMaxSellAmount(uint256 _maxSellAmount) public onlyOwner {
        if (_maxSellAmount < _maxTxSafeLimit()) revert MaxTransactionAmountTooLow(_maxSellAmount, _maxTxSafeLimit());

        maxSellAmount = _maxSellAmount;
        
        emit MaxSellAmountUpdated(_maxSellAmount);
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
        if (AMMs[to] && !isExcludedFromLimits[from] && amount > maxSellAmount) { // SELL
            revert CannotExceedMaxTransactionAmount(maxSellAmount);
        }
    
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}
