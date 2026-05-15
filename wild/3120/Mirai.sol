// SPDX-License-Identifier: MIT

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable2Step, Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "./Interfaces.sol";

pragma solidity ^0.8.19;

contract MIRAI is
    ERC20,
    ERC20Burnable,
    AccessControl,
    ERC20Permit,
    Ownable2Step
{
    IUniswapV2Router02 immutable uniswapV2Router;
    uint256 public maxTxAmount;
    uint256 public maxWalletAmount;
    uint256 public buyTax = 35;
    uint256 public sellTax = 35;
    uint256 constant MAX_BUY_TAX_PERCENTAGE = 10;
    uint256 constant MAX_SELL_TAX_PERCENTAGE = 10;
    uint256 public minAmountToSwapTaxes;
    uint256 launchedAt;
    uint256 buys;
    uint256 buysBeforeSells = 60;
    uint256 public constant SUPPLY = 1_000_000_000 * 10 ** 18;
    uint256 private constant DIVISOR = 100;
    uint256 private constant SWAP_DIVISOR = 10000;
    uint256 private constant MIN_AMOUNT_TO_SWAP_SUPPLY_PERCENTAGE = 5;
    uint256 private constant MAX_WALLET_AMOUNT_SUPPLY_PERCENTAGE = 2;

    bool public launchTax;
    bool public taxesEnabled = true;
    bool public limitsEnabled = true;
    bool inSwapAndLiq;
    bool public tradingAllowed;

    address taxWallet;
    address public immutable uniswapV2Pair;

    // Axelar
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 internal constant UINT256_MAX = type(uint256).max;
    uint256 public minters;

    mapping(address => bool) public _isExcludedFromFees;

    modifier lockTheSwap() {
        inSwapAndLiq = true;
        _;
        inSwapAndLiq = false;
    }

    event LaunchTaxRemoved(uint256 newBuyTaxPercent, uint256 newSellTaxPercent);
    event MaxWalletUpdated(uint256 newMaxWalletAmount);
    event MaxTxUpdated(uint256 newAmount);
    event MinAmountToSwapTaxes(uint256 newMinAmount);
    event TaxesEnabled(bool enabled);
    event LimitsEnabled(bool limitsEnabed);

    constructor()
        ERC20("MIRAI", "MIRAI")
        ERC20Permit("MIRAI")
        Ownable(msg.sender)
    {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        taxWallet = 0x7cAadAbfcDfA83dEED6Df926bcff4b2C088EFFE7;

        _isExcludedFromFees[msg.sender] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[address(_uniswapV2Pair)] = true;

        _mint(msg.sender, SUPPLY);

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        minAmountToSwapTaxes =
            (SUPPLY * MIN_AMOUNT_TO_SWAP_SUPPLY_PERCENTAGE) /
            SWAP_DIVISOR;
        maxWalletAmount =
            (SUPPLY * MAX_WALLET_AMOUNT_SUPPLY_PERCENTAGE) /
            DIVISOR;
        maxTxAmount = SUPPLY / DIVISOR;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(amount > 0, "ERC20: transfer must be greater than 0");

        address _owner = owner();
        if (!tradingAllowed) {
            require(from == _owner || to == _owner, "Trading not active yet");
        }

        uint256 taxAmount;

        if (launchTax) {
            setTax(block.number);
        }

        if (from == uniswapV2Pair && !_isExcludedFromFees[to]) {
            if (limitsEnabled) {
                require(amount <= maxTxAmount, "Max Tx in effect");
                require(
                    balanceOf(to) + amount <= maxWalletAmount,
                    "Max Wallet In Effect"
                );
            }

            if (taxesEnabled) {
                taxAmount = (amount * buyTax) / 100;
            }

            buys++;
        }

        if (to == uniswapV2Pair && !_isExcludedFromFees[from]) {
            if (limitsEnabled) {
                require(amount <= maxTxAmount, "Max Tx in effect");
            }

            if (taxesEnabled) {
                taxAmount = (amount * sellTax) / 100;
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool overMinTokenBalance = contractTokenBalance >= minAmountToSwapTaxes;

        if (
            from != address(0) &&
            overMinTokenBalance &&
            !inSwapAndLiq &&
            from != uniswapV2Pair &&
            !_isExcludedFromFees[from] &&
            buys > buysBeforeSells
        ) {
            swapAndSend(minAmountToSwapTaxes);
        }

        if (taxAmount > 0) {
            uint256 userAmount = amount - taxAmount;
            super._update(from, address(this), taxAmount);
            super._update(from, to, userAmount);
        } else {
            super._update(from, to, amount);
        }
    }

    function swapAndSend(uint256 _contractTokenBalance) internal lockTheSwap {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(
            address(this),
            address(uniswapV2Router),
            _contractTokenBalance
        );

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _contractTokenBalance,
            0,
            path,
            taxWallet,
            block.timestamp
        );
    }

    function setTax(uint256 _block) internal {
        uint256 newBuyTax;
        uint256 newSellTax;
        uint256 _launchedAt = launchedAt;

        if (_block <= _launchedAt + 3) {
            newBuyTax = 35;
            newSellTax = 35;
        } else if (_block <= _launchedAt + 5) {
            newBuyTax = 15;
            newSellTax = 15;
        } else if (_block <= _launchedAt + 9) {
            newBuyTax = 10;
            newSellTax = 10;
        } else {
            newBuyTax = 5;
            newSellTax = 5;
        }

        if (newBuyTax != buyTax) {
            buyTax = newBuyTax;
        }

        if (newSellTax != sellTax) {
            sellTax = newSellTax;
        }
    }

    function changetaxWallet(address _newtaxWallet) external onlyOwner {
        taxWallet = _newtaxWallet;
    }

    function removeLaunchTax(
        uint256 _newBuyTaxPercent,
        uint256 _newSellTaxPercent
    ) external onlyOwner {
        require(
            _newBuyTaxPercent <= MAX_BUY_TAX_PERCENTAGE &&
                _newSellTaxPercent <= MAX_SELL_TAX_PERCENTAGE,
            "Cannot set taxes above MAX_TAX_PERCENTAGE"
        );
        buyTax = _newBuyTaxPercent;
        sellTax = _newSellTaxPercent;
        launchTax = false;

        emit LaunchTaxRemoved(_newBuyTaxPercent, _newSellTaxPercent);
    }

    function excludeFromFees(
        address _address,
        bool _isExcluded
    ) external onlyOwner {
        _isExcludedFromFees[_address] = _isExcluded;
    }

    function updateMaxWalletAmount(
        uint256 _newMaxWalletAmount
    ) external onlyOwner {
        maxWalletAmount = _newMaxWalletAmount;

        emit MaxWalletUpdated(_newMaxWalletAmount);
    }

    function updateMaxTxAmount(uint256 _newAmount) external onlyOwner {
        maxTxAmount = _newAmount;

        emit MaxTxUpdated(_newAmount);
    }

    function changeMinAmountToSwapTaxes(
        uint256 _newMinAmount
    ) external onlyOwner {
        require(_newMinAmount > 0, "Cannot set to zero");
        minAmountToSwapTaxes = _newMinAmount;

        emit MinAmountToSwapTaxes(_newMinAmount);
    }

    function enableTaxes(bool _enable) external onlyOwner {
        taxesEnabled = _enable;

        emit TaxesEnabled(_enable);
    }

    function activate() external onlyOwner {
        require(!tradingAllowed, "Trading not paused");
        tradingAllowed = true;
        launchedAt = block.number;
        launchTax = true;
    }

    function toggleLimits(bool _limitsEnabed) external onlyOwner {
        limitsEnabled = _limitsEnabed;

        emit LimitsEnabled(_limitsEnabed);
    }

    function manualSwap(uint256 _amount) external onlyOwner {
        swapAndSend(_amount);
    }

    // Interchain Functions

    // Grant Minter Role
    // Can only be called ONCE to add Axelars Token Manager
    // After that no other addresses can be granted Role
    function grantRole(
        bytes32 role,
        address account
    ) public virtual override onlyRole(getRoleAdmin(role)) {
        if (minters >= 1) revert("Cannot add more than one Minter");
        minters++;
        _grantRole(role, account);
    }

    // Mint new tokens. Only address with the MINTER_ROLE can call this function
    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    // Burn tokens from a specified account
    function burn(
        address account,
        uint256 amount
    ) public onlyRole(MINTER_ROLE) {
        _burn(account, amount);
    }

    /**
     * @notice A method to be overwritten that will decrease the allowance of the `spender` from `sender` by `amount`.
     * @dev Needs to be overwritten. This provides flexibility for the choice of ERC20 implementation used. Must revert if allowance is not sufficient.
     */
    function _spendAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal override(ERC20) {
        uint256 _allowance = allowance(sender, spender);

        if (_allowance != UINT256_MAX) {
            _approve(sender, spender, _allowance - amount);
        }
    }
}
