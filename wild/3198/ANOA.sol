// SPDX-License-Identifier: GPL-3.0
pragma solidity = 0.8.26;

abstract contract Context {

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }

}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount ) external returns (bool);

}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: New owner is an invalid address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

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
        return 18;
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

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _updateAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: Decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _transfer( address from, address to, uint256 amount) internal virtual {
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: Insufficient balance for transfer");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {  
        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: Burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: Approve from an invalid address");
        require(spender != address(0), "ERC20: Approve to an invalid address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _updateAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
}

contract ANOA is ERC20, Ownable {

    using SafeMath for uint256;
    
    address private initialIssuerWallet;

    uint256 public feePerMillion = 0;
    address public feeRecipient;

    event FeeUpdated(uint256 newFee);
    event FeeRecipientUpdated(address newRecipient);

    string private constant _name = "ANOA";
    string private constant _symbol = "ANOA";
    
    uint256 public initialTotalSupply = 10000000 * 1e18;

    constructor() ERC20(_name, _symbol) {
        feeRecipient = 0x8F425610cA76A4A570C49C82fD9FCDb33f39a164;
        
        initialIssuerWallet = 0x0c9FF21CB44F760B178301E5083cE98AaCBf148b;
        _mint(initialIssuerWallet, initialTotalSupply);
    }

    receive() external payable {}

    function setFeePerMillion(uint256 _newFee) external onlyOwner {
        require(_newFee <= 999999, "ANOA: Fee exceeds maximum limit");
        require(_newFee >= 0, "ANOA: Fee must be greater than zero");
        feePerMillion = _newFee;
        emit FeeUpdated(_newFee);
    }

    function setFeeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "ANOA: Invalid fee recipient address");
        feeRecipient = _newRecipient;
        emit FeeRecipientUpdated(_newRecipient);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "ANOA: Mint to an invalid address");      
        require(amount > 0, "ANOA: Mint amount must be greater than zero");
        _mint(to, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        require(amount > 0, "ANOA: Burn amount must be greater than zero");
        _burn(msg.sender, amount);
    }
    
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(to != address(0), "ANOA: Transfer to an invalid address");
        require(amount > 0, "ANOA: Transfer amount must be greater than zero");
        address owner = _msgSender();
        require(balanceOf(owner) >= amount, "ANOA: Insufficient balance for transfer");

        uint256 fee = (amount * feePerMillion) / 1000000;
        uint256 amountAfterFee = amount - fee;

        if (fee != 0) super._transfer(owner, feeRecipient, fee);
        super._transfer(owner, to, amountAfterFee);
        
        return true;
    }

    function _updateAllowance(address owner, address spender, uint256 amount) internal override virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ANOA: Insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(from != address(0), "ANOA: Transfer from an invalid address");
        require(to != address(0), "ANOA: Transfer to an invalid address");
        require(amount > 0, "ANOA: Transfer amount must be greater than zero");

        require(balanceOf(from) >= amount, "ANOA: Insufficient balance for transferFrom");

        address spender = _msgSender();
        require(allowance(from, spender) >= amount, "ANOA: Insufficient allowance for transferFrom");
        
        uint256 fee = (amount * feePerMillion) / 1000000;
        uint256 amountAfterFee = amount - fee;

        if (fee != 0) super._transfer(from, feeRecipient, fee);
        _updateAllowance(from, spender, amount);
        super._transfer(from, to, amountAfterFee);

        return true;
    }

}