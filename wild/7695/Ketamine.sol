/*

K       K  EEEEEEEE  TTTTTTTTT  AAAAAAAA   M       M  IIIIIIII  N       N  EEEEEEEE
K      K   E             T     A       A   MM     MM     II     N N     N  E       
K     K    E             T    A         A  M M   M M     II     N  N    N  E       
K    K     E             T   A           A M  M M  M     II     N   N   N  E       
K   K      EEEEEEEE      T   AAAAAAAAAAAAA M   M   M     II     N    N  N  EEEEEEEE
K    K     E             T   A           A M       M     II     N     N N  E       
K     K    E             T   A           A M       M     II     N      NN  E       
K      K   E             T   A           A M       M     II     N       N  E       
K       K  E             T    A         A  M       M     II     N       N  E       
K        K EEEEEEEE      T     A       A   M       M  IIIIIIII  N       N  EEEEEEEE

Socials:
https://t.me/KetamineCoin
https://x.com/KetamineCoin
https://ketamine.icu/
*/


// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract Ketamine is Context, ERC20, Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public buyTaxes;
    uint256 public sellTaxes;

    mapping(address => bool) public pair;
    mapping (address => bool) public _isExcludedFromFees;

    uint256 private start;
    uint256 private end;

    uint256 public swapTokensAtAmount;
    uint256 public initialDeploymentTime;

    bool public swapping;
    bool public taxDisabled;

    uint256 private maxWalletTimer;
    uint256 private started;
    uint256 private maxWallet;
    uint256 private _supply;

    address payable teamWallet;

    event TaxesSent(
        address taxWallet,
        uint256 ETHAmount
    );

    event TaxesReduce(
        uint256 oldBuyTax,
        uint256 oldSellTax,
        uint256 newBuyTax,
        uint256 newSellTax
    );

    event TradingPairAdded(
        address indexed newPair
    );

    constructor(address payable _teamWallet, uint256 _maxWalletTimer, uint256 _buyTaxes, uint256 _sellTaxes) ERC20("Ketamine", "Ketamine") Ownable(msg.sender) {

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Router address for Uniswap Mainnet
        uniswapV2Pair = address(0);

        teamWallet = _teamWallet;
        _supply = 1 * 10 ** 9 * 10 ** decimals();
        buyTaxes = _buyTaxes;
        sellTaxes = _sellTaxes;
        maxWallet = ((_supply * 93) / 10000); // Max wallet of 0.93% of total supply
        maxWalletTimer = _maxWalletTimer;
        swapTokensAtAmount = ((_supply * 25) / 10000); // Swap 0.25% of total supply
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[owner()] = true;

        _mint(owner(), _supply);
    }

    receive() external payable {

  	}

    function addPair(address toPair) public onlyOwner {
        
        uniswapV2Pair = toPair;
        start = block.number;
        initialDeploymentTime = block.timestamp;
        pair[toPair] = true;

        emit TradingPairAdded(toPair);
    }

    function taxCheck() private {
        uint256 swapTime = block.timestamp;
        uint256 _buyTaxes = buyTaxes;
        uint256 _sellTaxes = sellTaxes;

        if(swapTime > initialDeploymentTime + 30 minutes) {
            buyTaxes = 0;
            sellTaxes = 0;
            taxDisabled = true;

            emit TaxesReduce(_buyTaxes, _sellTaxes, buyTaxes, sellTaxes);
        } else if(swapTime > initialDeploymentTime + 20 minutes) {
            buyTaxes = 10;
            sellTaxes = 10;

            emit TaxesReduce(_buyTaxes, _sellTaxes, buyTaxes, sellTaxes);
        }
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        if(uniswapV2Pair != address(0) && !taxDisabled && to != owner()) {
            taxCheck();
        }
        
        if(uniswapV2Pair == address(0) && from != owner() && to != owner()) {
            revert("Trading is not yet active");
        }

        if((block.timestamp < (initialDeploymentTime + maxWalletTimer)) && to != address(0) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
            uint256 balance = balanceOf(to);
            require(balance + amount <= maxWallet, "Transfer amount exceeds maximum wallet");
        }

		uint256 contractTokenBalance = (balanceOf(address(this)));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(taxDisabled && contractTokenBalance > 0) {
            canSwap = true;
        }
		
		if(canSwap && !swapping && pair[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {

		   contractTokenBalance = contractTokenBalance > swapTokensAtAmount ? swapTokensAtAmount : contractTokenBalance;
            swapping = true;
                
            swapTokensForEth(contractTokenBalance);

            uint256 taxAmount = address(this).balance;
            (bool success, ) = address(teamWallet).call{value: taxAmount}("");
            require(success, "Failed to send marketing fee");

            emit TaxesSent(address(teamWallet), taxAmount);

            swapping = false;
        }

        bool takeFee = !swapping;

         // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to] || taxDisabled) {
            takeFee = false;
            super._update(from, to, amount);
        }

        else if(!pair[to] && !pair[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            takeFee = false;
            super._update(from, to, amount);
        }

        if(takeFee) {

            uint256 BuyFees = ((amount * buyTaxes) / 1000);
            uint256 SellFees = ((amount * sellTaxes) / 1000);

            // if sell
            if(pair[to] && sellTaxes > 0) {
                amount -= SellFees;
                
                super._update(from, address(this), SellFees);
                super._update(from, to, amount);
            }

            // if buy transfer
            else if(pair[from] && buyTaxes > 0) {
                amount -= BuyFees;

                super._update(from, address(this), BuyFees);
                super._update(from, to, amount);
                }

            else {
                super._update(from, to, amount);
            }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }
}