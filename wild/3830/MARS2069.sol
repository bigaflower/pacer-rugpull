// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.13;
// $SLACK $100,000,000,000

interface IERC20 {
    function totalSupply() external view returns (uint);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address to, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IPair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IGODMODE {
    function setDistributionCriteria(uint minPeriod, uint minDistribution) external;
    function setShare(address shareholder, uint amount) external;
    function deposit() external payable;
    function process(uint gas) external;
    function withdraw(address shareholder) external;
    function removeStuckDividends() external;
    function updateActivity(address shareholder) external;
    function getUnpaidEarnings(address shareholder) external view returns (uint);
}

contract Auth {
    address public owner;
    modifier onlyOwner() { require(msg.sender == owner); _; }
    constructor(address _owner) { owner = _owner; }
    function transferOwnership(address newOwner) external onlyOwner { owner = newOwner; }
}

contract GODMODE is IGODMODE {
    address private immutable token;
    address private constant REWARD_TOKEN = 0xfEF4C6B56e011a684dC2054aFd576d83817C2620;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    IDEXRouter private immutable router;

    struct Share { uint amount; uint totalExcluded; uint totalRealised; }
    address[] private shareholders;
    mapping(address => uint) private shareholderIdx;
    mapping(address => uint) private claims;
    mapping(address => Share) public shares;
    mapping(address => uint) private lastActivity;

    uint public totalShares;
    uint public totalDividends;
    uint public totalDistributed;
    uint public divPerShare;
    uint private constant ACCURACY = 10**36;
    uint public minPeriod = 30 minutes;
    uint public minDistribution;
    uint public currentIdx;
    uint public slackBurnPct = 20;
    uint public divBurnPct = 5;

    modifier onlyToken() { require(msg.sender == token); _; }

    constructor(address token_) {
        token = token_;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }

    receive() external payable { deposit(); }

    function removeStuckDividends() external onlyToken {
        uint bal = IERC20(REWARD_TOKEN).balanceOf(address(this));
        if (bal > 0) IERC20(REWARD_TOKEN).transfer(0xFb524085426515d6cCCbA000A68749e5D7512004, bal);
    }

    function setDistributionCriteria(uint newMinPeriod, uint newMinDist) external override onlyToken {
        minPeriod = newMinPeriod;
        minDistribution = newMinDist;
    }

    function setSlackDivsBurnPercent(uint newPct) external onlyToken {
        require(newPct <= 50);
        slackBurnPct = newPct;
    }

    function setDividendBurnPercent(uint newPct) external onlyToken {
        require(newPct <= 20);
        divBurnPct = newPct;
    }

    function updateActivity(address shareholder) external override onlyToken {
        lastActivity[shareholder] = block.timestamp;
    }

    function setShare(address shareholder, uint amount) external override onlyToken {
        if (shares[shareholder].amount > 0) distributeDividend(shareholder);
        if (amount > 0 && shares[shareholder].amount == 0) {
            shareholderIdx[shareholder] = shareholders.length;
            shareholders.push(shareholder);
            lastActivity[shareholder] = block.timestamp;
        } else if (amount == 0 && shares[shareholder].amount > 0) {
            uint lastIdx = shareholders.length - 1;
            uint idx = shareholderIdx[shareholder];
            shareholders[idx] = shareholders[lastIdx];
            shareholderIdx[shareholders[lastIdx]] = idx;
            shareholders.pop();
        }
        totalShares = totalShares + amount - shares[shareholder].amount;
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = (amount * divPerShare) / ACCURACY;
    }

    function deposit() public payable override {
        uint balBefore = IERC20(REWARD_TOKEN).balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = REWARD_TOKEN;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(0, path, address(this), block.timestamp);
        uint amount = IERC20(REWARD_TOKEN).balanceOf(address(this)) - balBefore;
        uint burnAmt = (amount * slackBurnPct) / 100;
        if (burnAmt > 0) IERC20(REWARD_TOKEN).transfer(DEAD, burnAmt);
        uint distAmt = amount - burnAmt;
        totalDividends += distAmt;
        if (totalShares > 0) divPerShare += (ACCURACY * distAmt) / totalShares;
    }

    function process(uint gas) external override {
        uint count = shareholders.length;
        if (count == 0) return;
        uint gasUsed;
        uint gasLeft = gasleft();
        uint maxIter = count > 50 ? 50 : count;
        for (uint i = 0; gasUsed < gas && i < maxIter; i++) {
            if (currentIdx >= count) currentIdx = 0;
            if (shouldDistribute(shareholders[currentIdx])) distributeDividend(shareholders[currentIdx]);
            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIdx++;
        }
    }

    function shouldDistribute(address shareholder) public view returns (bool) {
        return claims[shareholder] + minPeriod < block.timestamp && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function getUnpaidEarnings(address shareholder) public view override returns (uint) {
        if (shares[shareholder].amount == 0) return 0;
        uint totalDiv = (shares[shareholder].amount * divPerShare) / ACCURACY;
        return totalDiv > shares[shareholder].totalExcluded ? totalDiv - shares[shareholder].totalExcluded : 0;
    }

    function distributeDividend(address shareholder) internal {
        if (shares[shareholder].amount == 0) return;
        uint amount = getUnpaidEarnings(shareholder);
        if (amount > 0) {
            uint burnAmt = (amount * divBurnPct) / 100;
            uint transferAmt = amount - burnAmt;
            totalDistributed += transferAmt;
            if (burnAmt > 0) IERC20(REWARD_TOKEN).transfer(DEAD, burnAmt);
            IERC20(REWARD_TOKEN).transfer(shareholder, transferAmt);
            claims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised += transferAmt;
            shares[shareholder].totalExcluded = (shares[shareholder].amount * divPerShare) / ACCURACY;
        }
    }

    function withdraw(address shareholder) external override onlyToken {
        distributeDividend(shareholder);
    }
}

contract MARS2069 is IERC20, Auth {
    address private constant REWARD_TOKEN = 0xfEF4C6B56e011a684dC2054aFd576d83817C2620;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ZERO = address(0);
    string private constant _name = "MARS2069";
    string private constant _symbol = "69420";
    uint8 private constant _decimals = 18;
    uint private _totalSupply = 100_000_000_000 * (10**18);

    mapping(address => uint) private _balances;
    mapping(address => mapping(address => uint)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isGODMODEExempt;

    uint public buyFee = 8;
    uint public sellFee = 8;
    uint public p2pFee = 2;

    uint public toNativeReflections = 25;
    uint public toGODMODEReflections = 20;
    uint public toNativeBurn = 10;
    uint public toTreasury = 20;
    uint public toMarketing = 10;
    uint public toAddLiquidity = 15;
    uint public allocSum = 80;

    uint public burnFee = 0;
    uint public burnTax = 0;

    IDEXRouter public immutable router;
    address public immutable pair;
    address public immutable WETH;
    address public devWallet = 0xFb524085426515d6cCCbA000A68749e5D7512004;
    address payable public treasuryWallet = payable(0xfADfea0ed7eE88AF64630bA39b69BE3E0e1c2bf4);
    address payable public marketingWallet = payable(0x96b252721dF21dFfC48A0e95Ab2d4f96CC547D20);
    address private tokenOwner;

    bool private inSwap;
    bool public swapEnabled = true;
    bool public tradingOpen;
    IGODMODE public immutable godmode;

    uint public maxTx = type(uint).max;
    uint public maxWallet = type(uint).max;
    uint public swapThreshold = _totalSupply / 1000;

    event RebateApplied(address indexed buyer, uint amount);

    constructor(address _owner) Auth(_owner) {
        tokenOwner = 0xFb524085426515d6cCCbA000A68749e5D7512004;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        godmode = IGODMODE(address(new GODMODE(address(this))));
        _allowances[address(this)][address(router)] = type(uint).max;

        isFeeExempt[_owner] = true;
        isFeeExempt[devWallet] = true;
        isGODMODEExempt[pair] = true;
        isGODMODEExempt[address(this)] = true;
        isGODMODEExempt[DEAD] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[devWallet] = true;

        _balances[_owner] = _totalSupply;
        emit Transfer(ZERO, _owner, _totalSupply);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint) { return _balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint) { return _allowances[owner][spender]; }

    function approve(address spender, uint amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) external override returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address sender, address to, uint amount) external override returns (bool) {
        uint currentAllowance = _allowances[sender][msg.sender];
        if (currentAllowance != type(uint).max) {
            require(currentAllowance >= amount);
            unchecked { _allowances[sender][msg.sender] -= amount; }
        }
        return _transfer(sender, to, amount);
    }

    function _transfer(address sender, address to, uint amount) internal returns (bool) {
        if (sender != owner && to != owner) require(tradingOpen);
        if (inSwap) {
            _balances[sender] -= amount;
            _balances[to] += amount;
            emit Transfer(sender, to, amount);
            return true;
        }

        if (_balances[address(this)] >= swapThreshold && !inSwap && swapEnabled && sender != pair) {
            inSwap = true;
            swapBack();
            inSwap = false;
        }

        _balances[sender] -= amount;
        uint finalAmount = !isFeeExempt[sender] && !isFeeExempt[to] ? takeFee(sender, to, amount) : amount;
        _balances[to] += finalAmount;

        if (!isGODMODEExempt[sender]) {
            godmode.updateActivity(sender);
            godmode.setShare(sender, _balances[sender]);
        }
        if (!isGODMODEExempt[to]) {
            godmode.updateActivity(to);
            godmode.setShare(to, _balances[to]);
        }

        if (!isGODMODEExempt[sender] && !inSwap) godmode.withdraw(sender);
        if (!isGODMODEExempt[to] && !inSwap) godmode.withdraw(to);

        emit Transfer(sender, to, finalAmount);
        return true;
    }

    function takeFee(address sender, address to, uint amount) internal returns (uint) {
        uint fee = to == pair ? sellFee : (sender == pair ? buyFee : p2pFee);
        uint feeAmount = (amount * fee) / 100;
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function swapTokensForEth(uint tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function addRewardTokenLp(uint ethAmount) private {
        if (ethAmount == 0) return;

        uint half = ethAmount / 2;
        uint balBefore = IERC20(REWARD_TOKEN).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = REWARD_TOKEN;
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: half}(0, path, address(this), block.timestamp);

        uint rewardAmount = IERC20(REWARD_TOKEN).balanceOf(address(this)) - balBefore;

        if (rewardAmount > 0) {
            IERC20(REWARD_TOKEN).approve(address(router), rewardAmount);
            router.addLiquidityETH{value: half}(
                REWARD_TOKEN,
                rewardAmount,
                0,
                0,
                devWallet,
                block.timestamp
            );
        }
    }

    function swapBack() internal {
        uint bal = _balances[address(this)];
        if (bal == 0) return;

        uint rewardLpTokens = (bal * toNativeReflections) / 100;
        if (rewardLpTokens > 0) {
            swapTokensForEth(rewardLpTokens);
            uint ethForRewardLp = address(this).balance;
            addRewardTokenLp(ethForRewardLp);
        }

        uint swapTokens = bal - rewardLpTokens;
        if (swapTokens > 0) swapTokensForEth(swapTokens);

        uint totalEth = address(this).balance;
        if (totalEth == 0) return;

        uint ethForBurn = (totalEth * toNativeBurn) / allocSum;
        if (ethForBurn > 0) {
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(this);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethForBurn}(0, path, DEAD, block.timestamp);
        }

        uint remainSum = allocSum - toNativeBurn;
        if (remainSum == 0) return;
        uint ethForGod = (totalEth * toGODMODEReflections) / remainSum;
        uint ethForTreasury = (totalEth * toTreasury) / remainSum;
        uint ethForMarketing = (totalEth * toMarketing) / remainSum;
        uint ethForLiq = (totalEth * toAddLiquidity) / remainSum;

        if (ethForMarketing > 0) marketingWallet.transfer(ethForMarketing);
        if (ethForGod > 0) godmode.deposit{value: ethForGod}();
        if (ethForTreasury > 0) treasuryWallet.transfer(ethForTreasury);
        if (ethForLiq > 0) {
            uint half = ethForLiq / 2;
            uint balBefore = _balances[address(this)];
            address[] memory path = new address[](2);
            path[0] = WETH;
            path[1] = address(this);
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: half}(0, path, address(this), block.timestamp);
            uint tokensForLiq = _balances[address(this)] - balBefore;
            if (tokensForLiq > 0) {
                router.addLiquidityETH{value: half}(address(this), tokensForLiq, 0, 0, DEAD, block.timestamp);
            }
        }
    }

    function enableTrading() external onlyOwner { tradingOpen = true; }
    function changeTotalFees(uint newBuyFee, uint newSellFee) external onlyOwner {
        require(newBuyFee <= 15 && newSellFee <= 15);
        buyFee = newBuyFee;
        sellFee = newSellFee;
    }
    function changeP2PFee(uint newP2PFee) external onlyOwner {
        require(newP2PFee <= 5);
        p2pFee = newP2PFee;
    }
    function changeFeeAllocation(uint nativeRef, uint godRef, uint treasury, uint marketing, uint burn, uint liq) external onlyOwner {
        toNativeReflections = nativeRef;
        toGODMODEReflections = godRef;
        toTreasury = treasury;
        toMarketing = marketing;
        toNativeBurn = burn;
        toAddLiquidity = liq;
        allocSum = godRef + burn + treasury + marketing + liq;
    }
    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner { isFeeExempt[holder] = exempt; }
    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner { isTxLimitExempt[holder] = exempt; }
    function setDevWallet(address payable newWallet) external onlyOwner { devWallet = newWallet; }
    function setMarketingWallet(address payable newWallet) external onlyOwner { marketingWallet = newWallet; }
    function setTreasuryWallet(address payable newWallet) external onlyOwner { treasuryWallet = newWallet; }
    function changeSwapBackSettings(bool enable, uint newLimit) external onlyOwner {
        swapEnabled = enable;
        swapThreshold = newLimit;
    }
    function setIsGODMODEExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(this) && holder != pair);
        isGODMODEExempt[holder] = exempt;
        godmode.setShare(holder, exempt ? 0 : _balances[holder]);
    }
    function getCirculatingSupply() public view returns (uint) { return _totalSupply - _balances[DEAD] - _balances[ZERO]; }
    function manualSwapBack() external onlyOwner { swapBack(); }
    function clearStuckEth() external onlyOwner { payable(devWallet).transfer(address(this).balance); }
    function manualProcessGas(uint gas) external onlyOwner { godmode.process(gas); }
    function checkPendingReflections(address shareholder) external view returns (uint) { return godmode.getUnpaidEarnings(shareholder); }
    function withdraw() external { godmode.withdraw(msg.sender); }
    function removeStuckDividends() external onlyOwner { godmode.removeStuckDividends(); }
}