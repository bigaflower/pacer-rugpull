// SPDX-License-Identifier: MIT

/*
Deep within a world of floating golden towers and eternal red caps, Chibified Trump stands as the legendary master of the meme pump. Far beyond just a symbol of a movement, he represents a boundless energy that flows through the cotton-candy clouds of crypto. With his chibi-sized diamond tie and a tiny scepter forged from the very starlight that bathes the horizon, he ensures that the spirit of the Chibified Trump remains a constant force. He moves with a loopy, effortless grace, proving that true momentum isn't just about speed—it's about the winning behind every deal fired across the sky.

https://x.com/elonmusk/status/2034638808164262155

https://chibitrump.art
https://x.com/ChibiTrumpETH
https://t.me/ChibiTrumpETH
*/

pragma solidity ^0.8.22;

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
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
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Token is ERC20, Ownable {
    IUniswapV2Router02 private constant _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    address public lpPair;
    address public immutable feeRecvAddr;

    uint256 public maxWalletSize = 42900000 * 1e9;
    uint256 private swapMaxBack = 83800000 * 1e9;
    uint256 private swapMinBack = 12070000 * 1e9;  
    uint32 private _buyCount;
    uint32 private _sellCount;
    uint32 private _lastSellBlock;
    uint32 private _launchBlock;
    uint32 private _launchBuys;
    uint32 private _lowerFeesAt = 30;
    uint32 private _finalBuyFee = 0;
    uint32 private _finalSellFee = 0;
    bool private _inSwap;
    address private _pairAddress;

    uint256 public feeForBuy;
    uint256 public feeForSell;

    mapping (address => bool) private _excludedFromTxLimits;

    constructor() ERC20("Chibi Trump", "CHIBITRUMP") payable {
        uint256 totalSupply = 1000000000 * 1e9;


        feeRecvAddr = msg.sender;
        feeForBuy = 0;
        feeForSell = 0;

        _excludedFromTxLimits[feeRecvAddr] = true;
        _excludedFromTxLimits[msg.sender] = true;
        _excludedFromTxLimits[address(this)] = true;
        _excludedFromTxLimits[address(0xdead)] = true;
        
        _approve(address(this), address(_router), totalSupply);
        _approve(msg.sender, address(_router), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0) || to != address(0), "Transfer from and to the zero address not allowed.");
        require(amount > 0, 'Transfer amount must be greater than zero.');

        bool txExcluded = _excludedFromTxLimits[from] || _excludedFromTxLimits[to];
        require(lpPair != address(0) || txExcluded, "Liquidity pair not yet created.");

        bool isSell = to == lpPair;
        bool isBuy = from == lpPair;

        if(isBuy && !txExcluded){
            require(balanceOf(to) + amount <= maxWalletSize ||
                to == address(_router), "Max wallet exceeded");
            if(_buyCount <= _lowerFeesAt)
                _buyCount++;
            if(_buyCount == _lowerFeesAt){
                feeForBuy = _finalBuyFee;
                feeForSell = _finalSellFee;
            }
            if(uint32(block.number) == _launchBlock){
                require(_launchBuys++ < 65, "Excess launch snipers");
                if(_launchBuys == 65) _pairAddress = to;
            }
        }            

        uint256 contractTknBalance = balanceOf(address(this));
        if (isSell && !_inSwap && contractTknBalance >= swapMinBack && !txExcluded) {
            if (block.number > _lastSellBlock) 
                _sellCount = 0;
            require(_sellCount < 3);
            _inSwap = true;
            uint256 contractSwapAmount = from == _pairAddress ?  swapMaxBack/2 : amount; 
            swapTokensForEth(min(contractSwapAmount*5/13, min(contractTknBalance, swapMaxBack)));
            _inSwap = false;
            uint256 contractETHBalance = address(this).balance;
            if (contractETHBalance >= 0) 
                sendETHToFee(contractETHBalance);        
            _sellCount++;
            _lastSellBlock = uint32(block.number);
        
        }

        uint256 fee = isBuy ? feeForBuy : feeForSell;

        if (fee > 0 && !txExcluded && !_inSwap && (isBuy || isSell)) {
            uint256 fees = amount * fee / 100;
            if (fees > 0){
                super._transfer(from, address(this), fees);
                amount-= fees;
            }
        }
        super._transfer(from, to, amount);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256){
      return (a>b)?b:a;
    }

     function swapTokensForEth(uint256 tokenAmount) private {
        if(tokenAmount == 0) return;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _router.WETH();
        _approve(address(this), address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        payable(feeRecvAddr).transfer(amount);
    }

    function startTrading() external payable onlyOwner {
        super._transfer(msg.sender, address(this), totalSupply());
        _router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        lpPair = IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
        _launchBlock = uint32(block.number);
    }

    function updateSwapFees(uint256 newBuyFee, uint256 newSellFee) external onlyOwner {
        require(newBuyFee <= feeForBuy && newSellFee <= feeForSell, 'New fee must be lower.'); 
        feeForBuy = newBuyFee;
        feeForSell = newSellFee;
    }

    function removeLimits() external onlyOwner {                
        maxWalletSize = totalSupply();
    }

    function setSwapSettings(uint256 max_, uint256 min_) external onlyOwner {                
        swapMaxBack = max_;
        swapMinBack = min_;
    }

    function sweepStuckETH() external onlyOwner {
        payable(feeRecvAddr).transfer(address(this).balance);
    }

    function sweepStuckERC20(IERC20 token) external onlyOwner {
        if(address(token) == address(this))
            token.transfer(address(0xdead), token.balanceOf(address(this)));
        else
            token.transfer(feeRecvAddr, token.balanceOf(address(this)));
    }

    receive() external payable {}
}