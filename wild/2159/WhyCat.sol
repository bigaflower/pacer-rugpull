/*
    Website: https://whycat.meme
    TG: https://t.me/WhyCatMeme
    X: https://x.com/WhyCatMeme
*/
// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts@4.9.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.9.0/access/Ownable.sol";

contract WhyCat is ERC20, Ownable {
    /* Structs */
    struct Tax {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
    }

    /* Mappings */
    mapping(address => bool) private _isExcludedFromFees;

    /* Public Variables */
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapV2Pair;
    Tax public tax;
    bool public tradingEnabled;

    /* Private Variables */
    bool private _inSwap;
    address private _marketingWallet;

    /* Constants */
    uint64 public constant FEE_DIVISOR = 10000;

    /* Events */
    event ExcludeFromFees(address account, bool excluded);
    event UpdateTax(Tax tax);
    event SwapFeesAndDistribute(
        uint256 tokensSwapped,
        uint256 ethRecieved
    );
    event TradingEnabled();
    event UpdateMarketingWallet(address marketingWallet);

    /* Modifiers */
    modifier lockSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    /* Constructor */
    constructor(address marketingWallet) ERC20("WhyCat", "WhyCat") {
        address routerAddress;
        if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
        } else if (block.chainid == 1 || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet & Testnet
        } else {
            revert();
        }

        uniswapV2Router = IUniswapV2Router02(routerAddress);
        uniswapV2Pair = IUniswapV2Pair(
            IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            )
        );

        _marketingWallet = marketingWallet;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(0xdead)] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[marketingWallet] = true;

        tax.buy = 200;
        tax.sell = 200;
        tax.transfer = 200;

        _mint(owner(), 100_000_000_000 * (10 ** decimals()));
    }

    /* Callbacks */
    receive() external payable {}

    /* Public Functions */
    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    /* Overrides */
    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(
            tradingEnabled ||
                isExcludedFromFees(from) ||
                isExcludedFromFees(to),
            "Trading not yet enabled"
        );

        if (amount == 0) {
            super._transfer(from, to, amount);
            return;
        }

        if (
            !_inSwap &&
            address(uniswapV2Pair) == to &&
            tradingEnabled &&
            balanceOf(address(this)) >= totalSupply() / 5_000 &&
            !isExcludedFromFees(from)
        ) {
            _swapFees();
        }

        if (!(isExcludedFromFees(from) || isExcludedFromFees(to) || _inSwap)) {
            uint256 fee = 0;

            if (address(uniswapV2Pair) == from) {
                fee = (amount * tax.buy) / FEE_DIVISOR;
            } else if (address(uniswapV2Pair) == to) {
                fee = (amount * tax.sell) / FEE_DIVISOR;
            } else {
                fee = (amount * tax.transfer) / FEE_DIVISOR;
            }

            if (fee > 0) {
                amount -= fee;
                super._transfer(from, address(this), fee);
            }
        }

        super._transfer(from, to, amount);
    }

    /* Owner Functions */
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(
            isExcludedFromFees(account) != excluded,
            "Account is already the value of 'excluded'"
        );

        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function bulkExcludeFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        require(accounts.length > 0, "No accounts provided");

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            if (_isExcludedFromFees[account] != excluded) {
                _isExcludedFromFees[account] = excluded;
                emit ExcludeFromFees(account, excluded);
            }
        }
    }

    function updateTax(
        uint256 buy,
        uint256 sell,
        uint256 transfer
    ) external onlyOwner {
        require(buy + sell <= FEE_DIVISOR * 10 / 100, "Total buy + sell tax should be <= than 10%");
        require(transfer <= FEE_DIVISOR * 5 / 100, "Transfer tax should be <= than 5%");

        tax.buy = buy;
        tax.sell = sell;
        tax.transfer = transfer;

        emit UpdateTax(tax);
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled");

        tradingEnabled = true;

        emit TradingEnabled();
    }

    function updateMarketingWallet(
        address marketingWallet
    ) external onlyOwner {
        require(
            marketingWallet != _marketingWallet,
            "Marketing wallet is already that address"
        );
        require(
            marketingWallet != address(0),
            "Marketing wallet cannot be the zero address"
        );

        _marketingWallet = marketingWallet;

        emit UpdateMarketingWallet(marketingWallet);
    }

    /* Private Functions */
    function _swapFees() private lockSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        uint256 tokensToSwap = balanceOf(address(this));

        _approve(address(this), address(uniswapV2Router), tokensToSwap);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokensToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 ethRecieved = address(this).balance;
        
        payable(_marketingWallet).call{value: ethRecieved}("");

        emit SwapFeesAndDistribute(
            tokensToSwap,
            ethRecieved
        );
    }
}
