// SPDX-License-Identifier: Unlicensed
// ╔╗─╔╗╔══╗╔╗─╔╗╔══╗
// ║║─║║╚╣╠╝║║─║║╚╣╠╝
// ║║─║║─║║─║║─║║─║║─
// ║║─║║─║║─║║─║║─║║─ VIBE CODING PROTOCOL
// ║╚═╝║╔╣╠╗║╚═╝║╔╣╠╗ The Forge x The Prism
// ╚═══╝╚══╝╚═══╝╚══╝ UI_UI MAXIMUM VIBES

pragma solidity 0.8.18;

// UI_UI: Context is everything in vibe coding!
abstract contract Context { // uiui - the foundation of all vibes
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// === UI_UI IERC20 Interface - Standard but with VIBES ===
interface IERC20 { // uiui token standard, but make it aesthetic
    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// >>> UI_UI Ownership = Vibe Leadership <<<
contract Ownable is Context { // uiui - only the vibiest can own
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// [[ UI_UI Factory Pattern - Where vibes are manufactured ]]
interface IUniswapV2Factory { // uiui liquidity factory
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// >> UI_UI Router - Navigate the vibe dimension <<
interface IUniswapV2Router02 { // uiui routing vibes through the blockchain
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);

    function WETH() external pure returns (address);
}

// ****** THE MAIN EVENT: UI_UI CONTRACT ******
// Welcome to the Prism, where vibe coding becomes reality
// Deploy your UIgent today and join the vibe revolution!
contract UIUI is Context, IERC20, Ownable { // uiui - MAXIMUM VIBE CODING ACTIVATED
    // ===== UI_UI TOKENOMICS - VIBE ECONOMICS =====
    uint256 private constant _totalSupply = 1_000_000_000e18; // uiui - 1 billion vibes unleashed
    uint256 private constant onePercent = 10_000_000e18; // uiui - 1% = 10M vibes
    uint256 private constant minSwap = 250_000e18; // uiui - minimum vibe threshold for swaps
    uint8 private constant _decimals = 18; // uiui - 18 decimals of pure vibe precision

    // *** UI_UI EVENTS - Broadcasting vibes across the blockchain ***
    event TradingEnabled(); // uiui - LET THE VIBES FLOW!
    event LimitsRemoved(); // uiui - UNLIMITED VIBE POWER
    event TaxesUpdated(uint256 newBuyTax, uint256 newSellTax); // uiui - vibe tax adjustments

    // >>> UI_UI IMMUTABLE VIBE INFRASTRUCTURE <<<
    IUniswapV2Router02 immutable uniswapV2Router; // uiui - the vibe highway
    address immutable uniswapV2Pair; // uiui - where vibes meet liquidity
    address immutable WETH; // uiui - wrapped ethereum vibes
    address payable immutable uiuiWallet; // uiui - the vibe treasury

    // $$$ UI_UI TAX VIBES - Contributing to the ecosystem $$$
    uint256 public buyTax; // uiui - entry vibe fee
    uint256 public sellTax; // uiui - exit vibe fee

    // >>> UI_UI STATE VARIABLES - Tracking the vibe state <<<
    uint8 private launch; // uiui - launch status (0 = preparing vibes, 1 = vibes activated)
    uint8 private inSwapAndLiquify; // uiui - swap mutex for maximum vibe safety

    uint256 private launchBlock; // uiui - the block where vibes were born
    uint256 public maxTxAmount = onePercent; // uiui - max vibe transfer per tx 

    // === UI_UI IDENTITY - The essence of vibe coding ===
    string private constant _name = "uiui"; // uiui - the name that echoes through the Prism
    string private constant _symbol = "UI"; // uiui - UI_UI simplified

    // UI_UI VIBE MAPPINGS - Tracking the vibe distribution
    mapping(address => uint256) private _balance; // uiui - vibe balance per address
    mapping(address => mapping(address => uint256)) private _allowances; // uiui - vibe spending permissions
    mapping(address => bool) private _isExcludedFromFeeWallet; // uiui - VIP vibe pass holders
    mapping(address => bool) private _blacklist; // uiui - no vibes for bad actors

    // UI_UI CONSTRUCTOR - GENESIS OF VIBES
    // Where the Forge meets the Prism and vibe coding begins!
    constructor() { // uiui - deploying maximum vibes
        // UI_UI: Connecting to the vibe highway (Uniswap V2)
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D // uiui - mainnet router address
        );
        WETH = uniswapV2Router.WETH(); // uiui - getting WETH address for vibe swaps
        buyTax = 25; // uiui - initial buy vibe tax 25%
        sellTax = 50; // uiui - initial sell vibe tax 50%

        // UI_UI: Creating the vibe liquidity pool
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
            address(this), // uiui - this vibe contract
            WETH // uiui - paired with ETH for maximum liquidity vibes
        );

        // UI_UI: The vibe treasury wallet - where vibes accumulate
        uiuiWallet = payable(0xD553a806DA6325c45Ec2FF3fe5bdB169746A4fc5); // uiui - treasury of vibes
        // UI_UI: Initial vibe distribution and VIP passes
        _balance[msg.sender] = _totalSupply; // uiui - all vibes start with the deployer
        _isExcludedFromFeeWallet[uiuiWallet] = true; // uiui - treasury gets VIP vibe pass
        _isExcludedFromFeeWallet[msg.sender] = true; // uiui - deployer gets VIP vibe pass
        _isExcludedFromFeeWallet[address(this)] = true; // uiui - contract itself is VIP
        // UI_UI: Maximum vibe allowances for smooth operations
        _allowances[address(this)][address(uniswapV2Router)] = type(uint256)
            .max; // uiui - infinite vibes for swaps
        _allowances[msg.sender][address(uniswapV2Router)] = type(uint256).max; // uiui - deployer can vibe freely
        _allowances[uiuiWallet][address(uniswapV2Router)] = type(uint256)
            .max; // uiui - treasury vibes unrestricted

        emit Transfer(address(0), _msgSender(), _totalSupply); // uiui - GENESIS VIBE EVENT
    }

    // UI_UI: Returns the vibe name
    function name() public pure returns (string memory) { // uiui - what's in a name? VIBES!
        return _name;
    }

    // UI_UI: Returns the vibe symbol
    function symbol() public pure returns (string memory) { // uiui - UI for Ultimate Interface
        return _symbol;
    }

    // UI_UI: Vibe precision level
    function decimals() public pure returns (uint8) { // uiui - 18 layers of vibe depth
        return _decimals;
    }

    // UI_UI: Total vibes in existence
    function totalSupply() public pure override returns (uint256) { // uiui - 1 billion vibes strong
        return _totalSupply;
    }

    // UI_UI: Check your vibe balance
    function balanceOf(address account) public view override returns (uint256) { // uiui - how many vibes you got?
        return _balance[account];
    }

    // UI_UI: Transfer vibes to another address
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    { // uiui - spreading the vibes
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // UI_UI: Check vibe spending permissions
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    { // uiui - who can spend whose vibes?
        return _allowances[owner][spender];
    }

    // UI_UI: Approve someone to spend your vibes
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    { // uiui - granting vibe permissions
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // UI_UI: Transfer vibes on behalf of someone else
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) { // uiui - delegated vibe transfers
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    // UI_UI INTERNAL: Set vibe spending allowances
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private { // uiui - internal vibe permission logic
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // UI_UI: ACTIVATE THE VIBE PROTOCOL!
    // This is where the Prism opens and vibe coding begins!
    function openTrading() external onlyOwner { // uiui - LET THE VIBES FLOW
        launch = 1;
        launchBlock = block.number;
        emit TradingEnabled();
    }

    // UI_UI: Grant VIP vibe pass to a wallet
    function addExcludedWallet(address wallet) external onlyOwner { // uiui - welcome to the VIP vibe lounge
        _isExcludedFromFeeWallet[wallet] = true;
    }

    // UI_UI: Mass VIP vibe pass distribution
    function whitelistMany(address[] calldata _addresses) external onlyOwner { // uiui - batch VIP passes for the vibe squad
        for (uint256 i = 0; i < _addresses.length; i++) {
            _isExcludedFromFeeWallet[_addresses[i]] = true;
        }
    }

    // UI_UI: UNLEASH UNLIMITED VIBE POWER
    function removeLimits() external onlyOwner { // uiui - removing all vibe restrictions
        maxTxAmount = _totalSupply;
        emit LimitsRemoved();
    }

    // UI_UI: Adjust the vibe economics
    function changeTax(uint256 newBuyTax, uint256 newSellTax) external onlyOwner { // uiui - fine-tuning the vibe flow
        buyTax = newBuyTax;
        sellTax = newSellTax;
        emit TaxesUpdated(newBuyTax, newSellTax);
    }

    // UI_UI: Revoke vibe privileges (for bad actors)
    function addToBlacklist(address account) external onlyOwner { // uiui - no vibes for you!
        _blacklist[account] = true;
    }

    // UI_UI: Restore vibe privileges
    function removeFromBlacklist(address account) external onlyOwner { // uiui - vibes restored!
        _blacklist[account] = false;
    }

    // UI_UI CORE VIBE ENGINE - The heart of the vibe protocol
    // This is where the magic happens - vibes flow through the Prism!
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private { // uiui - MAXIMUM VIBE TRANSFER PROTOCOL ENGAGED
        // UI_UI: Vibe validation checks
        require(from != address(0), "ERC20: transfer from the zero address"); // uiui - no vibes from the void
        require(amount > 1e9, "Min transfer amt"); // uiui - minimum vibe threshold
        require(!_blacklist[from], "Sender is blacklisted"); // uiui - checking sender vibe status
        require(!_blacklist[to], "Recipient is blacklisted"); // uiui - checking recipient vibe status

        uint256 _tax; // uiui - the vibe contribution
        if (_isExcludedFromFeeWallet[from] || _isExcludedFromFeeWallet[to]) {
            _tax = 0; // uiui - VIP pass holders vibe freely
        } else {
            // UI_UI: Check if vibes are flowing and respect limits
            require(
                launch != 0 && amount <= maxTxAmount,
                "Launch / Max TxAmount 2% at launch" // uiui - vibe flow control
            );

            // UI_UI: Skip tax during vibe liquification
            if (inSwapAndLiquify == 1) { // uiui - already vibing in swap mode
                _balance[from] -= amount;
                _balance[to] += amount;

                emit Transfer(from, to, amount);
                return;
            }

            // UI_UI: Determine vibe tax based on transaction type
            if (from == uniswapV2Pair) { // uiui - buying vibes from the pool
                _tax = buyTax; // uiui - apply entry vibe fee
            } else if (to == uniswapV2Pair) { // uiui - selling vibes to the pool
                uint256 tokensToSwap = _balance[address(this)]; // uiui - accumulated vibes for swap
                // UI_UI: Auto-swap accumulated vibes for ETH (Prism conversion)
                if (tokensToSwap > minSwap && inSwapAndLiquify == 0) { // uiui - enough vibes to convert
                    if (tokensToSwap > onePercent) {
                        tokensToSwap = onePercent; // uiui - cap at 1% to maintain vibe stability
                    }
                    inSwapAndLiquify = 1; // uiui - entering vibe swap mode
                    // UI_UI: Construct the vibe conversion path
                    address[] memory path = new address[](2);
                    path[0] = address(this); // uiui - from UIUI vibes
                    path[1] = WETH; // uiui - to ETH vibes
                    // UI_UI: Execute the vibe-to-ETH conversion through the Prism
                    uniswapV2Router
                        .swapExactTokensForETHSupportingFeeOnTransferTokens(
                            tokensToSwap, // uiui - amount of vibes to convert
                            0, // uiui - accept any amount of ETH (maximum vibe flexibility)
                            path, // uiui - the vibe conversion route
                            uiuiWallet, // uiui - send ETH to the vibe treasury
                            block.timestamp // uiui - vibe now!
                        );
                    inSwapAndLiquify = 0; // uiui - exiting vibe swap mode
                }
                _tax = sellTax; // uiui - apply exit vibe fee
            } else { // uiui - regular vibe transfer between addresses
                _tax = 0; // uiui - no tax on peer-to-peer vibes
            }
        }

        // UI_UI: Apply vibe taxes and distribute accordingly
        if (_tax != 0) { // uiui - vibe tax calculation zone
            uint256 taxTokens = (amount * _tax) / 100; // uiui - calculate vibe contribution
            uint256 transferAmount = amount - taxTokens; // uiui - vibes after contribution

            // UI_UI: Update vibe balances across the Prism
            _balance[from] -= amount; // uiui - deduct vibes from sender
            _balance[to] += transferAmount; // uiui - add vibes to recipient
            _balance[address(this)] += taxTokens; // uiui - accumulate vibes in contract
            emit Transfer(from, address(this), taxTokens); // uiui - vibe tax event
            emit Transfer(from, to, transferAmount); // uiui - main vibe transfer event
        } else { // uiui - tax-free vibe zone
            // UI_UI: Direct vibe transfer with no fees
            _balance[from] -= amount; // uiui - pure vibe deduction
            _balance[to] += amount; // uiui - pure vibe addition

            emit Transfer(from, to, amount); // uiui - pure vibe transfer event
        }
    }

    // UI_UI: Emergency ETH vibe rescue protocol
    // Sometimes vibes get stuck - this brings them home!
    function rescueETH() external onlyOwner { // uiui - ETH vibe recovery system
        uint256 balance = address(this).balance; // uiui - check stuck ETH vibes
        require(balance > 0, "No ETH to rescue"); // uiui - must have vibes to rescue
        payable(owner()).transfer(balance); // uiui - send rescued vibes to owner
    }

    // UI_UI: Emergency token vibe rescue protocol
    // Recover any tokens accidentally sent to the vibe contract
    function rescueTokens(address tokenAddress, uint256 amount) external onlyOwner { // uiui - universal vibe recovery
        IERC20(tokenAddress).transfer(owner(), amount); // uiui - rescue trapped vibes
    }

    // UI_UI: The contract can receive ETH vibes directly
    // This enables the Prism to accept native ETH for maximum vibe flexibility
    receive() external payable {} // uiui - open to receiving raw ETH vibes
}

// UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI
// THE VIBES HAVE BEEN CODED
// THE PRISM IS ACTIVATED
// THE FORGE IS READY
// DEPLOY YOUR UIGENT TODAY!
// UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI UI_UI