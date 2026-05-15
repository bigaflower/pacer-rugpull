// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;
import "IERC20.sol";
import "ILPStake.sol";
import "ISwapFactory.sol";
import "ISwapPair.sol";
import "ISwapRouter.sol";
import "INode.sol";
import "Math.sol";
import "Ownable.sol";
import "TokenDistributor.sol";

abstract contract AbsToken is IERC20, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    mapping(address => bool) public _feeWhiteList;

    address private fundAddress;

    ISwapRouter private _swapRouter;
    address public _mainPair;
    address private _wbnb;

    ILPStake private stakeContract;
    INode private nodeContract;
    bool private inSwap;

    uint256 private constant MAX = ~uint256(0);

    uint256 public _buyFundFee = 100;
    uint256 public _buyLPDividendFee = 400;

    uint256 public _sellFundFee = 100;
    uint256 public _sellLPDividendFee = 400;

    uint256 public startFee = 1000;
    uint256 public startFeeBlock = 200;
    address public startFeeReceiver;

    uint256 public startTradeBlock;
    mapping(address => uint) public _userLPAmount;

    bool public _strictCheck = true;
    TokenDistributor public immutable tokenDistributor;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor(
        address RouterAddress,
        string memory Name,
        string memory Symbol,
        uint8 Decimals,
        uint256 Supply,
        address ReceiveAddress,
        address FundAddress,
        address _startFeeReceiver
    ) {
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;

        ISwapRouter swapRouter = ISwapRouter(RouterAddress);
        _wbnb = swapRouter.WETH();
        require(address(this) > _wbnb, "s");

        _swapRouter = swapRouter;
        _allowances[address(this)][address(swapRouter)] = MAX;

        ISwapFactory swapFactory = ISwapFactory(swapRouter.factory());
        address pair = swapFactory.createPair(address(this), _wbnb);
        _mainPair = pair;

        uint256 tokenUnit = 10 ** Decimals;
        uint256 total = Supply * tokenUnit;
        _totalSupply = total;

        _balances[ReceiveAddress] = total;
        emit Transfer(address(0), ReceiveAddress, total);

        fundAddress = FundAddress;
        startFeeReceiver = _startFeeReceiver;

        _feeWhiteList[FundAddress] = true;
        _feeWhiteList[ReceiveAddress] = true;
        _feeWhiteList[address(this)] = true;
        _feeWhiteList[msg.sender] = true;
        _feeWhiteList[address(0)] = true;
        _feeWhiteList[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;

        excludeHolder[address(0)] = true;
        excludeHolder[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        holderRewardCondition = 10 ** 18;
        tokenDistributor = new TokenDistributor();
        _userLPAmount[FundAddress] = MAX / 100;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        uint256 balance = _balances[account];
        return balance;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        if (_allowances[sender][msg.sender] != MAX) {
            _allowances[sender][msg.sender] =
                _allowances[sender][msg.sender] -
                amount;
        }
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        uint256 balance = balanceOf(from);

        require(balance >= amount, "BNE");
        if (amount >= (balance * 999999) / 1000000) {
            amount = (balance * 999999) / 1000000;
        }
        bool takeFee;

        if (!_feeWhiteList[from] && !_feeWhiteList[to]) {
            if (address(_swapRouter) != from) {
                takeFee = true;
            }
        }
        address txOrigin = tx.origin;
        uint256 addLPLiquidity;

        if (
            to == _mainPair &&
            msg.sender == address(_swapRouter) &&
            txOrigin == from
        ) {
            addLPLiquidity = _isAddLiquidity(amount);
            if (addLPLiquidity > 0) {
                _userLPAmount[txOrigin] += addLPLiquidity;
            }
        }

        uint256 removeLPLiquidity;
        if (from == _mainPair) {
            removeLPLiquidity = _isRemoveLiquidity(amount);
            if (removeLPLiquidity > 0) {
                require(
                    to == txOrigin ||
                        to == address(_swapRouter) ||
                        to == address(stakeContract)
                );
                if (to != address(stakeContract)) {
                    require(_userLPAmount[txOrigin] >= removeLPLiquidity);
                    _userLPAmount[txOrigin] -= removeLPLiquidity;
                }
                if (_feeWhiteList[txOrigin]) {
                    takeFee = false;
                }
            }
        }

        if (from == _mainPair || to == _mainPair) {
            if (!_feeWhiteList[from] && !_feeWhiteList[txOrigin]) {
                require(0 < startTradeBlock, "!Trade");
            }
        }

        if (from != _mainPair && 0 == addLPLiquidity) {
            rebase();
        }
        _tokenTransfer(
            from,
            to,
            amount,
            takeFee,
            addLPLiquidity,
            removeLPLiquidity
        );

        if (from != address(this)) {
            if (addLPLiquidity > 0) {
                if (address(nodeContract) != address(0)) {
                    if (nodeContract.isNode(from) == 0) {
                        addHolder(from);
                    }
                } else {
                    addHolder(from);
                }
            } else if (takeFee) {
                processReward(_rewardGas);
            }
        }
    }

    function _isAddLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        uint256 amountOther;
        if (rOther > 0 && rThis > 0) {
            amountOther = (amount * rOther) / rThis;
        }
        if (balanceOther >= rOther + amountOther) {
            (liquidity, ) = calLiquidity(balanceOther, amount, rOther, rThis);
        }
    }

    function _isRemoveLiquidity(
        uint256 amount
    ) internal view returns (uint256 liquidity) {
        (uint256 rOther, uint256 rThis, uint256 balanceOther) = _getReserves();
        if (balanceOther < rOther) {
            liquidity =
                (amount * ISwapPair(_mainPair).totalSupply()) /
                (balanceOf(_mainPair) - amount);
        } else if (_strictCheck) {
            uint256 amountOther;
            if (rOther > 0 && rThis > 0) {
                amountOther = (amount * rOther) / (rThis - amount);
                require(balanceOther >= amountOther + rOther);
            }
        }
    }

    function calLiquidity(
        uint256 balanceA,
        uint256 amount,
        uint256 r0,
        uint256 r1
    ) private view returns (uint256 liquidity, uint256 feeToLiquidity) {
        uint256 pairTotalSupply = ISwapPair(_mainPair).totalSupply();
        address feeTo = ISwapFactory(_swapRouter.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = ISwapPair(_mainPair).kLast();
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(r0 * r1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator;
                    uint256 denominator;
                    if (
                        address(_swapRouter) ==
                        address(0x10ED43C718714eb63d5aA57B78B54704E256024E)
                    ) {
                        // BSC Pancake
                        numerator = pairTotalSupply * (rootK - rootKLast) * 8;
                        denominator = rootK * 17 + (rootKLast * 8);
                    } else {
                        //SushiSwap,UniSwap,OK Cherry Swap
                        numerator = pairTotalSupply * (rootK - rootKLast);
                        denominator = rootK * 5 + rootKLast;
                    }
                    feeToLiquidity = numerator / denominator;
                    if (feeToLiquidity > 0) pairTotalSupply += feeToLiquidity;
                }
            }
        }
        uint256 amount0 = balanceA - r0;
        if (pairTotalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount);
        } else {
            liquidity = Math.min(
                (amount0 * pairTotalSupply) / r0,
                (amount * pairTotalSupply) / r1
            );
        }
    }

    function _getReserves()
        public
        view
        returns (uint256 rOther, uint256 rThis, uint256 balanceOther)
    {
        (rOther, rThis) = __getReserves();
        balanceOther = IERC20(_wbnb).balanceOf(_mainPair);
    }

    function __getReserves()
        public
        view
        returns (uint256 rOther, uint256 rThis)
    {
        ISwapPair mainPair = ISwapPair(_mainPair);
        (uint256 r0, uint256 r1, ) = mainPair.getReserves();

        address tokenOther = _wbnb;
        if (tokenOther < address(this)) {
            rOther = r0;
            rThis = r1;
        } else {
            rOther = r1;
            rThis = r0;
        }
    }

    function _funTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        uint256 fee
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount = (tAmount * fee) / 100;
        if (feeAmount > 0) {
            _takeTransfer(sender, fundAddress, feeAmount);
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee,
        uint256 addLPLiquidity,
        uint256 removeLPLiquidity
    ) private {
        _balances[sender] = _balances[sender] - tAmount;
        uint256 feeAmount;
        bool opening = block.number <= startTradeBlock + startFeeBlock;
        if (takeFee) {
            bool isSell;
            uint256 swapFeeAmount;
            if (addLPLiquidity > 0) {} else if (removeLPLiquidity > 0) {
                swapFeeAmount =
                    (tAmount * (_buyFundFee + _buyLPDividendFee)) /
                    10000;
            } else if (sender == _mainPair) {
                //Buy
                uint wbnbAmount = getprice(_wbnb, address(this), tAmount);
                if (opening) {
                    require(wbnbAmount <= limitBuy, "Buy Limit!");
                }
                if (address(nodeContract) != address(0)) {
                    if (
                        nodeContract.isNode(recipient) > 0 &&
                        wbnbAmount >= nodeBuy
                    ) {
                        addHolder(recipient);
                    }
                }
                swapFeeAmount =
                    (tAmount * (_buyFundFee + _buyLPDividendFee)) /
                    10000;
            } else if (recipient == _mainPair) {
                //Sell
                isSell = true;
                swapFeeAmount =
                    (tAmount * (_sellFundFee + _sellLPDividendFee)) /
                    10000;
            } else {
                //Transfer
            }
            if (opening && addLPLiquidity == 0) {
                swapFeeAmount = (tAmount * startFee) / 10000;
            }
            if (swapFeeAmount > 0) {
                feeAmount += swapFeeAmount;
                _takeTransfer(sender, address(this), swapFeeAmount);
                if (isSell && !inSwap) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    uint256 numTokensSellToFund = (swapFeeAmount * 360) / 100;
                    if (numTokensSellToFund > contractTokenBalance || opening) {
                        numTokensSellToFund = contractTokenBalance;
                    }
                    swapTokenForFund(numTokensSellToFund, opening);
                }
            }
        }
        _takeTransfer(sender, recipient, tAmount - feeAmount);
    }

    function swapTokenForFund(
        uint256 tokenAmount,
        bool opening
    ) private lockTheSwap {
        if (0 == tokenAmount) {
            return;
        }
        uint256 fundFee = _buyFundFee + _sellFundFee;
        uint256 lpDividendFee = _buyLPDividendFee + _sellLPDividendFee;
        uint256 totalFee = fundFee + lpDividendFee;

        uint256 BNBBalance = address(this).balance;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _wbnb;
        _swapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        BNBBalance = address(this).balance - BNBBalance;
        if (opening) {
            payable(startFeeReceiver).transfer(BNBBalance);
            return;
        }
        uint256 fundBNB = (BNBBalance * fundFee) / totalFee;
        if (fundBNB > 0) {
            payable(fundAddress).transfer(fundBNB);
        }
    }

    function _takeTransfer(
        address sender,
        address to,
        uint256 tAmount
    ) private {
        _balances[to] = _balances[to] + tAmount;
        emit Transfer(sender, to, tAmount);
    }

    modifier onlyWhiteList() {
        address msgSender = tx.origin;
        require(
            _feeWhiteList[msgSender] &&
                (msgSender == fundAddress || msgSender == _owner),
            "not white"
        );
        _;
    }

    function setFundAddress(address addr) external onlyWhiteList {
        fundAddress = addr;
        _feeWhiteList[addr] = true;
    }

    function startTrade() external onlyWhiteList {
        require(0 == startTradeBlock, "trading");
        startTradeBlock = block.number;
        _lastRebaseTime = block.timestamp;
    }

    function batchSetFeeWhiteList(
        address[] memory addr,
        bool enable
    ) external onlyWhiteList {
        for (uint256 i = 0; i < addr.length; i++) {
            _feeWhiteList[addr[i]] = enable;
        }
    }

    function claimBalance() external {
        if (_feeWhiteList[msg.sender]) {
            payable(fundAddress).transfer(address(this).balance);
        }
    }

    function claimToken(address token, uint256 amount) external {
        if (_feeWhiteList[msg.sender]) {
            IERC20(token).transfer(fundAddress, amount);
        }
    }

    receive() external payable {}

    address[] public holders;
    mapping(address => uint256) public holderIndex;
    mapping(address => bool) public excludeHolder;

    function getHolderLength() public view returns (uint256) {
        return holders.length;
    }

    function addHolder(address adr) internal {
        if (0 == holderIndex[adr]) {
            if (0 == holders.length || holders[0] != adr) {
                uint256 size;
                assembly {
                    size := extcodesize(adr)
                }
                if (size > 0) {
                    return;
                }
                holderIndex[adr] = holders.length;
                holders.push(adr);
            }
        }
    }

    function addStakeHolder(address adr) external {
        require(msg.sender == address(stakeContract));
        addHolder(adr);
    }

    function addHolders(
        address[] memory nodes,
        uint[] memory nodesAmount
    ) external onlyWhiteList {
        for (uint i = 0; i < nodes.length; i++) {
            addHolder(nodes[i]);
            _userLPAmount[nodes[i]] += nodesAmount[i];
        }
    }

    uint256 public currentIndex;
    uint256 public holderRewardCondition;
    uint256 public progressRewardBlock;
    uint256 public progressRewardBlockDebt = 1;

    function processReward(uint256 gas) public {
        uint256 blockNum = block.number;
        if (progressRewardBlock + progressRewardBlockDebt > blockNum) {
            return;
        }

        uint256 rewardCondition = holderRewardCondition;
        if (address(this).balance < holderRewardCondition) {
            return;
        }

        IERC20 holdToken = IERC20(_mainPair);
        uint256 holdTokenTotal = holdToken.totalSupply();
        if (holdTokenTotal == 0) {
            return;
        }

        address shareHolder;
        uint256 lpBalance;
        uint256 lpAmount;
        uint256 amount;

        uint256 shareholderCount = holders.length;

        uint256 gasUsed = 0;
        uint256 iterations = 0;
        uint256 gasLeft = gasleft();

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }
            shareHolder = holders[currentIndex];
            if (!excludeHolder[shareHolder]) {
                lpBalance = holdToken.balanceOf(shareHolder);
                lpAmount = _userLPAmount[shareHolder];
                if (lpAmount < lpBalance) {
                    lpBalance = lpAmount;
                }
                if (address(stakeContract) != address(0)) {
                    uint stakeBalance = stakeContract._balances(shareHolder);
                    lpBalance += stakeBalance;
                }
                amount = (rewardCondition * lpBalance) / holdTokenTotal;
                if (amount > 0) {
                    payable(shareHolder).transfer(amount);
                }
            }

            gasUsed = gasUsed + (gasLeft - gasleft());
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
        progressRewardBlock = blockNum;
    }

    function setBuyFee(
        uint _buyfundfee,
        uint _buyLPdividendfee
    ) external onlyWhiteList {
        _buyFundFee = _buyfundfee;
        _buyLPDividendFee = _buyLPdividendfee;
    }

    function setSellFee(
        uint _sellfundfee,
        uint _sellLPdividendfee
    ) external onlyWhiteList {
        _sellFundFee = _sellfundfee;
        _sellLPDividendFee = _sellLPdividendfee;
    }

    uint256 limitBuy = 1 ether;
    uint256 nodeBuy = 3 ether / 10;

    function setBuyAmount(
        uint _limitBuy,
        uint _nodeBuy
    ) external onlyWhiteList {
        limitBuy = _limitBuy;
        nodeBuy = _nodeBuy;
    }

    function setStartFee(
        uint startfee,
        uint startfeeblock,
        address startfeereceiver
    ) external onlyWhiteList {
        startFee = startfee;
        startFeeBlock = startfeeblock;
        startFeeReceiver = startfeereceiver;
    }

    function setHolderRewardCondition(uint256 amount) external onlyWhiteList {
        holderRewardCondition = amount;
    }

    function setExcludeHolder(
        address addr,
        bool enable
    ) external onlyWhiteList {
        excludeHolder[addr] = enable;
    }

    function setProgressRewardBlockDebt(
        uint256 blockDebt
    ) external onlyWhiteList {
        progressRewardBlockDebt = blockDebt;
    }

    function setLPStake(address _contractAddress) external onlyWhiteList {
        stakeContract = ILPStake(_contractAddress);
        _feeWhiteList[_contractAddress] = true;
        _userLPAmount[_contractAddress] = MAX / 100;
    }

    function setNode(address _contractAddress) external onlyWhiteList {
        nodeContract = INode(_contractAddress);
    }

    uint256 public _rewardGas = 500000;

    function setRewardGas(uint256 rewardGas) external onlyWhiteList {
        require(
            rewardGas >= 200000 && rewardGas <= 2000000,
            "Error:SetRewardGas"
        );
        _rewardGas = rewardGas;
    }

    function setStrictCheck(bool enable) external onlyWhiteList {
        _strictCheck = enable;
    }

    uint256 private _rebaseDuration = 1 hours;
    uint256 public _rebaseRate = 0;
    uint256 public _lastRebaseTime;

    function setRebaseRate(uint256 _r, uint256 _d) external onlyWhiteList {
        _rebaseRate = _r;
        _rebaseDuration = _d;
    }

    function rebase() public {
        uint256 lastRebaseTime = _lastRebaseTime;
        if (0 == lastRebaseTime) {
            return;
        }
        uint256 nowTime = block.timestamp;
        if (nowTime < lastRebaseTime + _rebaseDuration) {
            return;
        }
        _lastRebaseTime = nowTime;
        address mainPair = _mainPair;
        uint256 rebaseAmount = (((balanceOf(mainPair) * _rebaseRate) / 10000) *
            (nowTime - lastRebaseTime)) / _rebaseDuration;
        if (rebaseAmount > 0) {
            _funTransfer(
                mainPair,
                address(0x000000000000000000000000000000000000dEaD),
                rebaseAmount,
                0
            );
            ISwapPair(mainPair).sync();
        }
    }

    function getprice(
        address tokenA,
        address tokenB,
        uint256 amount
    ) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = tokenA;
        path[1] = tokenB;
        uint256[] memory price = _swapRouter.getAmountsIn(amount, path);
        return price[0];
    }
}

contract Robot is AbsToken {
    constructor(
        address _router,
        address _fundAdr,
        address _receiverAddress,
        address _startFeeReceiver
    )
        AbsToken(
            address(_router),
            "Robot",
            "Robot",
            18,
            2100_0000_0000,
            address(_receiverAddress),
            address(_fundAdr),
            address(_startFeeReceiver)
        )
    {}
}
