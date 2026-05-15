// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/*

Twitter: https://x.com/KiwiSwapX
Telegram: http://t.me/KiwiSwaps
Website: http://kiwiswaps.com


██╗  ██╗██╗██╗    ██╗██╗
██║ ██╔╝██║██║    ██║██║
█████╔╝ ██║██║ █╗ ██║██║
██╔═██╗ ██║██║███╗██║██║
██║  ██╗██║╚███╔███╔╝██║
╚═╝  ╚═╝╚═╝ ╚══╝╚══╝ ╚═╝
                        

*/

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);
}

contract Kiwi is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public _isExcludedFromFee;

    uint8 private constant _decimals = 18;
    uint256 private constant _tTotal = 1000000000 * 10 ** _decimals;
    string private constant _name = unicode"Kiwi";
    string private constant _symbol = unicode"KIWI";
    uint256 public _taxSwapThreshold = 100000 * 10 ** _decimals;
    mapping(address => bool) public blacklisted;

    address payable public _devWallet =
        payable(0x618C8E172b62B900392981AFc8A67FCef448d73C);

    address payable public _charityWallet =
        payable(0x618C8E172b62B900392981AFc8A67FCef448d73C);

    address payable public _marketingWallet =
        payable(0x618C8E172b62B900392981AFc8A67FCef448d73C);

    uint256 public _kiwiMarketingBuyFee = 0;
    uint256 public _kiwiDeveloperBuyFee = 0;
    uint256 public _kiwiCharityBuyFee = 0;
    uint256 public _kiwiTotalBuyFee = 0;

    uint256 public _kiwiMarketingSellFee = 0;
    uint256 public _kiwiCharitySellFee = 0;
    uint256 public _kiwiDeveloperSellFee = 0;
    uint256 public _kiwiTotalSellFee = 0;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private inSwap = false;
    bool private swapEnabled = true;
    bool public KiwiEnabled = false;

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    event TaxWalletPaymentRevert(address indexed taxWallet, uint256 amount);

    constructor() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        // IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1); // test router address

        // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_charityWallet] = true;
        _isExcludedFromFee[_devWallet] = true;
        _isExcludedFromFee[_marketingWallet] = true;

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

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
        require(
            !blacklisted[from] && !blacklisted[to],
            "Address is blacklisted"
        );
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount = 0;
        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(KiwiEnabled, "Kiwi to be enabled");

            if (_kiwiTotalBuyFee > 0) {
                if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                    taxAmount = amount.mul(_kiwiTotalBuyFee).div(100);
                }
            }

            if (_kiwiTotalSellFee > 0) {
                if (to == uniswapV2Pair) {
                    taxAmount = amount.mul(_kiwiTotalSellFee).div(100);
                }
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _kiwiTotalSellFee > 0
            ) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);
            emit Transfer(from, address(this), taxAmount);
        }
        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        if (tokenAmount == 0) {
            return;
        }
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
        if (amount == 0) return;

        uint256 marketingShare = amount.mul(_kiwiMarketingSellFee).div(
            _kiwiTotalSellFee
        );
        uint256 developerShare = amount.mul(_kiwiDeveloperSellFee).div(
            _kiwiTotalSellFee
        );
        uint256 charityShare = amount.mul(_kiwiCharitySellFee).div(
            _kiwiTotalSellFee
        );

        if (marketingShare > 0) {
            (bool success, ) = _marketingWallet.call{value: marketingShare}("");
            if (!success)
                emit TaxWalletPaymentRevert(_marketingWallet, marketingShare);
        }

        if (developerShare > 0) {
            (bool success, ) = _devWallet.call{value: developerShare}("");
            if (!success)
                emit TaxWalletPaymentRevert(_devWallet, developerShare);
        }

        if (charityShare > 0) {
            (bool success, ) = _charityWallet.call{value: charityShare}("");
            if (!success)
                emit TaxWalletPaymentRevert(_charityWallet, charityShare);
        }
    }

    receive() external payable {}

    function enableKiwi() public onlyOwner {
        require(KiwiEnabled != true, "Kiwi enabled already");
        KiwiEnabled = true;
    }

    function updateTaxSwapThreshold(uint256 _taxLimit) public onlyOwner {
        require(_taxLimit > 0, "Threshold cannot be 0");
        _taxSwapThreshold = _taxLimit;
    }

    function excludeFromTaxes(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInTaxes(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function blacklistAddress(address account) external onlyOwner {
        blacklisted[account] = true;
    }

    function whitelistAddress(address account) external onlyOwner {
        blacklisted[account] = false;
    }

    function updateBuyFee(
        uint256 marketingBuyFee,
        uint256 charityBuyFee,
        uint256 developerBuyFee
    ) public onlyOwner {
        uint256 totalBuyFee = marketingBuyFee + charityBuyFee + developerBuyFee;
        require(totalBuyFee <= 5, "Buy fee cannot be higher than 5%");

        _kiwiMarketingBuyFee = marketingBuyFee;
        _kiwiCharityBuyFee = charityBuyFee;
        _kiwiDeveloperBuyFee = developerBuyFee;
        _kiwiTotalBuyFee = totalBuyFee;
    }

    function updateSellFee(
        uint256 marketingSellFee,
        uint256 charitySellFee,
        uint256 developerSellFee
    ) public onlyOwner {
        uint256 totalSellFee = marketingSellFee +
            charitySellFee +
            developerSellFee;
        require(totalSellFee <= 5, "Sell fee cannot be higher than 5%");

        _kiwiMarketingSellFee = marketingSellFee;
        _kiwiCharitySellFee = charitySellFee;
        _kiwiDeveloperSellFee = developerSellFee;
        _kiwiTotalSellFee = totalSellFee;
    }

    function manualSwap() external onlyOwner {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }
        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
}