// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "ERC20.sol";
import "Ownable.sol";
import "IUniswapV2Factory.sol";
import "IUniswapV2Router.sol";
import "console.sol";

contract NovaMind is ERC20, Ownable {
    // ====== MODIFICATORS ====== //

    // ====== EVENTS ====== //

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromMaxWallet(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair);
    event TaxReceiverUpdated(address indexed newWallet, address indexed oldWallet);

    // ====== STORAGE ====== //

    IUniswapV2Router02 public router;
    address public uniswapV2Pair;

    bool private swapping;
    uint256 public swapTokensAtAmount = 50_000 ether;

    address public taxReceiver;

    bool public tradingActive = false;
    mapping(address => bool) public isBlacklisted;
    mapping(address => uint256) public voidMindAt;

    uint32 public buyFees = 5;
    uint32 public sellFees = 20;
    uint64 public voidMindFees = 40;

    uint256 public endOfVoidMind;

    uint256 public maxWallet = 1_000_000 ether;

    mapping(address => bool) public isExcludedFromFees;
    mapping(address => bool) public isExcludedFromMaxWallet;
    address public lp;

    // ====== CONSTRUCTOR ====== //

    constructor(address _router, address _taxReceiver) ERC20("NOVAMIND_", "NMD") Ownable(msg.sender) {
        router = IUniswapV2Router02(_router);
        taxReceiver = _taxReceiver;

        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[taxReceiver] = true;

        isExcludedFromMaxWallet[address(this)] = true;
        isExcludedFromMaxWallet[msg.sender] = true;
        isExcludedFromMaxWallet[taxReceiver] = true;

        _mint(msg.sender, 100_000_000 ether);
    }

    // ====== VIEWS ====== //

    // ====== FUNCTIONS ====== //

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    // ====== OWNER ONLY ====== //

    function enableTrading() external payable onlyOwner {
        require(!tradingActive, "Trading already active.");

        endOfVoidMind = block.number + 24;

        lp = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        emit SetAutomatedMarketMakerPair(lp);
        isExcludedFromMaxWallet[lp] = true;

        _approve(address(this), address(router), type(uint256).max);

        router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            msg.sender,
            block.timestamp
        );

        tradingActive = true;
    }

    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        require(newAmount >= 500 ether, "NMD: Swap amount cannot be lower than 500.");
        require(newAmount <= 100000 ether, "NMD: Swap amount cannot be higher than 20000");

        swapTokensAtAmount = newAmount;
    }

    function updateFees(uint32 _buyFees, uint32 _sellFees) external onlyOwner {
        require(_buyFees <= 20, "NMD: Must keep fees at 20% or less");
        require(_sellFees <= 20, "NMD: Must keep fees at 20% or less");

        buyFees = _buyFees;
        sellFees = _sellFees;
    }

    function updateTaxReceivers(address _taxReceiver) external onlyOwner {
        require(_taxReceiver != address(0), "NMD: Address 0");

        if (taxReceiver != _taxReceiver) {
            address oldWallet = taxReceiver;
            taxReceiver = _taxReceiver;
            emit TaxReceiverUpdated(taxReceiver, oldWallet);
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner {
        isExcludedFromMaxWallet[account] = excluded;
        emit ExcludeFromMaxWallet(account, excluded);
    }

    function blacklist(address[] calldata accounts, bool value) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isBlacklisted[accounts[i]] = value;
        }
    }

    function adminWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No tokens");
        require(IERC20(token).transfer(msg.sender, balance));
    }

    // ====== PRIVATE ====== //

    function _update(address from, address to, uint256 amount) internal override {
        require(!isBlacklisted[from] && !isBlacklisted[msg.sender] && !isBlacklisted[tx.origin], "NMD: blacklisted");
        if (amount == 0) {
            super._update(from, to, 0);
            return;
        }

        if (to != address(0) && !swapping && !tradingActive) {
            require(isExcludedFromFees[from] || isExcludedFromFees[to], "NMD: Trading is not active.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (canSwap && !swapping && from != lp && !isExcludedFromFees[from] && !isExcludedFromFees[to]) {
            swapping = true;
            sellCollectedFees();
            swapping = false;
        }

        bool takeFee = !swapping;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 feesAmount = 0;

        if (takeFee) {
            if (lp == from) {
                // on buy
                feesAmount = (amount * buyFees) / 100;

                if (block.number <= endOfVoidMind) {
                    feesAmount = ((amount * voidMindFees) / 2) / 100;
                    voidMindAt[to] = block.number;
                }
            } else if (lp == to) {
                // on sell
                if (voidMindAt[from] > 0 && voidMindAt[from] < block.number) {
                    feesAmount = (amount * voidMindFees) / 100;
                } else {
                    feesAmount = (amount * sellFees) / 100;
                }
            } else {
                // regular transfer
                if (voidMindAt[from] > 0) {
                    voidMindAt[to] = block.number;

                    if (voidMindAt[from] < block.number) {
                        feesAmount = (amount * voidMindFees) / 100;
                    }
                }
            }

            if (feesAmount > 0) {
                super._update(from, address(this), feesAmount);
            }

            amount -= feesAmount;
        }

        if (!isExcludedFromMaxWallet[to]) {
            require(amount + balanceOf(to) <= maxWallet, "NMD: Max wallet exceeded");
        }

        super._update(from, to, amount);
    }

    function sellCollectedFees() private {
        uint256 tokensBalance = balanceOf(address(this));

        if (tokensBalance == 0) {
            return;
        }

        if (tokensBalance > swapTokensAtAmount * 20) {
            tokensBalance = swapTokensAtAmount * 20;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokensBalance, 0, path, taxReceiver, block.timestamp);
    }
}
