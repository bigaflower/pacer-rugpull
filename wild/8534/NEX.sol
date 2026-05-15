/*
    Nexchain AI
    NEX

    Nexchain — the first AI blockchain |  400K TPS, $0.001 gas, smart Contracts 2.0, cross-chain integration


    https://www.nexchainai.app
    https://scan.nexchainai.app
    https://testnet.nexchainai.app
    https://x.com/NexChainAI_x
    https://t.me/NexChainAI_entry
*/

// SPDX-License-Identifier: MIT

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
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

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract NEX is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _excludedTax;
    address payable private _NEXTAXWALLET;

    uint256 private __initialTaxOnBuy=0;
    uint256 private __initialTaxOnSell=0;
    uint256 private __finalTaxOnBuy=0;
    uint256 private __finalTaxOnSell=0;
    uint256 private __reduceTaxOnBuyAt=7;
    uint256 private reduceTaxOnSellAt=7;
    uint256 private noSwapBefore=10;
    uint256 private transfer_Tax=0;
    uint256 private buys_Count=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotalAmount = 420690_000_000 * 10**_decimals;
    string private constant _name = unicode"Nexchain AI";
    string private constant _symbol = unicode"NEX";
    uint256 public maxTxAmt =  100 * (_tTotalAmount/100);
    uint256 public maxSizeOfWallet =  100 * (_tTotalAmount/100);
    uint256 public _tTaxSwapThreshold =  1 * (_tTotalAmount/1000);
    uint256 public _tTaxMaxSwap = 1 * (_tTotalAmount/100);

    bool public _THEN9AFND;
    uint160 public _XF261AND;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private sells_Count = 0;
    uint256 private lastBlockOfSell = 0;
    event MaxTxAmountUpdated(uint maxTxAmt);
    event transfer_TaxUpdated(uint _tax);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () payable {
        _NEXTAXWALLET = payable(0xB7bD35d920FE6c7E780E1867eDd60E830016680d);
        _balances[address(this)] = _tTotalAmount;
        _excludedTax[owner()] = true;
        _excludedTax[address(this)] = true;
        _excludedTax[_NEXTAXWALLET] = true;

        emit Transfer(address(0), address(this), _tTotalAmount);
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

    function totalSupply() public pure override returns (uint256) {
        return _tTotalAmount;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        uint256 taxAmount=0;
        if (from != owner() && to != owner()) {

            if(buys_Count==0){
                taxAmount = amount.mul((buys_Count>__reduceTaxOnBuyAt)?__finalTaxOnBuy:__initialTaxOnBuy).div(100);
            }
            if(buys_Count>0){
                taxAmount = amount.mul(transfer_Tax).div(100);
            }

            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _excludedTax[to] ) {
                require(amount <= maxTxAmt, "Exceeds the maxTxAmt.");
                require(balanceOf(to) + amount <= maxSizeOfWallet, "Exceeds the maxWalletSize.");
                taxAmount = amount.mul((buys_Count>__reduceTaxOnBuyAt)?__finalTaxOnBuy:__initialTaxOnBuy).div(100);
                buys_Count++;
            }

            if(to == uniswapV2Pair && from!= address(this) ){
                taxAmount = amount.mul((buys_Count>reduceTaxOnSellAt)?__finalTaxOnSell:__initialTaxOnSell).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && buys_Count > noSwapBefore) {
                if (block.number > lastBlockOfSell) {
                    sells_Count = 0;
                }
                require(sells_Count < 400, "Only 400 sells per block!");
                if(contractTokenBalance > 0)
                    swapTokensForEth(min(amount, min(contractTokenBalance, _tTaxMaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance >= 0) {
                    sendETHToFee(address(this).balance);
                }
                sells_Count++;
                lastBlockOfSell = block.number;
            }
        }

        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }


    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

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

    function removeLimits() public onlyOwner{
        maxTxAmt = _tTotalAmount;
        maxSizeOfWallet=_tTotalAmount;
        emit MaxTxAmountUpdated(_tTotalAmount);
    }

    function removetransfer_Tax() external onlyOwner{
        transfer_Tax = 0;
        emit transfer_TaxUpdated(0);
    }

    function sendETHToFee(uint256 amount) private {
        _NEXTAXWALLET.transfer(amount);
    }

    function enableTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotalAmount);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function clearRandomStuckEth() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function manualSwap() external {
        require(_msgSender()==_NEXTAXWALLET);
        uint256 tokenBalance=balanceOf(address(this));
        if(tokenBalance>0){
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance=address(this).balance;
        if(ethBalance>0){
          sendETHToFee(ethBalance);
        }
    }

    function manualsend() external {
        require(_msgSender()==_NEXTAXWALLET);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
}