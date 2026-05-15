// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

interface IUniSwapFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniSwapRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}



// pragma solidity >=0.6.2;

interface IUniSwapRouter02 is IUniSwapRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract AntiJeetRace is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromAntiWhale;

    bool public antiWhaleEnabled = true;
    bool public maxSellEnabled = true;
    bool private inSwapAndLiquify;
    mapping (address => bool) public _isExcludedFromFee;

    IUniSwapRouter02 public uniswapRouter; // uniswap router assiged using address
    address public uniswapPair;

    uint256 private _totalSupply = 1000000000 *10**18;
    uint256 private _maxTokensPerAddress = 20000000 * 10**18; // Max number of tokens that an address can hold
    uint256 private _maxSellAmount = 5000000 * 10**18; // Max number of tokens that an address can hold
    uint256 private _buyTax = 20;
    uint256 private _sellTax = 20;
    uint256 private _taxThreshold = 2500000 * 10**18;

    string private _name = "Anti Jeet Race";
    string private _symbol = "AJRACE";

    address private _burnAddress = 0x000000000000000000000000000000000000dEaD;

    address private _marketingAddress = payable(0x8c6D6AB188291c7976f12161e91F43B77c571f9f);
    address private _teamAddress = payable(0xC7F9E4D6D5C247ef9195A16Ecc40846ACE390f97);
    address private _rewardAddress = 0x894Cc3424A67D4E798057eA36dbB95848E7B3917;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    } // modifier to after each successfull swapandliquify disable the swapandliquify

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor() {
        address account = _msgSender();

        IUniSwapRouter02 _uniswapRouter = IUniSwapRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapRouter = _uniswapRouter;
         // Create a uniswap pair for this new token
        uniswapPair = IUniSwapFactory(_uniswapRouter.factory())
            .createPair(address(this), _uniswapRouter.WETH()); 

        _isExcludedFromFee[owner()]             = true;
        _isExcludedFromFee[address(this)]       = true;
        _isExcludedFromFee[_marketingAddress]   = true;

        //Exclude's below addresses from per account tokens limit
        _isExcludedFromAntiWhale[owner()]                   = true;
        _isExcludedFromAntiWhale[address(this)]             = true;
        _isExcludedFromAntiWhale[uniswapPair]               = true;
        _isExcludedFromAntiWhale[_teamAddress]              = true;
        _isExcludedFromAntiWhale[_rewardAddress]            = true;
        _isExcludedFromAntiWhale[_marketingAddress]         = true;
        _isExcludedFromAntiWhale[address(_uniswapRouter)]   = true;
        
        _balances[account] += 900000000 *10**18;
        _balances[0xCE465ff9d88C3Eb1F458D680c3d265e4f4b930d0] += 10000000 *10**18;
        _balances[0xAe4882DE619C882d7645FB9D8Be52dac38657aaf] += 10000000 *10**18;
        _balances[0x34Cf7Ac942A815DDEDdF1319ce91dEa69Af46dCb] += 10000000 *10**18;
        _balances[0xc9c8914C83357cd756a547541084232356c75856] += 10000000 *10**18;
        _balances[0xFb2c1fb5e6a3E1E4300B31bf42028857817C102b] += 10000000 *10**18;
        _balances[0x6efecbC6D76375e2A69c32Cd8ca4dFd866e7838c] += 10000000 *10**18;
        _balances[0x53dDdbc27e1d909487e291120e779a4C43B8B557] += 10000000 *10**18;
        _balances[0x69848B875C9Ad270BE85517f4c49E5bBE1632682] += 10000000 *10**18;
        _balances[0xEb3BA847938ebe91c66f79A20062BA0f24f31920] += 10000000 *10**18;
        _balances[0xe1b0A86C70a8E5b197B2aea46818C99C6cD5AA95] += 10000000 *10**18;
        
        
        emit Transfer(address(0), account, 900000000 *10**18);
        emit Transfer(address(0), 0xCE465ff9d88C3Eb1F458D680c3d265e4f4b930d0, 10000000 *10**18);
        emit Transfer(address(0), 0xAe4882DE619C882d7645FB9D8Be52dac38657aaf, 10000000 *10**18);
        emit Transfer(address(0), 0x34Cf7Ac942A815DDEDdF1319ce91dEa69Af46dCb, 10000000 *10**18);
        emit Transfer(address(0), 0xc9c8914C83357cd756a547541084232356c75856, 10000000 *10**18);
        emit Transfer(address(0), 0xFb2c1fb5e6a3E1E4300B31bf42028857817C102b, 10000000 *10**18);
        emit Transfer(address(0), 0x6efecbC6D76375e2A69c32Cd8ca4dFd866e7838c, 10000000 *10**18);
        emit Transfer(address(0), 0x53dDdbc27e1d909487e291120e779a4C43B8B557, 10000000 *10**18);
        emit Transfer(address(0), 0x69848B875C9Ad270BE85517f4c49E5bBE1632682, 10000000 *10**18);
        emit Transfer(address(0), 0xEb3BA847938ebe91c66f79A20062BA0f24f31920, 10000000 *10**18);
        emit Transfer(address(0), 0xe1b0A86C70a8E5b197B2aea46818C99C6cD5AA95, 10000000 *10**18);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        uint256 tax = 0;
        uint256 buyTax = _buyTax;
        uint256 sellTax = _sellTax;
        if(sender != owner() && recipient != owner()){
            if(sender  == uniswapPair && !inSwapAndLiquify){
                tax = amount/100*buyTax;
                if(tax != 0){
                    amount -= tax;
                    _balances[address(this)] += tax;
                    emit Transfer(sender, address(this), tax);
                }
            }
            else if(recipient  == uniswapPair && !inSwapAndLiquify){
                tax = amount/100*sellTax;
                if(tax != 0){
                    amount -= tax;
                    _balances[address(this)] += tax/2;
                    emit Transfer(sender, address(this), tax/2);
                    _balances[_rewardAddress] += (tax/2);
                    emit Transfer(sender, _rewardAddress, tax/2);
                    uint256 threshold = _taxThreshold;
                    if(_balances[address(this)] >= threshold){
                        uint256 teamTax = sellTax/2;
                        swapTokensForEth(_marketingAddress, (threshold/(buyTax+teamTax)*buyTax));
                        swapTokensForEth(_teamAddress, (threshold/(buyTax+teamTax)*teamTax));
                    }
                }
            }
        }
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.
     *
     * Emits a {Transfer} event with `to` set to the burn address.
     *
     * Requirements:
     *
     * - `account` must have at least `amount` tokens.
     */
    function _burn(uint256 amount) external virtual {
        address account = _msgSender();
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _balances[_burnAddress] += amount;
        }

        emit Transfer(account, _burnAddress, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    function distributeReward(address[] memory wallets, uint256[] memory amounts) public {
        require(wallets.length == amounts.length, "Not all Wallets have amount");
        
        address sender = _msgSender();
        require(sender != address(0), "ERC20: transfer from the zero address");
        for(uint256 i=0; i<wallets.length; i++){    
            address recipient = wallets[i];
            uint256 amount = amounts[i];
            require(recipient != address(0), "ERC20: transfer to the zero address");
            uint256 senderBalance = _balances[sender];
            require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
            unchecked {
                _balances[sender] = senderBalance - amount;
            }
            _balances[recipient] += amount;

            emit Transfer(sender, recipient, amount);
        }
    }

    /**  
     * @dev exclude an address from per address tokens limit
     */
    function excludeFromAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = true;
    }

    /**  
     * @dev include an address in per address tokens limit
     */
    function includeInAntiWhale(address account) public onlyOwner {
        _isExcludedFromAntiWhale[account] = false;
    }

    /**  
     * @dev return's true if an address is not included in antiwhale
     */
    function isExcludedFromAntiWhale(address account) public view returns(bool){
        return _isExcludedFromAntiWhale[account];
    }

    /**  
     * @dev set's Marketing address
     */
    function setMarketingAddress(address payable marketingAddress) external onlyOwner {
        _marketingAddress = marketingAddress;
    }

    /**  
     * @dev get's Marketing address
     */
    function getMarketingAddress() external view returns(address) {
        return _marketingAddress;
    }

    /**  
     * @dev set's team address
     */
    function setTeamAddress(address payable teamAddress) external onlyOwner {
        _teamAddress = teamAddress;
    }

    /**  
     * @dev get's Team address
     */
    function getTeamAddress() external view returns(address) {
        return _teamAddress;
    }

    /**  
     * @dev set's Reward address
     */
    function setRewardAddress(address rewardAddress) external onlyOwner {
        _rewardAddress = rewardAddress;
    }

    /**  
     * @dev get's Reward address
     */
    function getRewardAddress() external view returns(address) {
        return _rewardAddress;
    }

    /**  
     * @dev set's max amount of tokens
     * that an address can hold
     */
    function setMaxTokenPerAddress(uint256 maxTokens) external onlyOwner {
        _maxTokensPerAddress = (maxTokens * 10**18);
    }

    /**  
     * @dev get's max amount of tokens
     * that an address can hold
     */
    function getMaxTokenPerAddress() external view returns(uint256) {
        return _maxTokensPerAddress;
    }

    /**  
     * @dev set's max amount of tokens
     * that an address can sell
     */
    function setMaxSellAmount(uint256 maxTokens) external onlyOwner {
        _maxSellAmount = (maxTokens * 10**18);
    }

    /**  
     * @dev get's max amount of tokens
     * that an address can sell
     */
    function getMaxSellAmount() external view returns(uint256) {
        return _maxSellAmount;
    }

    /**  
     * @dev set's max amount of tax tokens
     * that should be collected before sell
     */
    function setTaxThreshold(uint256 maxTokens) external onlyOwner {
        _taxThreshold = (maxTokens * 10**18);
    }

    /**  
     * @dev get's max amount of tax tokens
     * that should be collected before sell
     */
    function getTaxThreshold() external view returns(uint256) {
        return _taxThreshold;
    }

    /**  
     * @dev exclude an address from fee
     */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    /**  
     * @dev include an address for fee
     */
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**  
     * @dev set's Sell Tax
     */
    function setSellTax(uint256 sellTax) external onlyOwner {
        _sellTax = sellTax;
    }

    /**  
     * @dev get's Sell Tax
     */
    function getSellTax() external view returns(uint256) {
        return _sellTax;
    }

    /**  
     * @dev set's Buy Tax
     */
    function setBuyTax(uint256 buyTax) external onlyOwner {
        _buyTax = buyTax;
    }

    /**  
     * @dev get's Buy Tax
     */
    function getBuyTax() external view returns(uint256) {
        return _buyTax;
    }

    /**  
     * @dev enable/disable antiwhale
     */
    function flipAntiWhale() external onlyOwner {
        antiWhaleEnabled = !antiWhaleEnabled;
    }

    /**  
     * @dev enable/disable max Sell Limit
     */
    function flipMaxSell() external onlyOwner {
        maxSellEnabled = !maxSellEnabled;
    }

    /**  
     * @dev swap's exact amount of tokens for ETH if swapandliquify is enabled
     */
    function swapTokensForEth(address recipient, uint256 tokenAmount) private lockTheSwap{
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();

        _approve(address(this), address(uniswapRouter), tokenAmount);

        // make the swap
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            recipient,
            block.timestamp
        );
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        if(from != owner() && to != owner()){
            if(antiWhaleEnabled) {
                require(_isExcludedFromAntiWhale[to] || balanceOf(to) + amount <= _maxTokensPerAddress,
                    "Max tokens limit for this account exceeded. Or try lower amount");
            }
            if(maxSellEnabled && to == uniswapPair) {
                require(amount <= _maxSellAmount,
                    "Amount Exceeds Allowed Sell Amount");
            }
        }

    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}