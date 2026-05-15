// SPDX-License-Identifier: MIT
/*********************************************************************************************\
* Deployyyyer: https://deployyyyer.io
* Twitter: https://x.com/deployyyyer
* Telegram: https://t.me/Deployyyyer
/*********************************************************************************************/
pragma solidity ^0.8.23;
import {LibDiamond} from "./LibDiamond.sol";
//import {LibMeta} from "./LibMeta.sol";
import {IUniswapV2Factory, IUniswapV2Router02} from "../interfaces/INewToken.sol";



struct AppStorage {
    mapping(address => bool) validRouters; //parentOnly
    mapping(address => bool) allowedTokens; //parentOnly
    //this should be bool too
    mapping(address => address) launchedTokens; //parentOnly
    mapping(address => address) launchedPresale; //parentOnly
    //cost of launch, cost of promo, cost of setting socials is 2xpromoCostEth
    uint256 ethCost; //parentOnly
    uint256 deployyyyerCost; //parentOnly
    uint256 promoCostEth; //parentOnly
    uint256 promoCostDeployyyyer; //parentOnly
    address bridge; //parentOnly

    //mapping of user address to score
    mapping(address => uint256) myScore; //parentOnly

    //+1 for launch, +5 for liquidity add, +50 for lp burn, -100 for lp retrieve
    uint256 cScore; //cScore is transferred with ownership, cScore is deducted on lp retrieve

    
    //address deployyyyer;
    bool isParent;
    uint256 minLiq;
    //this can be a map with share and clain in a structure
    mapping(address => uint256) teamShare;
    mapping(address => uint256) teamClaim;
    
    uint256 teamBalance;

    uint256 cliffPeriod; //min 30days
    uint256 vestingPeriod;//min 1day max 10000 days avg 30days.


    mapping(address => bool)  isExTxLimit; //is excluded from transaction limit
    mapping(address => bool)  isExWaLimit; //is excluded from wallet limit
    mapping (address => uint256)  balances; //ERC20 balance
    mapping (address => mapping (address => uint256))  allowances; //ERC20 balance

    address payable taxWallet; //tax wallet for the token
    address payable deployyyyerCa; //deployyyyer contract address
    address payable stakingContract; //address of staking contract for the token
    address stakingFacet; //facet address, used to launch a staking pool
    address presaleFacet; //facet address, used to launch a presale
    address tokenFacet; //facet address, used to launch a ERC20 token
    uint256 stakingShare; //share of tax sent to its staking pool
    
    
    // Reduction Rules
    uint256  buyCount; 

    uint256 initTaxType; //0-time,1-buyCount,2-hybrid,3-none
    //interval*1, lastIntEnd+(interval*2), lastIntEnd+(interval*3)
    uint256 initInterval; //seconds 0-1 hour(if 1m: 1m, 3m, 6m, 10m)
    uint256 countInterval; //0-100 

    //current taxes
    uint256  taxBuy; 
    uint256  maxBuyTax; //40%
    uint256  minBuyTax; //0

    uint256  taxSell; 
    uint256  maxSellTax; //40%
    uint256  minSellTax; //0
    
    


    uint256  tradingOpened;

    // Token Information
    uint8   decimals;
    uint256   tTotal;
    string   name;
    string   symbol;

    // Contract Swap Rules 
    uint256 preventSwap; //50            
    uint256  taxSwapThreshold; //0.1%
    uint256  maxTaxSwap; //1%
    uint256  maxWallet; //1%
    uint256  maxTx;

    IUniswapV2Router02  uniswapV2Router;
    address  uniswapV2Pair;
    
    bool  tradingOpen; //true if liquidity pool is created
    bool  inSwap;
    bool  walletLimited;
    bool isFreeTier;
    bool isBurnt;
    bool isRetrieved;
    uint256 lockPeriod;
    
    //buy back tax calculations
    uint256 lpTax; //0-50 percent of tax amount 
    uint256 halfLp;
    uint256 lastSwap;

    uint256 presaleTs;
    uint256 presaleSt;
    address presale;

}

/*
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}
*/


contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }  
    
}

