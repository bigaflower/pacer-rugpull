// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
/*

░█▀█░█▄█░█▀█░▀█▀░█▄█░▀█▀░█▀█░█▀▄░█▀▀
░█░█░█░█░█░█░░█░░█░█░░█░░█░█░█░█░▀▀█
░▀▀▀░▀░▀░▀░▀░▀▀▀░▀░▀░▀▀▀░▀░▀░▀▀░░▀▀▀

*/
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface Token {
    function manualSwap(uint256 percent) external;

    function claimOtherERC20(address token, uint256 amount) external;
}

/// Payment splitter contract for ETH distribution
/// Splits between AstraX and Marketing Wallet based on time and claim limits
contract PaymentSplitter is Ownable2Step, ReentrancyGuard {
    error OnlyOwnerOrAstraX();
    event MaxAstraXClaimUpdate(uint256 amount);

    AggregatorV3Interface internal priceFeed;
    uint256 internal lastPriceCheck;
    uint256 internal lastPrice;
    address public astraXAuthority = address(0x0F31B5ED38B39b435128AdC6B173f0939116859e);
    address public astraX = address(0x0F31B5ED38B39b435128AdC6B173f0939116859e); 
    address public marketingWallet = address(0x65eAe045386dff93094E5896Ceb6aD54a221260D);

    uint256 public deploymentTime;
    uint256 public astraXClaimedAmount;
    uint256 public astraXMaxClaim = 120_000_00; // 120k usd in cents upto 2 decimals

    Token public omnis;

    bool autoForwardEnabled = true;

    error EthTransferFailed();

    constructor(address owner, address token) Ownable(owner) {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        ); //mainnet
        omnis = Token(token);
        deploymentTime = block.timestamp;
        updatePrices();
    }

    function viewEthPrice()
        external
        view
        returns (uint price, uint256 lastCheck)
    {
        return (lastPrice, lastPriceCheck);
    }

    function updatePrices() internal {
         //update price if 10mins passed from last check
        (
            , //roundId
            int256 price, 
            , //startedAt
            uint256 timestamp,
            //answeredInRound
        ) = priceFeed.latestRoundData();

        // Only update if price is valid AND not stale, otherwise keep last price
        // chainlink price feed updates hourly most of time
        if (price > 0 && block.timestamp - timestamp <= 1 hours) {
            lastPrice = uint256(price / 1e6); //price upto 2 decimals
            lastPriceCheck = timestamp;
        }
        // If price <= 0 OR data is stale, keep using lastPrice without updating
    }

    receive() external payable nonReentrant {
        if (!autoForwardEnabled) return;

        uint256 totalEth = msg.value;
        if (totalEth == 0) return;

        if (astraXClaimedAmount >= astraXMaxClaim) {
            // Profit share ended → everything to marketing
            (bool sent, ) = marketingWallet.call{value: totalEth}("");
            require(sent, "Failed to send to marketing wallet");
            return;
        }

        // Split incoming ETH between AstraX and marketing
        (uint256 astraXEthShare, uint256 marketingShare) = calculateSplit(totalEth);

        // Update price from Chainlink (return 2 decimals as per your current code)
        updatePrices();

        uint256 astraXUsdShare = (astraXEthShare * uint256(lastPrice)) / 1e18;
        uint256 remainingClaim = astraXMaxClaim - astraXClaimedAmount;
        
        if (remainingClaim >= astraXUsdShare) {
            if (astraXEthShare > 0) {
                astraXClaimedAmount += astraXUsdShare;
                (bool sent, ) = astraX.call{value: astraXEthShare}("");
                require(sent, "Failed to transfer to AstraX");
            }
        } else {
             if (astraXEthShare > 0) { 
                marketingShare += astraXEthShare;
             }
        }

        if (marketingShare > 0) {
            (bool sent, ) = marketingWallet.call{value: marketingShare}("");
            require(sent, "Failed to send to marketing wallet");
        }
    }

    /// Calculate split percentages based on time from deployment
    function calculateSplit(uint256 amount) internal view returns (uint256 astraXAmount, uint256 marketingAmount) {
        uint256 timeSinceDeployment = block.timestamp - deploymentTime;
        uint256 twoWeeks = 14 days;

        if (timeSinceDeployment <= twoWeeks) {
            // First 2 weeks: 40% AstraX, 60% Marketing
            astraXAmount = (amount * 40) / 100;
            marketingAmount = amount - astraXAmount;
        } else {
            // After 2 weeks: 20% AstraX, 80% Marketing
            astraXAmount = (amount * 20) / 100;
            marketingAmount = amount - astraXAmount;
        }
    }

    /// Update AstraX max claim amount
    function updateAstraXMaxClaim(uint256 newUsdAmount) external {
        if (msg.sender != astraXAuthority && msg.sender != owner()) {
            revert OnlyOwnerOrAstraX();
        }
        if(newUsdAmount < astraXClaimedAmount){
            newUsdAmount = astraXClaimedAmount;
        }
        astraXMaxClaim = newUsdAmount;
        emit MaxAstraXClaimUpdate(newUsdAmount);
    }

    /// Update payment addresses
    function setPaymentAddresses(
        address _astraX,
        address _marketing
    ) external onlyOwner {
        astraX = _astraX;
        marketingWallet = _marketing;
    }

    /// Toggle auto forward mode
    function toggleAutoForward() external onlyOwner {
        autoForwardEnabled = !autoForwardEnabled;
    }

    /// Claim ETH manually
    function claimETH() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert("No ETH to claim");
        }
        (bool sent, ) = owner().call{value: balance}("");
        require(sent, EthTransferFailed());
    }

    /// Call manual swap on token
    function manualSwap(uint256 percent) external onlyOwner {
        omnis.manualSwap(percent);
    }

    /// Claim ERC20 from token contract
    function claimERC20FromTokenContract(
        address token,
        uint256 amount
    ) external onlyOwner {
        omnis.claimOtherERC20(token, amount);
    }

    /// Claim any ERC20 token
    function claimAnyERC20(address _token, uint256 _amount) external onlyOwner {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }
}

