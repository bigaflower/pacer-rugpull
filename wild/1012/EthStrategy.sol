// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success,) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value");
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 internal constant _NOT_ENTERED = 1;
    uint256 internal constant _ENTERED = 2;
    uint256 internal _status = _NOT_ENTERED;

    modifier nonReentrant() {
        require(_status == _NOT_ENTERED, "REENTRANCY");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract EthForwarder {
    address payable public immutable target;
    address public immutable authorizedSender;

    constructor(address payable target_, address authorizedSender_) {
        require(authorizedSender_ != address(0), "FORWARDER_INVALID_SENDER");
        target = target_;
        authorizedSender = authorizedSender_;
    }

    receive() external payable {
        require(msg.sender == authorizedSender, "FORWARDER_UNAUTHORIZED_SENDER");
        (bool ok,) = target.call{value: msg.value}("");
        require(ok, "FORWARD_FAILED");
    }
}

contract EthStrategy is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct FeeLot {
        uint256 ethAmount;
        uint256 entryPrice;
        uint64 createdAt;
    }

    struct BurnRecord {
        uint64 timestamp;
        uint64 sequence;
        uint256 lotId;
        uint256 ethSpent;
        uint256 entryPrice;
        uint256 targetPrice;
        uint256 tokensBurned;
        bool isPartial;
    }

    IUniswapV2Router02 public immutable uniswapV2Router;
    AggregatorV3Interface public priceOracle;
    address public immutable weth;
    address public immutable feeForwarder;

    string private _name;
    string private _symbol;
    uint256 private constant _TOTAL_SUPPLY = 100_000_000 * 10 ** 18;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    FeeLot[] internal feeLots;
    uint256 internal feeLotHead;
    uint256 public currentFees;
    address public teamWallet;
    uint256 public pendingTeamRewards;
    mapping(address => bool) public isBuyLimitExempt;

    uint256 public minGainBps = 500; // Set to 500 for ~5% burn threshold.
    uint256 public feeBufferBps = 30; // Set to 30 for ~0.3% buffer.
    uint256 public maxLotAge = 14 days;
    uint256 public dcaBps = 2500;
    uint256 public maxLotsPerWork = 5;
    uint256 public workRewardBps = 50; // 0.5% of ETH spent per work invocation goes to the caller
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    uint256 internal constant LOT_CLEANUP_THRESHOLD = 32;
    uint256 internal constant BURN_HISTORY_LIMIT = 25;

    uint256 public buyIncrement = 0.1 ether;
    uint256 public minLotEth = 0.1 ether;
    uint256 public pendingLotEth;
    uint256 public lastBuyBlock;
    mapping(address => bool) public trustedDepositors;

    uint8 public priceOracleDecimals;
    uint256 public maxPriceAge;

    bool public autoWorkEnabled;
    uint256 public autoWorkMaxLots = 1;
    bool private inAutoWork;

    uint8 private launchedToUniswap;
    address public uniswapPool;
    uint256 private launchTime;
    bool public launchLocked;
    bool public swapAndLiquifyEnabled;
    bool private inSwapAndLiquify;
    mapping(address => bool) public isMarketPair;
    bool private autoWorkQueued;

    uint256 public launchBlock;
    uint256 public burnMinOutBps = 500; // default to 5% of quoted output

    enum BurnFailureReason {
        None,
        SwapFailed,
        ZeroTokens
    }

    BurnFailureReason public lastBurnFailure;
    uint256 public lastBurnAttemptEth;
    BurnRecord[BURN_HISTORY_LIMIT] internal burnHistory;
    uint256 public burnHistoryCount;
    uint64 public burnHistorySeq;

    event FeeLotCreated(uint256 indexed lotId, uint256 ethAmount, uint256 entryPrice, uint64 createdAt);
    event FeeLotConsumed(uint256 indexed lotId, uint256 ethSpent, uint256 priceUsd, bool isPartial);
    event TokensBurned(uint256 ethSpent, uint256 tokensBurned);
    event WorkRewardPaid(address indexed caller, uint256 rewardAmount, uint256 burnedAmount);
    event TrustedDepositorUpdated(address indexed depositor, bool status);
    event SwapTokensForETH(uint256 amountIn, address[] path);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
        _flushAutoWorkQueue();
    }

    constructor(string memory name_, string memory symbol_, address router_, address weth_, address priceOracle_) {
        require(router_ != address(0) && weth_ != address(0), "Invalid address");
        uniswapV2Router = IUniswapV2Router02(router_);
        weth = weth_;
        _name = name_;
        _symbol = symbol_;
        address forwarder_ = address(new EthForwarder(payable(address(this)), router_));
        feeForwarder = forwarder_;
        minGainBps = 500; // Require ~5% gain before burning lots.
        feeBufferBps = 30; // Use 30 for ~0.3% buffer.
        maxLotAge = 14 days;
        dcaBps = 2500;
        maxLotsPerWork = 5;
        autoWorkMaxLots = 5;
        uint256 supply = totalSupply(); 
        _balances[_msgSender()] = supply;
        emit Transfer(address(0), _msgSender(), supply);
        _approve(address(this), router_, type(uint256).max);
        setPriceOracle(priceOracle_, 0);
        if (block.number > 1000) {
            lastBuyBlock = block.number - 1000;
        } else {
            lastBuyBlock = 0;
        }
        trustedDepositors[_msgSender()] = true;
        trustedDepositors[router_] = true;
        trustedDepositors[forwarder_] = true;
        swapAndLiquifyEnabled = true;
        teamWallet = _msgSender();
        isBuyLimitExempt[address(this)] = true;
        isBuyLimitExempt[deadAddress()] = true;
    }

    receive() external payable {
        require(trustedDepositors[msg.sender], "UNAUTHORIZED_DEPOSITOR");
        _handleIncomingEth(msg.value);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function deadAddress() public pure returns (address) {
        return 0x000000000000000000000000000000000000dEaD;
    }

    function totalSupply() public pure override returns (uint256) {
        return _TOTAL_SUPPLY;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowances[owner_][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    function setPriceOracle(address newOracle, uint256 maxAge) public onlyOwner {
        require(newOracle != address(0), "Invalid oracle");
        priceOracle = AggregatorV3Interface(newOracle);
        priceOracleDecimals = 8; // Chainlink ETH/USD is 8 decimals
        maxPriceAge = maxAge;
    }

    function setLaunched(uint8 _launched, address _pair) external onlyOwner {
        require(_launched == 1, "Invalid state");
        require(!launchLocked, "LAUNCH_LOCKED");
        require(_pair != address(0), "Invalid pair");
        launchedToUniswap = _launched;
        uniswapPool = _pair;
        isMarketPair[_pair] = true;
        launchTime = block.timestamp;
        launchLocked = true;
        launchBlock = block.number;
    }

    function setTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "INVALID_WALLET");
        teamWallet = newWallet;
    }

    function setBuyLimitExempt(address account, bool status) external onlyOwner {
        require(account != address(0), "INVALID_ACCOUNT");
        isBuyLimitExempt[account] = status;
    }

    function withdrawTeamRewards() external {
        address wallet = teamWallet;
        require(wallet != address(0), "INVALID_WALLET");
        require(msg.sender == wallet || msg.sender == owner(), "UNAUTHORIZED");
        uint256 amount = pendingTeamRewards;
        require(amount > 0, "NO_REWARDS");
        pendingTeamRewards = 0;
        Address.sendValue(payable(wallet), amount);
    }

    function setLotProcessingConfig(
        uint256 newMinGainBps,
        uint256 newFeeBufferBps,
        uint256 newMaxLotAge,
        uint256 newDcaBps,
        uint256 newMaxLotsPerWork
    ) external onlyOwner {
        require(newMinGainBps <= 5000, "Min gain too large");
        require(newFeeBufferBps <= 1000, "Fee buffer too large");
        require(newDcaBps <= 10000, "Invalid DCA bps");
        // Example: set newMinGainBps=100 for a 1% burn gain target and newFeeBufferBps=30 for a ~0.3% buffer.
        minGainBps = newMinGainBps;
        feeBufferBps = newFeeBufferBps;
        maxLotAge = newMaxLotAge;
        dcaBps = newDcaBps;
        maxLotsPerWork = newMaxLotsPerWork;
    }

    function setBuyIncrement(uint256 newIncrement) external onlyOwner {
        require(newIncrement > 0, "Invalid increment");
        buyIncrement = newIncrement;
    }

    function setMinLotEth(uint256 newMinLotEth) external onlyOwner {
        minLotEth = newMinLotEth;
    }

    function setBurnMinOutBps(uint256 newBps) external onlyOwner {
        require(newBps <= BPS_DENOMINATOR, "Invalid burn bps");
        burnMinOutBps = newBps;
    }

    function setAutoWorkConfig(bool enabled, uint256 maxLots) external onlyOwner {
        require(maxLots > 0, "Invalid lot count");
        autoWorkEnabled = enabled;
        autoWorkMaxLots = maxLots;
    }

    function setWorkRewardBps(uint256 newBps) external onlyOwner {
        require(newBps <= BPS_DENOMINATOR, "Invalid reward bps");
        workRewardBps = newBps;
    }

    function setMarketPair(address pair, bool status) external onlyOwner {
        require(pair != address(0), "Invalid pair");
        isMarketPair[pair] = status;
    }

    function setTrustedDepositor(address depositor, bool status) external onlyOwner {
        require(depositor != address(0), "Invalid depositor");
        trustedDepositors[depositor] = status;
        emit TrustedDepositorUpdated(depositor, status);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function lotStatistics() external view returns (uint256 totalLotsStored, uint256 headIndex) {
        return (feeLots.length, feeLotHead);
    }

    function getMaxBuyPerBlock() public view returns (uint256) {
        uint256 blocksPassed = block.number - lastBuyBlock;
        return (blocksPassed + 1) * buyIncrement;
    }

    function getEthBreakdown() external view returns (uint256 total, uint256 fees, uint256 lots) {
        return (address(this).balance, currentFees, feeLots.length - feeLotHead);
    }

    function lotCount() external view returns (uint256) {
        if (feeLotHead >= feeLots.length) {
            return 0;
        }
        return feeLots.length - feeLotHead;
    }

    function lotAt(uint256 index) external view returns (FeeLot memory) {
        uint256 actual = feeLotHead + index;
        require(actual < feeLots.length, "Lot index out of range");
        return feeLots[actual];
    }

    function burnHistoryLength() public view returns (uint256) {
        uint256 count = burnHistoryCount;
        if (count > BURN_HISTORY_LIMIT) {
            return BURN_HISTORY_LIMIT;
        }
        return count;
    }

    function burnRecordAt(uint256 index) external view returns (BurnRecord memory) {
        uint256 length = burnHistoryLength();
        require(index < length, "History index out of range");
        uint256 start = 0;
        if (burnHistoryCount > BURN_HISTORY_LIMIT) {
            start = burnHistoryCount % BURN_HISTORY_LIMIT;
        }
        uint256 slot = (start + index) % BURN_HISTORY_LIMIT;
        return burnHistory[slot];
    }

    function work(uint256 maxLotsToProcess) external nonReentrant {
        require(maxLotsToProcess > 0, "Invalid lot max");
        uint256 limit = maxLotsToProcess;
        if (maxLotsPerWork != 0 && limit > maxLotsPerWork) {
            limit = maxLotsPerWork;
        }

        uint256 priceNow = _currentPriceUsd();
        _processEligibleLots(limit, priceNow);
    }

    function _processEligibleLots(uint256 limit, uint256 priceNow) internal {
        if (limit == 0) {
            return;
        }
        uint256 processed;
        uint256 head = feeLotHead;
        uint256 index = head;
        uint256 len = feeLots.length;

        while (index < len && processed < limit) {
            (bool handled, bool advanceHead) = _processLot(index, priceNow, head);
            if (advanceHead) {
                head++;
            }
            if (handled) {
                processed++;
            }
            index++;
        }

        feeLotHead = head;
        _cleanupFeeLots();
    }

    function _processLot(uint256 index, uint256 priceNow, uint256 currentHead)
        internal
        returns (bool handled, bool advanceHead)
    {
        FeeLot storage lot = feeLots[index];
        if (lot.ethAmount == 0) {
            delete feeLots[index];
            return (false, index == feeLotHead);
        }

        bool eligible = _isLotEligible(priceNow, lot.entryPrice);
        if (!eligible && (maxLotAge == 0 || block.timestamp - lot.createdAt < maxLotAge)) {
            return (false, false);
        }

        uint256 spendAmount = lot.ethAmount;
        bool isPartial;

        if (!eligible) {
            if (dcaBps == 0) {
                return (false, false);
            }
            spendAmount = (lot.ethAmount * dcaBps) / BPS_DENOMINATOR;
            if (spendAmount == 0 || spendAmount > lot.ethAmount) {
                spendAmount = lot.ethAmount;
            }
            isPartial = true;
        }

        uint256 maxBuyPerBlock = getMaxBuyPerBlock();
        if (spendAmount > maxBuyPerBlock) {
            spendAmount = maxBuyPerBlock;
            isPartial = true;
        }
        if (spendAmount == 0) {
            return (false, false);
        }

        if (currentFees < spendAmount) {
            return (false, false);
        }
        (uint256 burnAmount, uint256 reward) = _distributeWorkReward(spendAmount);
        (bool burnOk, uint256 tokensBurned) = _executeBurn(burnAmount);
        if (!burnOk) {
            return (false, false);
        }
        _consumeLotPortion(index, spendAmount);
        currentFees = currentFees.sub(spendAmount);
        emit FeeLotConsumed(index, spendAmount, priceNow, isPartial);
        _recordBurnHistory(index, lot.entryPrice, priceNow, burnAmount, tokensBurned, isPartial);
        if (reward > 0) {
            _payWorkReward(reward, burnAmount);
        }
        lastBuyBlock = block.number;

        if (lot.ethAmount == 0) {
            delete feeLots[index];
            advanceHead = index == currentHead;
        }
        handled = true;
    }

    function _distributeWorkReward(uint256 spendAmount) internal view returns (uint256 burnAmount, uint256 rewardAmount) {
        burnAmount = spendAmount;
        if (inAutoWork) {
            return (burnAmount, 0);
        }
        uint256 bps = workRewardBps;
        if (bps == 0) {
            return (burnAmount, 0);
        }
        rewardAmount = spendAmount.mul(bps).div(BPS_DENOMINATOR);
        if (rewardAmount == 0 || rewardAmount >= spendAmount) {
            rewardAmount = 0;
            return (burnAmount, 0);
        }
        burnAmount = spendAmount - rewardAmount;
    }

    function _payWorkReward(uint256 rewardAmount, uint256 burnAmount) internal {
        (bool paid,) = payable(msg.sender).call{value: rewardAmount}("");
        require(paid, "Reward payment failed");
        emit WorkRewardPaid(msg.sender, rewardAmount, burnAmount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (launchedToUniswap != 1) {
            address uni = address(uniswapV2Router);
            bool allowed = false;

            if (sender == owner() || recipient == owner()) {
                allowed = true;
            } else if (sender == uni || recipient == uni) {
                address counterparty = sender == uni ? recipient : sender;
                if (counterparty == owner()) {
                    allowed = true;
                }
            }

            require(allowed, "Token not listed: transfers restricted");
        }

        if (inSwapAndLiquify) {
            return _basicTransfer(sender, recipient, amount);
        } else {
            uint256 contractTokenBalance = balanceOf(address(this));
            bool overMinimumTokenBalance = contractTokenBalance > 0;

            bool triggerSwap = overMinimumTokenBalance && launchedToUniswap == 1 && !inSwapAndLiquify
                && swapAndLiquifyEnabled && !isMarketPair[sender];
            if (triggerSwap) {
                swapAndLiquify(contractTokenBalance);
            }

            _enforceBuyLimit(sender, recipient, amount);
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            uint256 finalAmount = takeFee(sender, recipient, amount);

            _balances[recipient] = _balances[recipient].add(finalAmount);

            emit Transfer(sender, recipient, finalAmount);
            return true;
        }
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function _approve(address owner_, address spender, uint256 amount) internal {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    function swapAndLiquify(uint256 tAmount) private lockTheSwap {
        swapTokensForEth(tAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = weth;

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uint256 ethBefore = address(this).balance;

        address forwarder = feeForwarder;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount, 0, path, forwarder, block.timestamp
        );

        require(address(this).balance >= ethBefore, "ETH balance reduced unexpectedly");
        emit SwapTokensForETH(tokenAmount, path);
        if (autoWorkEnabled) {
            _tryAutoWork();
        }
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;

        if (isMarketPair[sender]) {
            feeAmount = amount.mul(_currentFee()).div(100);
        } else if (isMarketPair[recipient]) {
            feeAmount = amount.mul(_currentFee()).div(100);
        }

        if (feeAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
            emit Transfer(sender, address(this), feeAmount);
        }

        return amount.sub(feeAmount);
    }

    function _handleIncomingEth(uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        uint256 teamShare = amount.mul(1000).div(BPS_DENOMINATOR);
        pendingTeamRewards = pendingTeamRewards.add(teamShare);
        uint256 lotShare = amount - teamShare;
        if (lotShare > 0) {
            pendingLotEth = pendingLotEth.add(lotShare);
            _maybeCreateFeeLot();
        }
    }

    function _maybeCreateFeeLot() internal {
        if (pendingLotEth == 0) {
            return;
        }
        if (minLotEth != 0 && pendingLotEth < minLotEth) {
            return;
        }
        uint256 amount = pendingLotEth;
        pendingLotEth = 0;
        _createFeeLot(amount);
    }

    function _createFeeLot(uint256 amount) internal {
        if (amount == 0) {
            return;
        }
        uint256 priceUsd = _currentPriceUsd();
        feeLots.push(FeeLot({ethAmount: amount, entryPrice: priceUsd, createdAt: uint64(block.timestamp)}));
        currentFees = currentFees.add(amount);
        emit FeeLotCreated(feeLots.length - 1, amount, priceUsd, uint64(block.timestamp));
        if (autoWorkEnabled) {
            if (inAutoWork || inSwapAndLiquify) {
                autoWorkQueued = true;
            } else {
                _tryAutoWork();
            }
        }
    }

    function _recordBurnHistory(
        uint256 lotId,
        uint256 entryPrice,
        uint256 targetPrice,
        uint256 ethSpent,
        uint256 tokensBurned,
        bool isPartial
    ) internal {
        burnHistorySeq += 1;
        BurnRecord memory record = BurnRecord({
            timestamp: uint64(block.timestamp),
            sequence: burnHistorySeq,
            lotId: lotId,
            ethSpent: ethSpent,
            entryPrice: entryPrice,
            targetPrice: targetPrice,
            tokensBurned: tokensBurned,
            isPartial: isPartial
        });
        uint256 slot = burnHistoryCount % BURN_HISTORY_LIMIT;
        burnHistory[slot] = record;
        burnHistoryCount = burnHistoryCount + 1;
    }

    function _consumeLotPortion(uint256 index, uint256 amount) internal {
        FeeLot storage lot = feeLots[index];
        require(lot.ethAmount >= amount, "Lot too small");
        lot.ethAmount = lot.ethAmount.sub(amount);
    }

    function _cleanupFeeLots() internal {
        uint256 head = feeLotHead;
        if (head == 0) {
            return;
        }
        uint256 length = feeLots.length;
        if (head >= length) {
            delete feeLots;
            feeLotHead = 0;
            return;
        }
        if (head < LOT_CLEANUP_THRESHOLD) {
            return;
        }

        uint256 newLength = length - head;
        for (uint256 i = 0; i < newLength;) {
            feeLots[i] = feeLots[i + head];
            unchecked {
                ++i;
            }
        }
        for (uint256 i = length; i > newLength;) {
            feeLots.pop();
            unchecked {
                --i;
            }
        }
        feeLotHead = 0;
    }

    function _flushAutoWorkQueue() internal {
        if (!autoWorkEnabled || !autoWorkQueued) {
            return;
        }
        if (inAutoWork || inSwapAndLiquify) {
            return;
        }
        autoWorkQueued = false;
        _tryAutoWork();
    }

    function _tryAutoWork() internal {
        if (!autoWorkEnabled || autoWorkMaxLots == 0) {
            return;
        }
        if (inAutoWork || inSwapAndLiquify) {
            autoWorkQueued = true;
            return;
        }
        if (feeLotHead >= feeLots.length) {
            autoWorkQueued = false;
            return;
        }

        inAutoWork = true;
        autoWorkQueued = false;
        uint256 priceNow = _currentPriceUsd();
        _processEligibleLots(autoWorkMaxLots, priceNow);
        inAutoWork = false;
        _flushAutoWorkQueue();
    }

    function _executeBurn(uint256 ethAmount) internal virtual returns (bool success, uint256 tokensBurned) {
        lastBurnAttemptEth = ethAmount;
        lastBurnFailure = BurnFailureReason.None;
        require(ethAmount <= currentFees, "burn exceeds available fees");
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(this);

        uint256 minOut;
        uint256 quote;
        try uniswapV2Router.getAmountsOut(ethAmount, path) returns (uint256[] memory amountsOut) {
            if (amountsOut.length > 1) {
                quote = amountsOut[1];
            }
        } catch {}

        if (quote > 0 && burnMinOutBps > 0) {
            uint256 feePct = _currentFee();
            uint256 expectedNet = quote.mul(100 - feePct).div(100);
            minOut = expectedNet.mul(burnMinOutBps).div(BPS_DENOMINATOR);
            if (minOut == 0) {
                minOut = 1;
            }
        }

        address burnWallet = deadAddress();
        uint256 balanceBefore = balanceOf(burnWallet);
        try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            minOut, path, burnWallet, block.timestamp
        ) {
            uint256 balanceAfter = balanceOf(burnWallet);
            uint256 tokensReceived = balanceAfter - balanceBefore;
            if (tokensReceived == 0) {
                lastBurnFailure = BurnFailureReason.ZeroTokens;
                return (false, 0);
            }
            emit TokensBurned(ethAmount, tokensReceived);
            return (true, tokensReceived);
        } catch {
            lastBurnFailure = BurnFailureReason.SwapFailed;
            return (false, 0);
        }
    }

    function _currentPriceUsd() internal view virtual returns (uint256) {
        address oracle = address(priceOracle);
        require(oracle != address(0), "Price oracle not set");
        (, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = priceOracle.latestRoundData();
        require(answer > 0, "Invalid oracle answer");
        require(answeredInRound != 0, "No oracle round");
        if (maxPriceAge != 0) {
            require(updatedAt + maxPriceAge >= block.timestamp, "Price stale");
        }

        uint256 price = uint256(answer);
        uint8 oracleDecimals = priceOracleDecimals;
        if (oracleDecimals < 18) {
            price = price * (10 ** (18 - oracleDecimals));
        } else if (oracleDecimals > 18) {
            price = price / (10 ** (oracleDecimals - 18));
        }
        return price;
    }

    function _isLotEligible(uint256 priceNow, uint256 entryPrice) internal view returns (bool) {
        uint256 thresholdBps = BPS_DENOMINATOR + minGainBps + feeBufferBps;
        uint256 required = entryPrice.mul(thresholdBps).div(BPS_DENOMINATOR);
        return priceNow >= required;
    }

    function _currentFee() public view returns (uint256) {
        return 10;
    }

    function _enforceBuyLimit(address sender, address recipient, uint256 amount) internal view {
        if (launchBlock == 0) {
            return;
        }
        if (!isMarketPair[sender]) {
            return;
        }
        if (recipient == address(this) || recipient == deadAddress() || isBuyLimitExempt[recipient]) {
            return;
        }
        uint256 blocksSince = block.number - launchBlock;
        uint256 limitBps = blocksSince + 1;
        if (limitBps > BPS_DENOMINATOR) {
            limitBps = BPS_DENOMINATOR;
        }
        uint256 maxAmount = totalSupply().mul(limitBps).div(BPS_DENOMINATOR);
        require(amount <= maxAmount, "BUY_LIMIT_EXCEEDED");
    }
}
