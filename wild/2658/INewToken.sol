// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import { IPresale} from "./IPresale.sol";

interface INewToken {
    struct InitParams {
        address owner;
        address taxWallet;
        address stakingFacet;
        address v2router;
        bool isFreeTier;
        uint256 minLiq; 
        uint256 supply;
        uint256 initTaxType; //0-time,1-buyCount,2-hybrid
        uint256 initInterval; //seconds 0-1 hour(if 1m: 1m, 3m, 6m, 10m)
        uint256 countInterval; //0-100 
        uint256  maxBuyTax; //40%
        uint256  minBuyTax; //0
        uint256  maxSellTax; //40%
        uint256  minSellTax; //0
        uint256  lpTax; //0-90 of buy or sell tax
        uint256 maxWallet;
        uint256 maxTx;
        uint256 preventSwap;
        uint256 maxSwap;
        uint256 taxSwapThreshold;
        string  name;
        string  symbol;
    }
    
    struct TeamParams {
        address team1;
        uint256 team1p; 
        uint256 cliffPeriod; 
        uint256 vestingPeriod;
        bool isAdd;
    }

	function rescueERC20(address _address) external;
	function increaseLimits(uint256 maxwallet, uint256 maxtx) external;
	function startTrading(uint256 lockPeriod, bool shouldBurn, address router) external;
    //require trading and presale not started
    function addPresale(address presale, uint256 percent, IPresale.PresaleParams memory newdetails) external;
    //require caller to be presale address
    function finPresale() external;
    function refPresale() external;
    //requires presale not started and trading not started
    function addTeam(TeamParams memory params) external;
    //what if we remove team out from init?
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);

}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
