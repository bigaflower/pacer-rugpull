// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.13;

/**
 * Submitted for verification at Etherscan.io on 2026-01-01
*/

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
        uint256 c = a - b;
        return c;
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}

interface ISlackerDividends {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
    function withdraw(address shareholder) external;
    function removeStuckDividends() external;
}

contract SlackerDividends is ISlackerDividends {
    using SafeMath for uint256;
    address _token;

    address public Slacker = 0xbE91fe42fF53A74Ad1268fBB5895E3D9ab04Ae69; // Reward token

    IDEXRouter router;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    address[] shareholders;
    mapping(address => uint256) shareholderIndexes;
    mapping(address => uint256) shareholderClaims;
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**36;

    uint256 public minPeriod = 30 minutes;
    uint256 public minDistribution = 0;

    uint256 public currentIndex;
    bool initialized;

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor() {
        _token = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Router
    }

    receive() external payable {
        deposit();
    }

    function removeStuckDividends() external onlyToken {
        uint256 balance = IERC20(Slacker).balanceOf(address(this));
        IERC20(Slacker).transfer(
            address(0xFb524085426515d6cCCbA000A68749e5D7512004), // Owner wallet
            balance
        );
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (shares[shareholder].amount > 0) {
            distributeDividend(shareholder);
        }

        if (amount > 0 && shares[shareholder].amount == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() public payable override {
        uint256 balanceBefore = IERC20(Slacker).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(Slacker);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = IERC20(Slacker).balanceOf(address(this)).sub(balanceBefore);
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(
            dividendsPerShareAccuracyFactor.mul(amount).div(totalShares)
        );
    }

    function process(uint256 gas) external override {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) {
            return;
        }

        uint256 iterations = 0;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            if (shouldDistribute(shareholders[currentIndex])) {
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) public view returns (bool) {
        return
            shareholderClaims[shareholder] + minPeriod < block.timestamp &&
            getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) {
            return;
        }

        uint256 amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            totalDistributed = totalDistributed.add(amount);
            IERC20(Slacker).transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function withdraw(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if (shares[shareholder].amount == 0) {
            return 0;
        }

        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if (shareholderTotalDividends <= shareholderTotalExcluded) {
            return 0;
        }

        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length - 1];
        shareholderIndexes[shareholders[shareholders.length - 1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

contract ETHEREUM2069 is IERC20, Auth {
    using SafeMath for uint256;

    address public Slacker = 0xbE91fe42fF53A74Ad1268fBB5895E3D9ab04Ae69; // Reward token

    string private constant _name = "ETHEREUM2069";
    string private constant _symbol = "ETFETH";
    uint8 private constant _decimals = 18;

    uint256 private _totalSupply = 100_000_000_000 * (10**_decimals); // 100 billion tokens

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDividendExempt;

    uint256 public buyFee = 20;
    uint256 public sellFee = 30;

    uint256 public toReflections = 10;
    uint256 public toBurn = 10;
    uint256 public toTreasury = 40;
    uint256 public toMarketing = 40;

    uint256 public burnTax = 2;

    IDEXRouter public router;
    address public pair;

    address public treasuryWallet = 0xfADfea0ed7eE88AF64630bA39b69BE3E0e1c2bf4;
    address public marketingWallet = 0x96b252721dF21dFfC48A0e95Ab2d4f96CC547D20;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    SlackerDividends public SlackerDividend;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    uint256 public maxTx = _totalSupply; // Unlimited
    uint256 public maxWallet = _totalSupply; // Unlimited
    uint256 public swapThreshold = _totalSupply.div(1000); // 0.1% of supply

    constructor(address _owner) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // Uniswap V2 Router
        WETH = router.WETH();

        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;

        SlackerDividend = new SlackerDividends();

        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;

        _balances[_owner] = _totalSupply;

        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable {}

    function enableTrading() external onlyOwner {
        tradingOpen = true;
    }

    function changeTotalFees(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {
        buyFee = newBuyFee;
        sellFee = newSellFee;
        require(buyFee <= 30 && sellFee <= 30, "Fees too high");
    }

    function changeFeeAllocation(
        uint256 newTreasuryFee,
        uint256 newMarketingFee,
        uint256 newBurnFee,
        uint256 newReflectionsFee
    ) external onlyOwner {
        toReflections = newReflectionsFee;
        toMarketing = newMarketingFee;
        toTreasury = newTreasuryFee;
        toBurn = newBurnFee;
        require(toReflections + toMarketing + toTreasury + toBurn == 100, "Allocation must sum to 100");
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = newMarketingWallet;
    }

    function setTreasuryWallet(address payable newTreasuryWallet) external onlyOwner {
        treasuryWallet = newTreasuryWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function setDistributionCriteria(uint256 newMinPeriod, uint256 newMinDistribution) external onlyOwner {
        SlackerDividend.setDistributionCriteria(newMinPeriod, newMinDistribution);
    }

    function setIsDividendExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            SlackerDividend.setShare(holder, 0);
        } else {
            SlackerDividend.setShare(holder, _balances[holder]);
        }
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(tradingOpen || isFeeExempt[sender] || isFeeExempt[recipient], "Trading not open yet");

        if (inSwapAndLiquify) {
            _basicTransfer(sender, recipient, amount);
            return true;
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(finalAmount);

        if (!isDividendExempt[sender]) {
            try SlackerDividend.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try SlackerDividend.setShare(recipient, _balances[recipient]) {} catch {}
        }

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeApplicable = pair == recipient ? sellFee : buyFee;
        uint256 feeAmount = amount.mul(feeApplicable).div(100);
        uint256 burnAmount = amount.mul(burnTax).div(100);

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        _balances[DEAD] = _balances[DEAD].add(burnAmount);
        _totalSupply = _totalSupply.sub(burnAmount);

        emit Transfer(sender, address(this), feeAmount);
        emit Transfer(sender, DEAD, burnAmount);

        return amount.sub(feeAmount).sub(burnAmount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function burnSlacker(uint256 amount) private {
        if (amount > 0) {
            address[] memory path = new address[](2);
            path[0] = router.WETH();
            path[1] = address(Slacker);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(0, path, DEAD, block.timestamp);
        }
    }

    function swapBack() internal lockTheSwap {
        uint256 tokensToSwap = _balances[address(this)];
        swapTokensForEth(tokensToSwap);

        uint256 totalEthBalance = address(this).balance;

        uint256 ethForBurn = totalEthBalance.mul(toBurn).div(100);
        uint256 ethForMarketing = totalEthBalance.mul(toMarketing).div(100);
        uint256 ethForReflections = totalEthBalance.mul(toReflections).div(100);

        burnSlacker(ethForBurn);

        if (ethForMarketing > 0) {
            payable(marketingWallet).transfer(ethForMarketing);
        }

        if (ethForReflections > 0) {
            try SlackerDividend.deposit{value: ethForReflections}() {} catch {}
        }

        if (address(this).balance > 0) {
            payable(treasuryWallet).transfer(address(this).balance);
        }
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function withdraw() external {
        SlackerDividend.withdraw(msg.sender);
    }

    function checkPendingReflections(address shareholder) external view returns (uint256) {
        return SlackerDividend.getUnpaidEarnings(shareholder);
    }

    function removeStuckDividends() external onlyOwner {
        SlackerDividend.removeStuckDividends();
    }
}