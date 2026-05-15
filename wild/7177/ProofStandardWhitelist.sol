// SPDX-License-Identifier: None

pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./interfaces/IERC721A.sol";
import "./interfaces/ITeamFinanceLocker.sol";
import "./interfaces/ITokenWhitelist.sol";

/// This token was incubated and launched by PROOF: https://proofplatform.io/projects.

contract Token is
    ITokenWhitelist,
    Initializable,
    ERC20Upgradeable,
    OwnableUpgradeable
{
    struct UserInfo {
        bool isFeeExempt;
        bool isTxLimitExempt;
        bool isWhitelisted;
    }

    struct BuyInfo {
        uint32 lastBlock;
        uint8 count;
    }

    address public pair;
    address payable public mainWallet;
    address payable public secondaryWallet;
    address public futureOwner;
    IUniswapV2Router02 public uniswapV2Router;

    uint256 public whitelistEndTime;
    uint256 public whitelistDuration;
    uint256 public launchedAt;
    uint256 public maxWallet;
    uint256 public initMaxWallet;
    uint256 public swapping;
    uint256 public swapTokensAtAmount;
    uint256 public maxSwapsPerBlock;
    uint256 public restingBuyTotal;
    uint256 public restingSellTotal;
    uint256 public lockID;
    uint256 public lpLockDuration;
    uint8 public maxBuysPerBlock;

    bool public isWhitelistActive;
    bool public checkMaxHoldings = true;
    bool public maxWalletChanged;
    bool public swapEnabled;
    bool public buyTaxesSettled;
    bool public sellTaxesSettled;
    bool public proofFeeReduced;
    bool public proofFeeRemoved;
    bool public cancelled;
    bool public buysPerBlockLimited = false;

    FeeInfo public feeTokens;
    FeeInfo public buyFees;
    FeeInfo public sellFees;

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => uint256) public swapThrottle;
    mapping(address => BuyInfo) private _buyInfo; // per-origin rolling counter

    IDataStore public immutable DATA_STORE;
    DataStoreAddressResponse public addresses;
    DataStoreLimitsResponse public limits;

    event SwapAndLiquify(uint256 tokensAutoLiq, uint256 ethAutoLiq);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event TokenCancelled(uint256 returnedETH);

    constructor(IDataStore dataStore) {
        DATA_STORE = dataStore;
        _disableInitializers();
    }

    function initialize(
        bytes calldata params
    ) public payable initializer lockTheSwap {
        TokenInfo memory token = abi.decode(params, (TokenInfo));
        __ERC20_init(token.name, token.symbol);
        __Ownable_init(token.owner);
        futureOwner = token.futureOwner;
        DataStoreLimitsResponse memory _limits = DATA_STORE.getLimits();
        limits = _limits;

        restingBuyTotal = token.buyFees.total * 100;
        restingSellTotal = token.sellFees.total * 100;
        (token.buyFees.proof, token.sellFees.proof) = (700, 700); // Start at 5% (500 basis points) instead of 2%
        token.buyFees.liquidity *= 100;
        token.buyFees.secondary *= 100;
        token.sellFees.liquidity *= 100;
        token.sellFees.secondary *= 100;

        //fees validate based on 100th precision and recalculates total
        _validateFees(token.buyFees, token.sellFees);
        token.buyFees.main =
            2000 -
            token.buyFees.proof -
            token.buyFees.secondary -
            token.buyFees.liquidity; // Start at 20% (2000 basis points) instead of 15%
        token.buyFees.total = 2000; // Start at 20% (2000 basis points) instead of 15%
        token.sellFees.main =
            2500 -
            token.sellFees.proof -
            token.sellFees.secondary -
            token.sellFees.liquidity; // Start at 25% (2500 basis points) instead of 20%
        token.sellFees.total = 2500; // Start at 25% (2500 basis points) instead of 20%

        buyFees = token.buyFees;
        sellFees = token.sellFees;

        // set addresses
        mainWallet = payable(token.mainWallet);
        secondaryWallet = payable(token.secondaryWallet);

        DataStoreAddressResponse memory _addresses = DATA_STORE
            .getPlatformAddresses();
        addresses = _addresses;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            _addresses.router
        );
        uniswapV2Router = _uniswapV2Router;

        pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        // set basic data

        lpLockDuration = token.lpLockDuration;
        swapTokensAtAmount =
            (token.totalSupply * _limits.swapTokensAtAmount) /
            _limits.denominator; // 125 / 100000

        initMaxWallet = token.initMaxWallet;
        maxWallet = (token.totalSupply * token.initMaxWallet) / 100000; // 100 = .1%
        maxSwapsPerBlock = 4;

        userInfo[address(this)] = UserInfo(true, true, true);
        userInfo[pair].isTxLimitExempt = true;
        userInfo[pair].isWhitelisted = true;

        whitelistDuration = token.whitelistDuration;
        _setWhitelisted(token.whitelist);

        uint256 amountToPair = (token.totalSupply * token.percentToLP) / 100;
        super._update(address(0), address(this), amountToPair); // mint to contract for liquidity
        super._update(address(0), owner(), token.totalSupply - amountToPair); // mint to proof wallet for distribution
        _approve(address(this), address(uniswapV2Router), type(uint256).max);
        addLiquidity(amountToPair, msg.value, address(this));
    }

    function launch(
        uint256 bundleBuyAmount,
        uint256 lastBlockTimestamp,
        bytes32 lastBlockParentHash
    ) external payable onlyOwner lockTheSwap {
        require(
            block.timestamp <= lastBlockTimestamp + 12 &&
                blockhash(block.number - 1) == lastBlockParentHash,
            "Forked Block"
        );
        if (launchedAt != 0 || cancelled) {
            revert InvalidConfiguration();
        }
        // enable trading
        checkMaxHoldings = true;
        swapEnabled = true;
        whitelistEndTime = block.timestamp + whitelistDuration;
        isWhitelistActive = true;
        buysPerBlockLimited = true;
        maxBuysPerBlock = 3;
        launchedAt = block.timestamp;

        if (bundleBuyAmount != 0) {
            //execute bundle buy
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(this);
            uniswapV2Router.swapExactETHForTokens{value: bundleBuyAmount}(
                0,
                path,
                futureOwner,
                block.timestamp
            );
        }

        // lock liquidity
        uint256 lpBalance = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(addresses.locker, lpBalance);

        lockID = ITeamFinanceLocker(addresses.locker).lockToken{
            value: address(this).balance
        }(
            pair,
            futureOwner,
            lpBalance,
            block.timestamp + lpLockDuration,
            false,
            address(0)
        );
    }

    function cancel() external onlyOwner lockTheSwap {
        if (launchedAt != 0) {
            revert InvalidConfiguration();
        }

        IERC20(pair).approve(
            address(uniswapV2Router),
            IERC20(pair).balanceOf(address(this))
        );
        uint256 ethAmt = uniswapV2Router
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),
                IERC20(pair).balanceOf(address(this)),
                0, // liq pool should be untouchable
                0, // liq pool should be untouchable
                msg.sender,
                block.timestamp
            );
        emit TokenCancelled(ethAmt);

        cancelled = true;

        // send the tokens and eth back to the owner
        uint256 bal = address(this).balance;
        if (bal > 0) {
            address(msg.sender).call{value: bal}("");
        }
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        //tx.origin allows 2-step locker
        if (
            swapping == 2 ||
            from == address(this) ||
            to == futureOwner ||
            amount == 0 ||
            tx.origin == owner()
        ) {
            //Allows Proof or the futureOwner to transfer tokens pre-launch
            super._update(from, to, amount);
            return;
        }

        if (launchedAt == 0) {
            revert TradingNotEnabled();
        }

        UserInfo memory sender = userInfo[from];
        UserInfo memory recipient = userInfo[to];

        if (isWhitelistActive) {
            if (block.timestamp < whitelistEndTime) {
                if (!sender.isWhitelisted || !recipient.isWhitelisted) {
                    revert NotWhitelisted();
                }
            } else {
                isWhitelistActive = false;
                buysPerBlockLimited = false;
            }
        }

        if (buysPerBlockLimited && from == pair) {
            address origin = tx.origin;
            BuyInfo storage info = _buyInfo[origin];

            if (info.lastBlock != uint32(block.number)) {
                info.lastBlock = uint32(block.number);
                info.count = 0;
            }

            unchecked {
                info.count++;
            }
            require(
                info.count <= maxBuysPerBlock,
                "Too many buys in this block from one origin"
            );
        }

        //start at anywhere from 0.1% to 0.5%, increase by 0.1%, every 10 blocks, until it reaches 1%
        if (!maxWalletChanged) {
            uint256 secondsPassed = block.timestamp - launchedAt;
            uint256 percentage = initMaxWallet + (100 * (secondsPassed / 120));
            if (percentage > 950) {
                percentage = 1000;
                maxWalletChanged = true;
                checkMaxHoldings = false;
                maxWallet = totalSupply();
            } else {
                uint256 newMax = (totalSupply() * percentage) / 100000;
                if (newMax != maxWallet) {
                    maxWallet = newMax;
                }
            }
        }

        if (checkMaxHoldings) {
            if (
                !recipient.isTxLimitExempt && amount + balanceOf(to) > maxWallet
            ) {
                revert ExceedsMaxWalletAmount();
            }
        }

        uint256 total = feeTokens.total;
        bool canSwap = total >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            to == pair &&
            swapThrottle[block.number] < maxSwapsPerBlock
        ) {
            ++swapThrottle[block.number];
            if (swapTokensAtAmount > amount) {
                processFees(total, amount);
            } else {
                processFees(total, swapTokensAtAmount);
            }
        }

        if (!sender.isFeeExempt && !recipient.isFeeExempt) {
            FeeInfo storage _buyFees = buyFees;
            FeeInfo storage _sellFees = sellFees;

            if (!proofFeeRemoved) {
                uint256 secondsPassed = block.timestamp - launchedAt;
                if (!proofFeeReduced && secondsPassed > 1 days) {
                    uint256 totalBuy = _buyFees.total - _buyFees.proof;
                    if (totalBuy == 0) {
                        _buyFees.total = 0;
                        _buyFees.proof = 0;
                    } else {
                        _buyFees.main = _buyFees.main + 100; //move proof fee to main fee, total doesn't change (100 basis points = 1%)
                        _buyFees.proof = 100; //decrementing proof fee to 1% (100 basis points)
                    }
                    uint256 totalSell = _sellFees.total - _sellFees.proof;
                    if (totalSell == 0) {
                        _sellFees.total = 0;
                        _sellFees.proof = 0;
                    } else {
                        _sellFees.main = _sellFees.main + 100; //same as the buy fee logic (100 basis points = 1%)
                        _sellFees.proof = 100; //decrementing proof fee to 1% (100 basis points)
                    }
                    proofFeeReduced = true;
                } else if (secondsPassed > 61 days) {
                    // Extended from 31 days to 61 days
                    //move proof fee to main fee
                    _buyFees.main += _buyFees.proof;
                    _sellFees.main += _sellFees.proof;
                    _buyFees.proof = 0;
                    _sellFees.proof = 0;
                    proofFeeRemoved = true;
                } else {
                    if (!buyTaxesSettled) {
                        uint256 restingTotal = restingBuyTotal;
                        uint256 feeTotal;
                        if (secondsPassed < 1801) {
                            // 30 minutes (1800 seconds) for buy tax degradation
                            //fee starts at 20% (2000 basis points), decreases by 1% (100 basis points) every 2 minutes until we reach the restingTotal.
                            feeTotal = 2000 - ((secondsPassed / 120) * 100);
                        }
                        if (feeTotal <= restingTotal) {
                            uint256 proofVal = proofFeeRemoved
                                ? 0
                                : proofFeeReduced
                                ? 100
                                : 200;
                            _buyFees.total = restingTotal;
                            _buyFees.proof = proofVal;
                            _buyFees.main =
                                restingTotal -
                                _buyFees.liquidity -
                                _buyFees.secondary -
                                _buyFees.proof;
                            buyTaxesSettled = true;
                        } else if (feeTotal != _buyFees.total) {
                            _buyFees.total = feeTotal;
                            //700 = starting proof fee
                            //500 = amount we are going down to get to 2%,
                            //2000 = starting fee
                            //1500 = total amount we are decreasing the total fee by
                            _buyFees.proof =
                                700 -
                                (500 * (2000 - feeTotal)) /
                                1500; // at minute 19: 500 - (300 - (2000 - 1900) / 1500)
                            //extra fees get sent to the main wallet
                            _buyFees.main =
                                feeTotal -
                                _buyFees.liquidity -
                                _buyFees.secondary -
                                _buyFees.proof;
                        }
                    }
                    if (!sellTaxesSettled) {
                        uint256 restingTotal = restingSellTotal;
                        uint256 feeTotal;
                        if (secondsPassed < 2401) {
                            // 40 minutes (2400 seconds) for sell tax degradation
                            feeTotal = 2500 - ((secondsPassed / 120) * 100); // 25% (2500 basis points) decreases by 1% (100 basis points) every 2 minutes
                        }
                        if (feeTotal <= restingTotal) {
                            uint256 proofVal = proofFeeRemoved
                                ? 0
                                : proofFeeReduced
                                ? 100
                                : 200;
                            _sellFees.total = restingTotal;
                            _sellFees.proof = proofVal;
                            _sellFees.main =
                                restingTotal -
                                _sellFees.liquidity -
                                _sellFees.secondary -
                                _sellFees.proof;
                            sellTaxesSettled = true;
                        } else if (feeTotal != _sellFees.total) {
                            _sellFees.total = feeTotal;
                            //700 = starting proof fee
                            //500 = amount we are going down to get to 2%,
                            //2500 = starting fee
                            //2000 = total amount we are decreasing the total fee by
                            _sellFees.proof =
                                700 -
                                (500 * (2500 - feeTotal)) /
                                2000; // at minute 19: 500 - (300 - (2000 - 1900) / 1500)
                            //extra fees get sent to the main wallet
                            _sellFees.main =
                                feeTotal -
                                _sellFees.liquidity -
                                _sellFees.secondary -
                                _sellFees.proof;
                        }
                    }
                }
            }

            uint256 fees;
            if (to == pair) {
                //sell
                fees = _calculateFees(_sellFees, amount);
            } else if (from == pair) {
                //buy
                fees = _calculateFees(_buyFees, amount);
            }
            if (fees > 0) {
                amount -= fees;
                super._update(from, address(this), fees);
            }
        }

        super._update(from, to, amount);
    }

    function _calculateFees(
        FeeInfo memory feeRate,
        uint256 amount
    ) internal returns (uint256 fees) {
        if (feeRate.total != 0) {
            fees = (amount * feeRate.total) / 10000; // Divide by 10000 for basis points (100% = 10000 basis points)

            FeeInfo storage _feeTokens = feeTokens;
            _feeTokens.main += (fees * feeRate.main) / feeRate.total;
            _feeTokens.secondary += (fees * feeRate.secondary) / feeRate.total;
            _feeTokens.liquidity += (fees * feeRate.liquidity) / feeRate.total;
            _feeTokens.proof += (fees * feeRate.proof) / feeRate.total;
            _feeTokens.total += fees;
        }
    }

    function processFees(
        uint256 total,
        uint256 amountToSwap
    ) internal lockTheSwap {
        FeeInfo storage _feeTokens = feeTokens;

        FeeInfo memory swapTokens;
        swapTokens.main = (amountToSwap * _feeTokens.main) / total;
        swapTokens.secondary = (amountToSwap * _feeTokens.secondary) / total;
        swapTokens.liquidity = (amountToSwap * _feeTokens.liquidity) / total;
        swapTokens.proof = (amountToSwap * _feeTokens.proof) / total;

        uint256 amountToPair = swapTokens.liquidity / 2;

        swapTokens.total = amountToSwap - amountToPair;

        uint256 ethBalance = swapTokensForETH(swapTokens.total);

        FeeInfo memory ethSplit;

        ethSplit.main = (ethBalance * swapTokens.main) / swapTokens.total;
        if (ethSplit.main > 0) {
            address(mainWallet).call{value: ethSplit.main}("");
        }

        ethSplit.secondary =
            (ethBalance * swapTokens.secondary) /
            swapTokens.total;
        if (ethSplit.secondary > 0) {
            address(secondaryWallet).call{value: ethSplit.secondary}("");
        }

        ethSplit.proof = (ethBalance * swapTokens.proof) / swapTokens.total;
        if (ethSplit.proof > 0) {
            uint256 revenueSplit = (ethSplit.proof * 3) / 4; // 75% to PROOF revenue wallet
            uint256 stakingSplit = ethSplit.proof - revenueSplit; // 25% to PROOF Staking Contract

            address(addresses.proofStaking).call{value: stakingSplit}("");
            address(addresses.proofWallet).call{value: revenueSplit}("");
        }

        uint256 amountPaired;
        ethSplit.liquidity = address(this).balance;
        if (amountToPair > 0 && ethSplit.liquidity > 0) {
            amountPaired = addLiquidity(
                amountToPair,
                ethSplit.liquidity,
                address(0xdead)
            );
            emit SwapAndLiquify(amountToPair, ethSplit.liquidity);
        }

        uint256 liquidityAdjustment = swapTokens.liquidity -
            (amountToPair - amountPaired);

        _feeTokens.main -= swapTokens.main;
        _feeTokens.secondary -= swapTokens.secondary;
        _feeTokens.liquidity -= liquidityAdjustment;
        _feeTokens.proof -= swapTokens.proof;
        _feeTokens.total -=
            swapTokens.main +
            swapTokens.secondary +
            swapTokens.proof +
            liquidityAdjustment;
    }

    function swapTokensForETH(
        uint256 tokenAmount
    ) internal returns (uint256 ethBalance) {
        uint256 ethBalBefore = address(this).balance;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        ethBalance = address(this).balance - ethBalBefore;
    }

    function addLiquidity(
        uint256 tokenAmount,
        uint256 ethAmount,
        address recipient
    ) private returns (uint256) {
        (uint256 amountA, , ) = uniswapV2Router.addLiquidityETH{
            value: ethAmount
        }(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            recipient,
            block.timestamp
        );
        return amountA;
    }

    function changeFees(
        uint256 liquidityBuy,
        uint256 mainBuy,
        uint256 secondaryBuy,
        uint256 liquiditySell,
        uint256 mainSell,
        uint256 secondarySell
    ) external onlyOwner {
        if (!buyTaxesSettled || !sellTaxesSettled) {
            revert InvalidConfiguration();
        }
        liquidityBuy *= 100;
        mainBuy *= 100;
        secondaryBuy *= 100;
        liquiditySell *= 100;
        mainSell *= 100;
        secondarySell *= 100;

        FeeInfo memory _buyFees;
        _buyFees.liquidity = liquidityBuy;
        _buyFees.main = mainBuy;
        _buyFees.secondary = secondaryBuy;

        FeeInfo memory _sellFees;
        _sellFees.liquidity = liquiditySell;
        _sellFees.main = mainSell;
        _sellFees.secondary = secondarySell;

        (_buyFees.proof, _sellFees.proof) = _calculateProofFee();
        _validateFees(_buyFees, _sellFees);
        buyFees = _buyFees;
        sellFees = _sellFees;
    }

    function _calculateProofFee() internal returns (uint256, uint256) {
        uint256 secondsPassed = block.timestamp - launchedAt;
        if (secondsPassed > 61 days) {
            proofFeeRemoved = true;
            return (0, 0);
        } else if (secondsPassed > 1 days) {
            proofFeeReduced = true;
            return (100, 100); // 1% (100 basis points)
        } else {
            return (200, 200);
        }
    }

    function _validateFees(
        FeeInfo memory _buyFees,
        FeeInfo memory _sellFees
    ) internal view {
        _buyFees.total =
            _buyFees.liquidity +
            _buyFees.main +
            _buyFees.secondary;
        if (_buyFees.total == 0) {
            _buyFees.proof = 0;
        } else {
            if (_buyFees.proof == 700) {
                _buyFees.total += 200;
            } else {
                _buyFees.total += _buyFees.proof;
            }
        }

        _sellFees.total =
            _sellFees.liquidity +
            _sellFees.main +
            _sellFees.secondary;
        if (_sellFees.total == 0) {
            _sellFees.proof = 0;
        } else {
            if (_sellFees.proof == 700) {
                _sellFees.total += 200;
            } else {
                _sellFees.total += _sellFees.proof;
            }
        }

        if (
            _buyFees.total > limits.maxBuyFee * 100 ||
            _sellFees.total > limits.maxSellFee * 100
        ) {
            revert InvalidConfiguration();
        }
    }

    function addToWhitelist(address[] memory accounts) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; i++) {
            userInfo[accounts[i]].isWhitelisted = true;
        }
    }

    function removeFromWhitelist(address[] memory accounts) external onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; i++) {
            userInfo[accounts[i]].isWhitelisted = false;
        }
    }

    function setFeeExempt(address account, bool value) public onlyOwner {
        userInfo[account].isFeeExempt = value;
    }

    function setFeeExempt(address[] memory accounts) public onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; i++) {
            userInfo[accounts[i]].isFeeExempt = true;
        }
    }

    function setTxLimitExempt(address account, bool value) public onlyOwner {
        userInfo[account].isTxLimitExempt = value;
    }

    function setTxLimitExempt(address[] memory accounts) public onlyOwner {
        uint256 len = accounts.length;
        for (uint256 i; i < len; i++) {
            userInfo[accounts[i]].isTxLimitExempt = true;
        }
    }

    function setMainWallet(address newWallet) external onlyOwner {
        mainWallet = payable(newWallet);
    }

    function setSecondaryWallet(address newWallet) external onlyOwner {
        secondaryWallet = payable(newWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setSwapAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount;
    }

    function setMaxSwapsPerBlock(uint256 _maxSwaps) external onlyOwner {
        maxSwapsPerBlock = _maxSwaps;
    }

    function manualSwapBack(uint256 percentTimesTen) external onlyOwner {
        uint256 _amountToSwap = (feeTokens.total * percentTimesTen) / 1000; //allows for .1% precision
        processFees(feeTokens.total, _amountToSwap);
    }

    function _setWhitelisted(address[] memory accounts) internal {
        uint256 len = accounts.length;
        for (uint256 i; i < len; i++) {
            userInfo[accounts[i]].isWhitelisted = true;
        }
    }

    function withdrawStuckTokens() external onlyOwner {
        super._update(
            address(this),
            _msgSender(),
            balanceOf(address(this)) - feeTokens.total
        );
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(address(0xdead));
    }

    modifier lockTheSwap() {
        swapping = 2;
        _;
        swapping = 1;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function version() public pure returns (uint8) {
        return 4;
    }

    function withdrawkETH() external onlyOwner {
        require(address(this).balance > 0, "No ETH balance");
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No token balance");
        require(token.transfer(msg.sender, balance), "Transfer failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
