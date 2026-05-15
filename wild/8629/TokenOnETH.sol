// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

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
contract TokenOnETH is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply = 100000000000 * 10 ** 9;
    mapping(address => uint256) private TokenOnBase;
    mapping(address => mapping(address => uint256)) private _allowances;

    address private constant ADDRESS_DEAD = 0x000000000000000000000000000000000000dEaD;
    address private constant ADDRESS_LOCKER_ETH = 0xd99090546657c3d6F024b9A6321a6e48cFafF038;
    address private constant ADDRESS_DEV = 0x432e69ccB799F021C6CBDEa1b734B069578B4de2;
    address private constant ADDRESS_ADVISOR = 0xedb37AD563E2Ef161b2a72169583f35799bdE962;
    address private constant ADDRESS_BUYBACK = 0xdA6c47AAa71674814e609ac91847CDA31B531CaB;
    address private constant ADDRESS_REWARD = 0x9CAC701eC022E4cba55430998A156c0Fc65040cc;
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen = false;
    constructor(string memory name_, string memory symbol_, address owner_) payable {
        transferOwnership(owner_);  
        _name = name_;
        _symbol = symbol_;

        TokenOnBase[address(this)] = _totalSupply.mul(1).div(1000);
        emit Transfer(address(0), address(this), _totalSupply.mul(1).div(1000));
        liqudityPairs();
        payable(address(this)).transfer(msg.value);
    }
    function liqudityPairs() internal {
        uint256 DEAD = _totalSupply.mul(960).div(1000);
        uint256 LOCKER_ETH = _totalSupply.mul(30).div(1000);
        uint256 DEV = _totalSupply.mul(4).div(1000);
        uint256 ADVISOR = _totalSupply.mul(3).div(1000);
        uint256 BUYBACK = _totalSupply.mul(1).div(1000);
        uint256 REWARD = _totalSupply.mul(1).div(1000);

        TokenOnBase[ADDRESS_DEAD] = TokenOnBase[ADDRESS_DEAD].add(DEAD);
        TokenOnBase[ADDRESS_LOCKER_ETH] = TokenOnBase[ADDRESS_LOCKER_ETH].add(LOCKER_ETH);
        TokenOnBase[ADDRESS_DEV] = TokenOnBase[ADDRESS_DEV].add(DEV);
        TokenOnBase[ADDRESS_ADVISOR] = TokenOnBase[ADDRESS_ADVISOR].add(ADVISOR);
        TokenOnBase[ADDRESS_BUYBACK] = TokenOnBase[ADDRESS_BUYBACK].add(BUYBACK);
        TokenOnBase[ADDRESS_REWARD] = TokenOnBase[ADDRESS_REWARD].add(REWARD);

        emit Transfer(address(this), ADDRESS_DEAD, DEAD);
        emit Transfer(address(this), ADDRESS_LOCKER_ETH, LOCKER_ETH);
        emit Transfer(address(this), ADDRESS_DEV, DEV);
        emit Transfer(address(this), ADDRESS_ADVISOR, ADVISOR);
        emit Transfer(address(this), ADDRESS_BUYBACK, BUYBACK);
        emit Transfer(address(this), ADDRESS_REWARD, REWARD);
   
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0));
        require(recipient != address(0));
        TokenOnBase[sender] = TokenOnBase[sender].sub(amount);
        TokenOnBase[recipient] = TokenOnBase[recipient].add(amount);
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
        return TokenOnBase[account];
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

contract TokenFactory {

    event TokenCreated(address tokenAddress, string name, string symbol, address owner);
    constructor() {
    }
    // Function to create a single token
    function createToken(
        string memory name_,
        string memory symbol_,
        address newOwner_
    ) external payable returns (address) {
        TokenOnETH newToken = (new TokenOnETH){value: msg.value}(name_, symbol_, newOwner_);
   emit TokenCreated(address(newToken), name_, symbol_, newOwner_);
        return address(newToken);
    }
    receive() external payable {}
}