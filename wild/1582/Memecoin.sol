// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IUniswapV2Router.sol";
import "./IUniswapV2Factory.sol";
import "./ERC20.sol";

contract MemeCoin is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1000000000 * 10**18; // Total supply tokens = 1bn
    uint256 public constant TOTAL_BUY_TOKENS = 800000000 * 10**18; // Total tokens to buy = 800mn
    uint256 public constant LIQUIDITY_TOKENS = 200000000 * 10**18; // Total tokens to for LP = 200mn
    uint256 public constant BUY_PRICE_DIFFERENCE_PERCENT = 1000; // Difference in buy price as percentage
    uint256 public constant TARGET_LIQUIDITY = 4 * 10**18; // Target liquidity in ETH, assuming 18 decimals
    address payable public constant REVENUE_ACCOUNT = payable(0xCDE357ABBdf15Da7CCE4B51CE70a1d0F08DfB782); // Fee collection address
    uint256 public sanityTokenAmount = 100 * 10 ** 18;
    uint8 public constant FEE_PERCENTAGE = 2; // Fee percentage

    uint8 private buying; //tracks contract buying state to restrict pre-listing transfers
    uint8 private selling;//tracks contract selling state to restrict pre-listing transfers
    IUniswapV2Router public uniswapRouter;
    address public lpAddress;
    string public picture;
    address public taxWallet;
    address public bullaDeployer; //authorized address where all sales of the Memecoin  are done from.
    bool public listed;
    bool public degen;
    uint256 public totalETHBought; // Total ETH paid for tokens buying
    uint256 public totalTokensBought; // Total tokens bought
    uint256 public maxWalletAmount; // Total amount of tokens a wallet can hold
    uint256 public buyTax;
    uint256 public sellTax;
    uint256 public devTaxTokens;// Tax tokens accumulated off all taxes {buy & sell}

    mapping(address => uint256) public contributions; // Track ETH contributions
    mapping(address => uint256) public tokens; // Track bought tokens

    constructor(
        address _bullaDeployer,
        address _router,
        address _taxWallet,
        uint256 _maxWalletAmount,
        uint256 _buyTax,
        uint256 _sellTax,
        string memory _name,
        string memory _ticker,
        string memory _picture,
        bool _degen
    ) ERC20(_name, _ticker) {
        bullaDeployer = _bullaDeployer;
        uniswapRouter = IUniswapV2Router(_router);
        if (_maxWalletAmount == 0) {
            maxWalletAmount = type(uint256).max;//No Wallet limit
        } else if(_maxWalletAmount == 1){
            maxWalletAmount = (TOTAL_SUPPLY * 5) / 1000;//0.5% Wallet limit
        } else if(_maxWalletAmount == 2){
            maxWalletAmount = TOTAL_SUPPLY * 1 / 100; //1% Wallet limit
        }
        require(_maxWalletAmount == 0 || _maxWalletAmount == 1 || _maxWalletAmount == 2,'Invalid Max Wallet Amount');
        picture = _picture;
        taxWallet = _taxWallet;
        buyTax = _buyTax;
        sellTax = _sellTax;
        degen = _degen;
        listed = false;
        totalETHBought = 0;

        //Create Pair
        lpAddress = IUniswapV2Factory(uniswapRouter.factory()).createPair(address(this), uniswapRouter.WETH());
        
        //Max approve token for Router
        _approve(address(this), address(uniswapRouter), type(uint256).max);

        _mint(address(this), TOTAL_SUPPLY);
    }


    modifier onlyTaxWallet() {
        require(tx.origin == taxWallet,"Unauthorized Reset Attempt");
        _;
    }


    modifier onlyBulla() {
        require(msg.sender == bullaDeployer,"Unauthorized Interaction");
        _;
    }


    // @notice transfer function that handles all the buy and sell tax logic.
    // @param sender this is the address of the user where tokens are sent from.
    // @param recepient this the address of the user receiving the tokens.
    // @param amount this is the amount of tokens to be sent.
    function _transfer(address sender, address recipient, uint256 amount) internal override {
            uint256 tax;
            address _weth = uniswapRouter.WETH();
        if (listed){
            updateMaxWalletAmount(lpAddress,_weth);
            
            //Buy tax
            if (buyTax > 0 && sender == lpAddress && recipient != taxWallet){
                    tax = amount * buyTax / 100;
                    uint256 taxedAmount = amount - tax;
                    devTaxTokens = devTaxTokens + tax;
                    amount = taxedAmount;
                    super._transfer(sender, address(this), tax);
            }

            //Sell tax
            if (sellTax > 0 && recipient == lpAddress && sender!= taxWallet){
                    tax = amount * sellTax / 100;
                    uint256 taxedAmount = amount - tax;
                    devTaxTokens = devTaxTokens + tax;
                    amount = taxedAmount;
                    super._transfer(sender, address(this), tax);
            }

            if (recipient != taxWallet && recipient != lpAddress && recipient != address(0x000000000000000000000000000000000000dEaD)) {
                require(balanceOf(address(recipient)) + amount <= maxWalletAmount, "Transfer amount exceeds the max wallet amount");
            }


            super._transfer(sender, recipient, amount);
            if(sender != lpAddress && recipient != lpAddress){
                _swapAndLiquify();
            }
        }else{
            
            //Make sure only token contract can send tokens before listing
            if (recipient != address(this) || sender != address(this)) {
                require(buying > 0 || selling > 0,"Pre-listing transfers Not Allowed");
                buying = 0;
                selling = 0;
            }
            
            if (recipient != taxWallet && recipient != address(this) && recipient != lpAddress) {
                
                require(balanceOf(address(recipient)) + amount <= maxWalletAmount, "Transfer amount exceeds the max wallet amount");
            }

            super._transfer(sender, recipient, amount);
        }
    }

    // @notice allows a user buy a memecoin by sending ETHER.
    // @param buyer this is the address of the user buyingb the tokens.
    // @param slippageAmount this is the minimum amount allowed by user to be received during the purchase.
    function buyTokens(address buyer,uint256 slippageAmount) external payable onlyBulla {
        require(!listed, "Liquidity is already added to Uniswap");
        require(msg.value > 0, "Send ETH to buy tokens");

        buying = 1;

        uint256 fee = msg.value * uint256(FEE_PERCENTAGE) / 100;
        uint256 ethAmount = msg.value - fee;

        uint256 tokenAmount = calculateTokenAmount(ethAmount);
        uint256 currentPrice = tokenAmount/ethAmount;

        uint256 finalprice;

        if (_getRemainingAmount() == msg.value) {

            finalprice = currentPrice;
    
            if(tokenAmount > (TOTAL_BUY_TOKENS - totalTokensBought)){
                tokenAmount = TOTAL_BUY_TOKENS - totalTokensBought;
            }
        }

        totalTokensBought += tokenAmount;    
        contributions[buyer] += ethAmount;
    

        if(finalprice == 0){
            require(tokenAmount >= slippageAmount, "Slippage Amount Restriction");
        }

        if(buyTax > 0 && buyer != taxWallet){
            uint256 tax = tokenAmount * buyTax / 100;
            uint256 buyerTokens = tokenAmount - tax;
            devTaxTokens = devTaxTokens + tax;
            tokens[buyer] += buyerTokens;
            tokenAmount = buyerTokens;
        }else{
            tokens[buyer] += tokenAmount;
        }

        totalETHBought += ethAmount;

        _transfer(address(this), buyer, tokenAmount);
        bool success;
        (success, ) = REVENUE_ACCOUNT.call{value: fee}("");
        require(success, "Transfer failed");

        if (address(this).balance >= TARGET_LIQUIDITY && !listed) {
            _addLiquidity();
            _burnRemainingTokens();
        }
    }

    // @notice allows a user sell a memecoin.
    // @param seller this is the address of the user selling tokens.
    // @param tokenAmount this is the amount of tokens a user wants to sell.
    function sellTokens(address seller,uint256 tokenAmount) external onlyBulla {
        require(!listed, "Liquidity is already added to Uniswap");
        require(tokenAmount > 0, "Amount must be greater than 0");

        selling = 1;

        uint256 ethAmount = calculateEthAmount(seller,tokenAmount);

        if ((balanceOf(address(this)) + tokenAmount) == TOTAL_SUPPLY) {
            ethAmount = address(this).balance;

            if(!degen){
                contributions[seller] = 0;
            }

            totalETHBought = 0;
        } else {

            if(!degen){
                
                    contributions[seller] -= ethAmount;
                    totalETHBought -= ethAmount;
            }else{
                if(contributions[seller] < ethAmount){

                    uint subAmount;
                    if(tokenAmount > 0 && tokenAmount <= (tokens[seller] * 25 / 100)){
                        subAmount = contributions[seller] * 25 / 100;
                    } else if (tokenAmount >= (tokens[seller] * 25 / 100) && tokenAmount <= (tokens[seller] * 50 / 100)){
                        subAmount = contributions[seller] * 50 / 100;
                    } else if (tokenAmount >= (tokens[seller] * 50 / 100) && tokenAmount <= (tokens[seller] * 75 / 100)){
                        subAmount = contributions[seller] * 75 / 100;
                    } else if (tokenAmount >= (tokens[seller] * 75 / 100) && tokenAmount <= (tokens[seller] * 100 / 100)){
                        subAmount = contributions[seller] * 100 / 100;
                    }
                        contributions[seller] = contributions[seller] - subAmount;
                        totalETHBought -= ethAmount;                
                }else{
                  
                        totalETHBought -= ethAmount;
                }
            }

        }

       uint256 fee = ethAmount * uint256(FEE_PERCENTAGE) / 100;

       if(sellTax > 0 && seller != taxWallet){
            uint256 tax = tokenAmount * sellTax / 100;
            uint256 sellerTokens = tokenAmount - tax;
            tokens[seller] -= tokenAmount;
            devTaxTokens = devTaxTokens + tax;
            tokenAmount = sellerTokens;
        }else{
            tokens[seller] -= tokenAmount;
        }

        totalTokensBought -= tokenAmount; 
        
        _transfer(seller, address(this), tokenAmount);
        bool success;
        (success, ) = seller.call{value: ethAmount - fee}("");
        require(success, "Transfer failed");
        (success, ) = REVENUE_ACCOUNT.call{value: fee}("");
        require(success, "Transfer failed");

    }

    // @notice call to get the remaining ETHER amount required to be spent by users for the memecoin to be listed.
    // @returns A uint value indicating the remaining ETHER amount required to be spent by users for the memecoin to be listed.
    function getRemainingAmount() public view returns (uint256) {
        require(TARGET_LIQUIDITY > address(this).balance, "Liquidity target exceeded");

        return _getRemainingAmount();
    }

    // @notice allows the user calculate the minimum amount required to be received during a buy.
    // @param ethAmount this of ETHER to be used for the buy.
    // @param slippageAllowance this is the amount in percentage  used to calculate slippage.
    function slippage(uint256 ethAmount,uint256 slippageAllowance) public view returns(uint256) {
        uint256 fee = ethAmount * uint256(FEE_PERCENTAGE) / 100;
        ethAmount = ethAmount - fee;
         uint256 slippageAmount = calculateTokenAmount(ethAmount);
        if (buyTax > 0) {
            uint256 tax = slippageAmount * buyTax / 100;
            slippageAmount = slippageAmount - tax;
        }
        slippageAllowance = slippageAmount * slippageAllowance / 100;
        slippageAmount = slippageAmount - slippageAllowance;
        return slippageAmount;
    }

    // @notice call to get the remaining ETHER amount required to be spent by users for the memecoin to be listed.
    // @param ethAmount this an amount of ETHER to be used to buy.
    // @returns A uint value indicating the token amount a user would receive.
    function calculateTokenAmount(uint256 ethAmount) public view returns (uint256) {
        require(totalETHBought + ethAmount <= TARGET_LIQUIDITY, "Liquidity target exceeded");

        uint256 initialTokenPrice = _initialTokenPrice();
        uint256 tokenPrice = initialTokenPrice + ((initialTokenPrice * BUY_PRICE_DIFFERENCE_PERCENT / 100) * (totalETHBought + (ethAmount / 6)) / TARGET_LIQUIDITY);
        return ethAmount * 10**18 / tokenPrice;
    }

    // @notice call to get the ETHER amount sent to a user when tokens are sold.
    // @param user this is the address of the user.
    // @param tokenAmount this the amount of tokens a user want to sell.
    // @returns A uint value indicating the ETHER amount a user would receive.
    function calculateEthAmount(address user,uint256 tokenAmount) public view returns (uint256) {
        uint256 userTokens = tokens[user];
        require(userTokens >= tokenAmount, "Insufficient user token balance");

        uint256 value;
        if(!degen){

            return contributions[user] * tokenAmount / userTokens;
        }else{
            if(contributions[user] < totalETHBought){
                value = totalETHBought - contributions[user];
                value = value / 5;
                value = value + contributions[user];
            }else{
                value = totalETHBought;
            }
            return value * tokenAmount / userTokens;
        }
    }


    // @notice allows the creator of a memecoin set the minimum amount required to be met before a swap of the tax tokens occurs.
    // @param value this is the minimum amount required to be met before a swap of the tax tokens.
    function setSanityTokenAmount(uint256 newValue) external onlyBulla onlyTaxWallet {
        sanityTokenAmount = newValue * 10 ** 18;
    }


    // @notice allows the creator of a memecoin tax from the token.
    function removeTaxFees() external onlyBulla onlyTaxWallet {
        buyTax = 0;
        sellTax = 0;
    }


    // @notice function that adds liqudity to Uniswap once the Target Liquidity is met.
    function _addLiquidity() internal {
 
        listed = true;
        uniswapRouter.addLiquidityETH{ value: address(this).balance }(
            address(this),
            LIQUIDITY_TOKENS,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 amount = IERC20(lpAddress).balanceOf(address(this));

        //Burn LP
        IERC20(lpAddress).transfer(address(0x000000000000000000000000000000000000dEaD),amount);

        _swapAndLiquify();
    }

    // @notice function that burns the remaining tokens in the contract after liquidity is added.
    function _burnRemainingTokens() internal  {
        
        uint256 amount;
        if(devTaxTokens > 0){
            amount = IERC20(address(this)).balanceOf(address(this)) - devTaxTokens;
        }else{
            amount = IERC20(address(this)).balanceOf(address(this));
        }

        //Burn Remaining Tokens
        IERC20(address(this)).transfer(address(0x000000000000000000000000000000000000dEaD),amount);
    }


    // @notice fucntion that update the maxWalletAmount once the 6 ETHER requirement is met.
    function updateMaxWalletAmount(address _lpToken,address _weth) internal {
        if(maxWalletAmount == type(uint256).max) return;

        uint256 amount = IERC20(_weth).balanceOf(address(_lpToken));

        if (amount >= 6 ether) {
            maxWalletAmount = type(uint256).max;
        }
    }
    
    // @notice call to get the remaining ETHER amount required to be spent by users for the memecoin to be listed.
    // @returns A uint value indicating the remaining ETHER amount required to be spent by users for the memecoin to be listed.
    function _getRemainingAmount() internal view returns (uint256) {
    
        return (TARGET_LIQUIDITY - totalETHBought) * 100 / (100 - uint256(FEE_PERCENTAGE));
    }


    // Get initial ETH normalized price per token
    function _initialTokenPrice() internal pure returns (uint256){
 
        return TARGET_LIQUIDITY * 10**18 / ((TOTAL_BUY_TOKENS * BUY_PRICE_DIFFERENCE_PERCENT) / 375);      
    }

    // @notice function that swaps devTaxToken balance for ETHER.
    function _swapAndLiquify() private {

        if(devTaxTokens < sanityTokenAmount) return;
        _swapTokensForEth(devTaxTokens);
        devTaxTokens = 0;
        
    }

    // @notice function that executes the swaps devTaxToken balance for ETHER.
    function _swapTokensForEth(uint256 tokenAmount) private  {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }
}