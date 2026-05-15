/*
    Octora AI - Contextual Power. Unified Intelligence.                                                                                                                                                                                                                            
                        
    Website:      https://octora.ai/
    X (Twitter):  https://x.com/octora_agent
    Telegram:     https://t.me/OctoraAI_Portal
    Medium:       https://medium.com/@OctoraAI
    GitHub:       https://github.com/Octora-AI

*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
    function approve(address spender, uint256 amount)
        external
        returns (bool);
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    
    function transfer(address recipient, uint256 amount)
        public virtual override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender)
        public view virtual override returns (uint256)
    {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount)
        public virtual override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool)
    {
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }
        _transfer(sender, recipient, amount);
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue)
        public virtual returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public virtual returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }
        return true;
    }
    
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from zero address");
        require(recipient != address(0), "ERC20: transfer to zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to zero address");
        _beforeTokenTransfer(address(0), account, amount);
        
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        
        _afterTokenTransfer(address(0), account, amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from zero address");
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
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}



interface IUniswapFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapRouter02 {
    function factory() external view returns (address);
    function WETH() external view returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}



contract OctoraAI is ERC20, Ownable {
   
    uint256 public buyFee = 5;
    uint256 public sellFee = 5;
    
    
    address public immutable marketingWallet;
    address public immutable stakingWallet;
    
    
    IUniswapRouter02 public immutable uniswapRouter;
    address public uniswapPair;
    
    
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    
    bool private swapping;
    uint256 public swapTokensAtAmount;
    
    
    mapping(address => bool) private isExcludedFromFees;
    mapping(address => bool) private isExcludedFromMaxWalletLimit;
    
    
    uint256 private maxWalletLimitRate = 20;
    
    event ExcludeFromFees(address indexed account, bool isExcluded);
    
    constructor(address _marketingWallet, address _stakingWallet)
        ERC20("Octora AI", "OCTA")
    {
        marketingWallet = _marketingWallet;
        stakingWallet = _stakingWallet;
        
       
        IUniswapRouter02 _uniswapRouter = IUniswapRouter02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapPair = IUniswapFactory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH());
        uniswapRouter = _uniswapRouter;
        
        _approve(address(this), address(uniswapRouter), type(uint256).max);
        
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[DEAD] = true;
        isExcludedFromFees[address(this)] = true;
        
        isExcludedFromMaxWalletLimit[owner()] = true;
        isExcludedFromMaxWalletLimit[DEAD] = true;
        isExcludedFromMaxWalletLimit[address(this)] = true;
        isExcludedFromMaxWalletLimit[address(0)] = true;
        
        _mint(owner(), 21e6 * 1e18);
        swapTokensAtAmount = totalSupply() / 500;
    }
    
    receive() external payable {}
    

    function sendETH(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "ETH transfer failed");
    }


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
        

        if (canSwap && !swapping && from != uniswapPair && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            swapping = true;
            
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = uniswapRouter.WETH();
            
            uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
                contractTokenBalance,
                0,
                path,
                address(this),
                block.timestamp
            );
            
            uint256 newBalance = address(this).balance;
            if (newBalance > 0) {
                uint256 marketingAmount = (newBalance * 80) / 100;
                uint256 stakingAmount = newBalance - marketingAmount;
                sendETH(payable(marketingWallet), marketingAmount);
                sendETH(payable(stakingWallet), stakingAmount);
            }
            swapping = false;
        }
        
        bool takeFee = !swapping;
        if (isExcludedFromFees[from] || isExcludedFromFees[to] || (from != uniswapPair && to != uniswapPair)) {
            takeFee = false;
        }
        
        if (takeFee) {
            uint256 totalFees;
            if (from == uniswapPair) {
                totalFees = buyFee;
            } else if (to == uniswapPair) {
                totalFees = sellFee;
            }
            if (totalFees > 0) {
                uint256 fees = (amount * totalFees) / 100;
                amount = amount - fees;
                super._transfer(from, address(this), fees);
            }
        }
        
       
        if (
            !isExcludedFromMaxWalletLimit[from] &&
            !isExcludedFromMaxWalletLimit[to] &&
            to != uniswapPair &&
            from == uniswapPair
        ) {
            uint256 balanceAfter = balanceOf(to);
            require(
                balanceAfter + amount <= (totalSupply() * maxWalletLimitRate) / 1000,
                "max wallet limit exceeded"
            );
        }
        
        super._transfer(from, to, amount);
    }
}