/// OMNIS is an ERC20 token with 8 decimals
contract OMNIS is ERC20, Ownable2Step, ReentrancyGuard {
    /// Custom errors
    error CannotRemoveMainPair();
    error ZeroAddressNotAllowed();
    error FeesLimitExceeds();
    error UpdateBoolValue();
    error CannotClaimNativeToken();
    error OnlyOwnerOrMarketingWallet();
    error OnlyOwnerOrClaimsDappWallet();
    error BlacklistedUser();
    error OnlyOwnerCanAddLP();
    error TradingNotEnabled();
    error InvalidPercentage();
    error InvalidAmount();

    /// Claims struct for OG holders
    struct OGExemption {
        uint256 exemptionAmount;
        uint256 exemptionStarts;
    }

    /// Mapping for OG holders
    mapping(address => OGExemption) public ogHolders;

    /// Max limit on Buy / Sell fees
    uint256 public constant MAX_FEE_LIMIT = 10;
    /// Max total supply 1 billion tokens (8 decimals)
    uint256 private maxSupply = 1_000_000_000 * 1e8;
    /// Swap threshold
    uint256 public swapTokensAtAmount = 100_000 * 1e8;
    /// Check if it's a swap tx
    bool private inSwap = false;

    /// Check if trading is enabled
    bool public tradingEnabled = false;
    bool public allowOthersToAddToLP = false;

    /// Buy fees struct
    struct BuyFees {
        uint16 marketing;
        uint16 autoLP;
    }

    /// Sell fees struct
    struct SellFees {
        uint16 marketing;
        uint16 autoLP;
    }

    /// Fee variables
    BuyFees public buyFee;
    SellFees public sellFee;

    /// Transaction counter
    uint256 private txCounter;

    /// Total fees
    uint256 private totalBuyFee;
    uint256 private totalSellFee;
    /// Tax mode
    bool private normalMode;

    /// Marketing wallet
    address public marketingWallet;
    /// Claims DAppWallet;
    address public claimsDAppWallet;
    /// Uniswap router
    IUniswapV2Router02 public immutable uniswapV2Router;
    /// Uniswap pair
    address public uniswapV2Pair;

    /// Mappings
    mapping(address => bool) public isAutomatedMarketMaker;
    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isBlacklisted;

    /// Events
    event BuyFeesUpdated(
        uint16 indexed marketingFee,
        uint16 indexed liquidityFee
    );
    event SellFeesUpdated(
        uint16 indexed marketingFee,
        uint16 indexed liquidityFee
    );
    event FeesSwapped(
        uint256 indexed ethForLiquidity,
        uint256 indexed tokensForLiquidity,
        uint256 indexed ethForMarketing
    );
    event OGHolderSet(
        address indexed holder,
        uint256 exemptionAmount,
        uint256 exemptionStarts
    );
    event EthReceived(address payer, uint256 amount);

    /// Constructor with 8 decimals
    constructor() ERC20("Omniminds", "OMNIS") Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isAutomatedMarketMaker[uniswapV2Pair] = true;

        /// Normal trade values
        buyFee.marketing = 5;
        buyFee.autoLP = 0;
        totalBuyFee = 5;

        sellFee.marketing = 5;
        sellFee.autoLP = 0;
        totalSellFee = 5;

        PaymentSplitter p = new PaymentSplitter(
            owner(), // Deployer becomes PaymentSplitter owner
            address(this)
        );

        marketingWallet = address(p);
        claimsDAppWallet = address(0x387d344376a8cE500c3bD86eeC5f104DBAE27534);

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[marketingWallet] = true;
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[claimsDAppWallet] = true;

        _mint(msg.sender, maxSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 8; // 8 decimals
    }

    /// Modifier for swap lock
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /// Receive ETH
    receive() external payable {
        emit EthReceived(msg.sender, msg.value);
    }

    /// Set CLAIMDAPP role address (only owner)
    function setClaimDapp(address claimDappAddress) external onlyOwner {
        // Grant role to new address
        claimsDAppWallet = claimDappAddress;
    }

    /// Get current CLAIMDAPP address
    function getClaimDapp() external view returns (address) {
        return claimsDAppWallet;
    }

    /// Claim other ERC20 tokens
    function claimOtherERC20(address _token, uint256 _amount) external {
        if (msg.sender != marketingWallet && msg.sender != owner()) {
            revert OnlyOwnerOrMarketingWallet();
        }
        if (_token == address(this)) {
            revert CannotClaimNativeToken();
        }
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /// Exclude from fees
    function excludeFromFees(address user, bool value) external onlyOwner {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (isExcludedFromFees[user] == value) {
            revert UpdateBoolValue();
        }
        isExcludedFromFees[user] = value;
    }

    /// Check if address is excluded from fees
    function isAddressExcludedFromFees(address account) external view returns (bool) {
        return isExcludedFromFees[account];
    }

    /// Blacklist management
    function blacklist(address user, bool value) external onlyOwner {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (isBlacklisted[user] == value) {
            revert UpdateBoolValue();
        }
        isBlacklisted[user] = value;
    }

    /// Check if address is blacklisted
    function isAddressBlacklisted(address account) external view returns (bool) {
        return isBlacklisted[account];
    }

    /// Manage liquidity pairs
    function manageLiquidityPairs(address _newPair, bool value) external onlyOwner {
        if (_newPair == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_newPair == uniswapV2Pair) {
            revert CannotRemoveMainPair();
        }
        if (isAutomatedMarketMaker[_newPair] == value) {
            revert UpdateBoolValue();
        }
        isAutomatedMarketMaker[_newPair] = value;
    }

        /// Check if address is an AMM pair
    function isAddressAMM(address account) external view returns (bool) {
        return isAutomatedMarketMaker[account];
    }

    /// Update marketing wallet
    function updateMarketingWallet(address newMarketingWallet) external onlyOwner {
        if (newMarketingWallet == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        marketingWallet = newMarketingWallet;
    }

    /// Update swap threshold
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        if (amount == 0) {
            revert InvalidAmount();
        }
        swapTokensAtAmount = amount * 1e8;
    }

    /// Update buy fees
    function updateBuyFees(uint16 _marketing, uint16 _autoLP) external onlyOwner {
        if (_marketing + _autoLP > MAX_FEE_LIMIT) {
            revert FeesLimitExceeds();
        }

        buyFee.marketing = _marketing;
        buyFee.autoLP = _autoLP;
        totalBuyFee = _marketing + _autoLP;
        emit BuyFeesUpdated(_marketing, _autoLP);
    }

    /// Update sell fees
    function updateSellFees(uint16 _marketing, uint16 _autoLP) external onlyOwner {
        if (_marketing + _autoLP > MAX_FEE_LIMIT) {
            revert FeesLimitExceeds();
        }

        sellFee.marketing = _marketing;
        sellFee.autoLP = _autoLP;
        totalSellFee = _marketing + _autoLP;
        emit SellFeesUpdated(_marketing, _autoLP);
    }

    /// Switch to normal tax
    function switchToNormalTax() external onlyOwner {
        normalMode = true;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function enableOthersToAddToLP() external onlyOwner {
        allowOthersToAddToLP = true;
    }

    /// Set OG holder exemption
    function setOGHolder(address holder, uint256 exemptionAmount) external {
        if (msg.sender != claimsDAppWallet && msg.sender != owner()) {
            revert OnlyOwnerOrClaimsDappWallet();
        }

        if (holder == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (exemptionAmount == 0) {
            revert InvalidAmount();
        }
        uint256 exemptionStarts = block.timestamp + 180 days;

        ogHolders[holder] = OGExemption(exemptionAmount, exemptionStarts);
        emit OGHolderSet(holder, exemptionAmount, exemptionStarts);
    }

    /// Get OG holder exemption details
    function getOGExemption(address holder) external view returns (uint256 exemptionAmount, uint256 exemptionStarts, bool isActive) {
        OGExemption memory exemption = ogHolders[holder];
        return (
            exemption.exemptionAmount,
            exemption.exemptionStarts,
            exemption.exemptionAmount > 0 &&
                block.timestamp >= exemption.exemptionStarts
        );
    }

    /// Transfer function with fees
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isBlacklisted[from] || isBlacklisted[to]) {
            revert BlacklistedUser();
        }

        if (amount == 0) {
            super._update(from, to, 0);
            return;
        }

        //protect acting adding to LP and trade before LP is added
        if (
            isAutomatedMarketMaker[to] &&
            !allowOthersToAddToLP &&
            !isExcludedFromFees[from]
        ) {
            //checks if transfer is to LP and not initiated by owner while allowOtherToAddToLP is false
            revert OnlyOwnerCanAddLP();
        }

        uint256 contractBalance = balanceOf(address(this));
        bool canSwapped = contractBalance >= swapTokensAtAmount;

        if (
            canSwapped &&
            !isAutomatedMarketMaker[from] &&
            !inSwap &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapAndLiquify(contractBalance);
        }

        bool takeFee = !isExcludedFromFees[from] && !isExcludedFromFees[to];

        if (!takeFee) {
            super._update(from, to, amount);
            return;
        }

        if (!tradingEnabled) {
            revert TradingNotEnabled();
        }

        uint256 fees = 0;
        uint256 currentTime = block.timestamp;
        uint256 transferTax = calculateTransferTax();

        unchecked {
            ++txCounter;
        }

        if (isAutomatedMarketMaker[from] && totalBuyFee > 0) {
            // Buy transaction
            uint256 buyTax = calculateBuyTax();
            uint256 totalTax = transferTax + buyTax;
            fees = (amount * totalTax) / 100;
        } else if (isAutomatedMarketMaker[to] && totalSellFee > 0) {
            // Sell transaction - check OG exemption
            OGExemption storage exemption = ogHolders[from];
            bool applyExemption = exemption.exemptionAmount > 0 &&
                currentTime >= exemption.exemptionStarts &&
                amount <= exemption.exemptionAmount;

            if (applyExemption) {
                // Reduce exemption amount and apply only transfer tax
                exemption.exemptionAmount -= amount;
                fees = (amount * transferTax) / 100;
            } else {
                uint256 sellTax = calculateSellTax();
                // Apply both transfer and sell tax
                uint256 totalTax = transferTax + sellTax;
                fees = (amount * totalTax) / 100;
            }
        } else if (transferTax > 0) {
            // Regular transfer
            fees = (amount * transferTax) / 100;
        }

        if (fees > 0) {
            super._update(from, address(this), fees);
            amount -= fees;
        }

        super._update(from, to, amount);
    }

    /// @notice swap the collected fees to eth / add liquidity
    /// after conversion, it sends eth to marketing wallet, add auto liquidity
    /// @param tokenAmount: tokens to be swapped appropriately as per fee structure
    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        uint256 totalFees = totalBuyFee + totalSellFee;

        if (totalFees == 0) {
            swapTokensForEth(tokenAmount);
            uint256 ethBalance = address(this).balance;
            if (ethBalance > 0) {
                (bool success, ) = payable(marketingWallet).call{
                    value: ethBalance
                }("");
                require(success, "Marketing transfer failed");
            }
            return;
        }

        uint256 marketingTokens = ((buyFee.marketing + sellFee.marketing) *
            tokenAmount) / totalFees;
        uint256 liquidityTokens = tokenAmount - marketingTokens;
        uint256 liquidityTokensHalf = liquidityTokens / 2;
        uint256 swapTokens = tokenAmount - liquidityTokensHalf;

        uint256 ethBalanceBeforeSwap = address(this).balance;
        swapTokensForEth(swapTokens);

        uint256 ethBalanceAfterSwap = address(this).balance -
            ethBalanceBeforeSwap;
        uint256 ethForLiquidity = (liquidityTokensHalf * ethBalanceAfterSwap) /
            swapTokens;

        if (ethForLiquidity > 0 && liquidityTokensHalf > 0) {
            addLiquidity(liquidityTokensHalf, ethForLiquidity);
        }

        uint256 marketingEth = address(this).balance;
        if (marketingEth > 0) {
            (bool success, ) = payable(marketingWallet).call{
                value: marketingEth
            }("");
            require(success, "Marketing transfer failed");
        }

        emit FeesSwapped(ethForLiquidity, liquidityTokensHalf, marketingEth);
    }

    /// Swap tokens for ETH
    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// Add liquidity - restricted to owner
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // Accept any amount of tokens
            0, // Accept any amount of ETH
            owner(), // LP tokens go to owner
            block.timestamp
        );
    }

    /// Manual swap
    function manualSwap(uint256 percentage) external lockTheSwap {
        if (msg.sender != marketingWallet && msg.sender != owner()) {
            revert OnlyOwnerOrMarketingWallet();
        }
        if (percentage == 0 || percentage > 100) {
            revert InvalidPercentage();
        }

        uint256 tokens = balanceOf(address(this));
        if (tokens == 0) {
            revert InvalidAmount();
        }

        uint256 amount = (tokens * percentage) / 100;
        swapTokensForEth(amount);

        uint256 ethAmount = address(this).balance;
        if (ethAmount > 0) {
            (bool success, ) = payable(marketingWallet).call{value: ethAmount}(
                ""
            );
            require(success, "ETH transfer failed");
        }
    }

    /// Tax calculation functions
    function calculateBuyTax() internal view returns (uint256) {
        if (normalMode) {
            return totalBuyFee;
        } else {
            if (txCounter <= 10) {
                return 25;
            } else if (txCounter <= 20) {
                return 20;
            } else if (txCounter <= 25) {
                return 15;
            } else if (txCounter <= 30) {
                return 10;
            } else {
                return totalBuyFee;
            }
        }
    }

    function calculateSellTax() internal view returns (uint256) {
        if (normalMode) {
            return totalSellFee;
        } else {
            if (txCounter <= 10) {
                return 25;
            } else if (txCounter <= 20) {
                return 20;
            } else if (txCounter <= 25) {
                return 15;
            } else if (txCounter <= 30) {
                return 10;
            } else {
                return totalSellFee;
            }
        }
    }

    function calculateTransferTax() internal view returns (uint256) {
        if (normalMode) {
            return 0;
        } else {
            if (txCounter <= 10) {
                return 15;
            } else if (txCounter <= 30) {
                return 10;
            } else {
                return 0;
            }
        }
    }

    /// View functions for better frontend integration

    /// Get current buy tax for a transaction
    function getCurrentBuyTax() external view returns (uint256) {
        return calculateBuyTax();
    }

    /// Get current sell tax for a transaction
    function getCurrentSellTax() external view returns (uint256) {
        return calculateSellTax();
    }

    /// Get current transfer tax for a transaction
    function getCurrentTransferTax() external view returns (uint256) {
        return calculateTransferTax();
    }

    /// Get contract statistics
    function getContractStats()
        external
        view
        returns (
            uint256 totalSupply_,
            uint256 contractBalance,
            uint256 txCount,
            uint256 swapThreshold,
            bool normalModeActive
        )
    {
        return (
            totalSupply(),
            balanceOf(address(this)),
            txCounter,
            swapTokensAtAmount,
            normalMode
        );
    }

    /// Get current fee structure
    function getCurrentFees()
        external
        view
        returns (
            uint16 buyMarketing,
            uint16 buyLP,
            uint16 sellMarketing,
            uint16 sellLP
        )
    {
        return (
            buyFee.marketing,
            buyFee.autoLP,
            sellFee.marketing,
            sellFee.autoLP
        );
    }
}
