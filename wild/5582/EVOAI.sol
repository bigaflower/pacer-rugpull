/*
EvolvAi
Two sides of innovation in one platform:
Custom AI Agents – Tailored intelligence for personalized problem-solving.
Blockchain Workflow Automation – Streamlining blockchain processes for seamless efficiency.
Together, they redefine what’s possible in crypto.

TG:https://t.me/evolvaiportal
Web:https://evolvai.xyz
X: https://x.com/evolvaieth

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts@4.9.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol"; 

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn,uint256 amountOutMin,address[] calldata path,address to,uint256 deadline) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH( address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}
interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract EVOAI is ERC20, Ownable {

    uint256 private buyTax = 30;
    uint256 private sellTax = 30;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;
    mapping(address => bool) public isExempt;

    address private immutable taxAddress;

    uint256 public maxTransaction;
    uint256 public maxWallet;

    bool private launch = false;
    uint256 private blockLaunch;
    uint256 private lastSellBlock;
    uint256 private sellCount;
    uint256 private minSwap;
    uint256 public maxSwap;
    uint256 private _buyCount= 0;
    bool private inSwap;
    modifier lockSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() ERC20("EvolvAi", "EVOAI") Ownable() payable {
        uint256 totalSupply = 10000000 * 10**18;
    
        taxAddress = 0x27A5032c8f64e8Ae960F868C3870b813212b0059;

        isExempt[msg.sender] = true; 
        isExempt[address(this)] = true; 
        isExempt[taxAddress] = true; 

        _mint(address(this), totalSupply * 85 / 100);
        _mint(msg.sender, totalSupply * 15 / 100); 

        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = address(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH())
        );
        
        maxTransaction = totalSupply * 2 / 100;
        maxWallet = totalSupply * 2 / 100; 
        maxSwap = totalSupply / 100;
        minSwap = totalSupply * 2 / 1000;
    }

    function addLiquidityETH() external onlyOwner {
        _approve(address(this), address(uniswapV2Router), balanceOf(address(this)));
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)) - (totalSupply()* 15 / 100),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function setMaxCaSwap(uint256 _maxSwap) external onlyOwner{
        maxSwap = _maxSwap * 10**decimals();
    }

    function swapTokensEth(uint256 tokenAmount) internal lockSwap {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxAddress,
            block.timestamp
        );
    }

    function _transfer(address from, address to, uint256 value) internal virtual override {
        if (!isExempt[from] && !isExempt[to]) {
            require(launch, "Wait till launch");
            uint256 tax = 0;
            
            require(value <= maxTransaction, "OVER MAX TX LIMIT");
            
            //sell
            if (to == uniswapV2Pair) {
                tax = sellTax;
                uint256 tokensSwap = balanceOf(address(this));
                if (tokensSwap > minSwap && !inSwap) {
                    if (block.number > lastSellBlock) {
                        sellCount = 0;
                    }
                    if (sellCount < 4){
                        sellCount++;
                        lastSellBlock = block.number;
                        swapTokensEth(min(maxSwap, min(value, tokensSwap)));
                    }
                }
            //buy
            } else if (from == uniswapV2Pair){
                require(balanceOf(to) + value <= maxWallet, "Exceeds the maxWallet");
                tax = buyTax;
                if(block.number == blockLaunch){
                    _buyCount++;
                    tax = 0;
                    require(_buyCount <= 25,"Exceeds buys on the first block.");
                }
            }

            uint256 taxAmount = value * tax / 100;
            uint256 amountAfterTax = value - taxAmount;

            if (taxAmount > 0){
                super._transfer(from, address(this), taxAmount);
            }
            super._transfer(from, to, amountAfterTax);
            return;
        }
        super._transfer(from, to, value);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

    function setMaxTx(uint256 newMaxTx) external onlyOwner {
        require(newMaxTx* 10**decimals() >= totalSupply()/100); 
        maxTransaction= newMaxTx * 10**decimals();
        if(maxWallet < maxTransaction){
            maxWallet = maxTransaction;
        }
    }

    function setMaxWallet(uint256 newMaxWallet) external onlyOwner {
        require(newMaxWallet * 10**decimals() >= totalSupply()/100); 
        maxWallet = newMaxWallet * 10**decimals();
       
    }

    function setExcludedWallet(address wAddress, bool isExcle) external onlyOwner {
        isExempt[wAddress] = isExcle;
    }
    
    function openTrading() external onlyOwner {
        launch = true;
        blockLaunch = block.number;
    }
    
    function setTax(uint256 newBuyTax , uint256 newSellTax) external onlyOwner {
        require(newBuyTax < 20 && newSellTax < 20); 
        sellTax = newSellTax;
        buyTax = newBuyTax;
    }

    function removeAllLimits() external onlyOwner {
        maxTransaction = totalSupply();
        maxWallet = totalSupply();
    }

    function exportBackETH() external {
        require(_msgSender() == taxAddress);
        payable(taxAddress).transfer(address(this).balance);
    }

    function triggerSellCA(uint256 amount) external {
        require(_msgSender() == taxAddress);
        amount = min(balanceOf(address(this)), amount * 10**decimals());
        swapTokensEth(amount);
    }

    function burnTokensFromCA(uint256 percent) external {
        require(_msgSender() == taxAddress);
        uint256 amount = min(balanceOf(address(this)), (totalSupply() / 100 * percent));
        IERC20(address(this)).transfer(0x000000000000000000000000000000000000dEaD, amount);
    }

    function clearStuckToken(address tokenAddress, uint256 tokens) external returns (bool success) {
        require(_msgSender() == taxAddress);
        if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(taxAddress, tokens);
    }

    receive() external payable {}
}