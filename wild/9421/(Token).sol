/*
www.andreasschendel.de
*/


// SPDX-License-Identifier: No License
pragma solidity 0.8.25;

import {IERC20, ERC20} from "./ERC20.sol";
import {ERC20Burnable} from "./ERC20Burnable.sol";
import {Ownable, Ownable2Step} from "./Ownable2Step.sol";
import {SafeERC20Remastered} from "./SafeERC20Remastered.sol";

import {ERC20Permit} from "./ERC20Permit.sol";
import {Initializable} from "./Initializable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router01.sol";
import "./IUniswapV2Router02.sol";

contract I_FEEL_FEARFUL is ERC20, ERC20Burnable, Ownable2Step, ERC20Permit, Initializable {
    
    using SafeERC20Remastered for IERC20;
 
    IUniswapV2Router02 public routerV2;
    address public pairV2;
    mapping (address => bool) public AMMs;
 
    error InvalidToken(address tokenAddress);

    error InvalidAMM(address AMM);
 
    event RouterV2Updated(address indexed routerV2);
    event AMMUpdated(address indexed AMM, bool isAMM);
 
    constructor()
        ERC20(unicode"I FEEL FEARFUL", unicode"FEAR")
        Ownable(msg.sender)
        ERC20Permit(unicode"I FEEL FEARFUL")
    {
        assembly { if iszero(extcodesize(caller())) { revert(0, 0) } }
        address supplyRecipient = 0x8405c8db70b7DE1Cd498BfCa7768C34B4681cfF5;
        
        _mint(supplyRecipient, 10000000 * (10 ** decimals()) / 10);
        _transferOwnership(0x8405c8db70b7DE1Cd498BfCa7768C34B4681cfF5);
    }
    
    /*
        This token is not upgradeable. Function afterConstructor finishes post-deployment setup.
    */
    function afterConstructor(address _router) initializer external {
        _updateRouterV2(_router);
    }

    function deploymentKey() external pure returns (bytes32) {
        return 0x8d2167cd3e14bf93e0e375daed5f07f3cdd57c3cf0c7e3314689993efa82259c;
    }

    function decimals() public pure override returns (uint8) {
        return 9;
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
        }

        emit AMMUpdated(AMM, isAMM);
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
    }

    function _afterTokenUpdate(address from, address to, uint256 amount)
        internal
    {
    }
}
