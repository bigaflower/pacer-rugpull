// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

/**
 * @title FixMe AI Token Contract
 * @dev A comprehensive ERC20 token with dynamic taxation, automated marketing,
 *      and liquidity management features.
 * @notice This contract implements advanced tokenomics for the FixMe AI ecosystem
 */

/*

.-----------------------------------------------.
| .-.-. .-.-. .-.-. .-.-. .-.-.      .-.-. .-.-.|
|( F .'( i .'( x .'( M .'( e .'.-.-.( A .'( I .'|
| `.(   `.(   `.(   `.(   `.(  '._.' `.(   `.(  |
'-----------------------------------------------'

*/
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface Token {
    function manualSwap(uint256 percent) external;
    function claimOtherERC20(address token, uint256 amount) external;
}

/// subcontract for spliting marketing eth to 3 wallets
/// as per there share
contract MarketingEthHandler is Ownable2Step {
    //// set your fee wallet address here
    address public feeWallet1 = address(0xbC164bCcb5E56e4F7702Fe88573F0214266cE3aA);
    address public feeWallet2 = address(0x17BeA72A6297F5Ab64f8D67D182C09A06d82b8dE);
    address public feeWallet3 = address(0x0F31B5ED38B39b435128AdC6B173f0939116859e);

    uint256 public feeWallet1Share;
    uint256 public feeWallet2Share;
    uint256 public feeWallet3Share;
    Token public fix;
    uint256 public totalShares;

    bool autoForwardEnabled = true;

    error EthTransferFailed();

    constructor(address owner, address token) Ownable(owner) {
        fix = Token(token);

        feeWallet1Share = 34;
        feeWallet2Share = 33;
        feeWallet3Share = 33;
        totalShares = feeWallet1Share + feeWallet2Share + feeWallet3Share;
    }

    receive() external payable {
        if (autoForwardEnabled) {
            bool sent;
            uint256 totalEth = msg.value;
            uint256 w1 = (totalEth * feeWallet1Share) / totalShares;
            uint256 w2 = (totalEth * feeWallet2Share) / totalShares;
            uint256 w3 = totalEth - w1 - w2;
            if (w1 > 0) {
                (sent, ) = feeWallet1.call{value: w1}("");
            }
            if (w2 > 0) {
                (sent, ) = feeWallet2.call{value: w2}("");
            }
            if (w3 > 0) (sent, ) = feeWallet3.call{value: w3}("");
        }
    }

    /// @dev update fee wallets
    /// @param _w1 new fee wallet1
    /// @param _w2 new fee wallet2
    /// @param _w3 new fee wallet3
    function setFeeWallets(
        address _w1,
        address _w2,
        address _w3
    ) external onlyOwner {
        feeWallet1 = _w1;
        feeWallet2 = _w2;
        feeWallet3 = _w3;
    }

    /// @dev wallets shares
    /// @param _w1Share: first wallet share
    /// @param _w2Share: second wallet share
    /// @param _w3Share: third wallet share
    function setWalletShares(
        uint256 _w1Share,
        uint256 _w2Share,
        uint256 _w3Share
    ) external onlyOwner {
        feeWallet1Share = _w1Share;
        feeWallet2Share = _w2Share;
        feeWallet3Share = _w3Share;
        totalShares = _w1Share + _w2Share + _w3Share;
    }

    /// toggle b/w auto forward  and manual mode
    function toggleAutoForward() external onlyOwner {
        autoForwardEnabled = !autoForwardEnabled;
    }

    /// claim eth manually
    function claimETH() external onlyOwner {
        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, EthTransferFailed());
    }

    /// call manual swap on token
    function manualSwap(uint256 percent) external onlyOwner {
        fix.manualSwap(percent);
    }

    // function any stuck erc20 on token
    function claimERC20FromTokenContract(
        address token,
        uint256 amount
    ) external onlyOwner {
        fix.claimOtherERC20(token, amount);
    }

    /// claim any erc20 token
    function claimAnyERC20(address _token, uint256 _amount) external onlyOwner {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }
}

/// FixMe AI is an ERC20 token
contract FixMeAI is ERC20, Ownable2Step {
    /// custom errors
    error CannotRemoveMainPair();
    error ZeroAddressNotAllowed();
    error FeesLimitExceeds();
    error CannotBlacklistLPPair();
    error UpdateBoolValue();
    error CannotClaimNativeToken();
    error AmountTooLow();
    error OnlyOwnerOrMarketingWallet();
    error BlacklistedUser();

    /// @notice Max limit on Buy / Sell fees
    uint256 public constant MAX_FEE_LIMIT = 10;
    /// @notice max total supply 50 million tokens (18 decimals)
    uint256 private maxSupply = 50_000_000 * 1e18;
    /// @notice swap threshold at which collected fees tokens are swapped for ether, autoLP
    uint256 public swapTokensAtAmount = 5_000 * 1e18;
    /// @notice check if it's a swap tx
    bool private inSwap = false;

    /// @notice struct buy fees variable
    /// marketing: marketing fees
    /// autoLP: liquidity fees
    struct BuyFees {
        uint16 marketing;
        uint16 autoLP;
    }
    /// @notice struct sell fees variable
    /// marketing: marketing fees
    /// autoLP: liquidity fees
    struct SellFees {
        uint16 marketing;
        uint16 autoLP;
    }

    /// @notice struct sell fees variable
    /// marketing: marketing fees
    /// autoLP: liquidity fees
    struct TransferFees {
        uint16 marketing;
        uint16 autoLP;
    }

    /// @notice buyFees variable
    BuyFees public buyFee;
    /// @notice sellFees variable
    SellFees public sellFee;
    /// @notice transferFees variable
    TransferFees public transferFee;

    ///@notice number of buys
    uint256 buyCount;
    ///@notice number of sells
    uint256 sellCount;
    //@notice number of transfer
    uint256 transferCount;

    /// @notice totalBuyFees
    uint256 private totalBuyFee;
    /// @notice totalSellFees
    uint256 private totalSellFee;
    /// @notice total transfer fee
    uint256 private totalTransferFee;
    /// @notice tax mode
    bool private normalMode;

    /// @notice marketingWallet
    address public marketingWallet;
    /// @notice uniswap V2 router address
    IUniswapV2Router02 public immutable uniswapV2Router;
    /// @notice uniswap V2 Pair address
    address public uniswapV2Pair;

    /// @notice mapping to manager liquidity pairs
    mapping(address => bool) public isAutomatedMarketMaker;
    /// @notice mapping to manage excluded address from/to fees
    mapping(address => bool) public isExcludedFromFees;
    /// @notice mapping to manage blacklist
    mapping(address => bool) public isBlacklisted;

    //// EVENTS ////
    event BuyFeesUpdated(
        uint16 indexed marketingFee,
        uint16 indexed liquidityFee
    );
    event SellFeesUpdated(
        uint16 indexed marketingFee,
        uint16 indexed liquidityFee
    );
    event FeesSwapped(
        uint256 indexed ethForLiquidity,
        uint256 indexed tokensForLiquidity,
        uint256 indexed ethForMarketing
    );

    /// @dev create an erc20 token using openzeppeling ERC20, Ownable2Step
    /// uses uniswap router and factory interface
    /// set uniswap router, create pair, initialize buy, sell fees, marketingWallet values
    /// excludes the token, marketingWallet and owner address from fees
    /// and mint all the supply to owner wallet.
    constructor() ERC20("FixMe AI", "FIX") Ownable(msg.sender) {
        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        isAutomatedMarketMaker[uniswapV2Pair] = true;

        /// normal trade values after antisnipe period
        buyFee.marketing = 5;
        buyFee.autoLP = 0;
        totalBuyFee = 5;

        sellFee.marketing = 5;
        sellFee.autoLP = 0;
        totalSellFee = 5;
        MarketingEthHandler m = new MarketingEthHandler(
            /// paste owner address to control marketing eth handler contract
            address(0xB37EF2036be73cf62AD413C62E01BF6FbFeb5e52), 
            msg.sender
        );

        marketingWallet = address(m);

        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[marketingWallet] = true;
        isExcludedFromFees[owner()] = true;
        _mint(msg.sender, maxSupply);
    }

    /// modifier  ///
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    /// receive external ether
    receive() external payable {}

    /// @dev owner can claim other erc20 tokens, if accidently sent by someone
    /// @param _token: token address to be rescued
    /// @param _amount: amount to rescued
    /// Requirements --
    /// Cannot claim native token
    function claimOtherERC20(address _token, uint256 _amount) external {
        if (msg.sender != marketingWallet && msg.sender != owner()) {
            revert OnlyOwnerOrMarketingWallet();
        }
        if (_token == address(this)) {
            revert CannotClaimNativeToken();
        }
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(
            abi.encodeWithSelector(0xa9059cbb, msg.sender, _amount)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    /// @dev exclude or include a user from/to fees
    /// @param user: user address
    /// @param value: boolean value. true means excluded. false means included
    /// Requirements --
    /// zero address not allowed
    /// if a user is excluded already, can't exlude him again
    function excludeFromFees(address user, bool value) external onlyOwner {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (isExcludedFromFees[user] == value) {
            revert UpdateBoolValue();
        }
        isExcludedFromFees[user] = value;
    }

    /// @dev exclude or include a user from/to blacklist
    /// @param user: user address
    /// @param value: boolean value. true means blacklisted. false means unblacklisted
    /// Requirements --
    /// zero address not allowed
    /// if a user is blacklisted already, can't blacklist him again
    function blacklist(address user, bool value) external onlyOwner {
        if (user == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (isBlacklisted[user] == value) {
            revert UpdateBoolValue();
        }
        isBlacklisted[user] = value;
    }

    /// @dev add or remove new pairs
    /// @param _newPair: address to be added or removed as pair
    /// @param value: boolean value, true means pair is added, false means pair is removed
    /// Requirements --
    /// address should not be zero
    /// Can not remove main pair
    /// can not add already added pairs  and vice versa
    function manageLiquidityPairs(
        address _newPair,
        bool value
    ) external onlyOwner {
        if (_newPair == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        if (_newPair == uniswapV2Pair) {
            revert CannotRemoveMainPair();
        }
        if (isAutomatedMarketMaker[_newPair] == value) {
            revert UpdateBoolValue();
        }
        isAutomatedMarketMaker[_newPair] = value;
    }

    /// update marketing wallet address
    function updateMarketingWallet(
        address _newMarketingWallet
    ) external onlyOwner {
        if (_newMarketingWallet == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        marketingWallet = _newMarketingWallet;
    }

    /// @dev update swap tokens at amount threshold
    /// @param amount: new threshold amount
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        swapTokensAtAmount = amount * 1e18;
    }

    /// @dev update buy fees
    /// @param _marketing: marketing fees
    /// @param _autoLP: liquidity fees
    /// Requirements --
    /// total Buy fees must be less than equals to MAX_FEE_LIMIT (10%);
    function updateBuyFees(
        uint16 _marketing,
        uint16 _autoLP
    ) external onlyOwner {
        if (_marketing + _autoLP > MAX_FEE_LIMIT) {
            revert FeesLimitExceeds();
        }
        buyFee.marketing = _marketing;
        buyFee.autoLP = _autoLP;
        totalBuyFee = _marketing + _autoLP;
        emit BuyFeesUpdated(_marketing, _autoLP);
    }

    /// @dev update sell fees
    /// @param _marketing: marketing fees
    /// @param _autoLP: liquidity fees
    /// Requirements --
    /// total Sell fees must be less than equals to MAX_FEE_LIMIT (10%);
    function updateSellFees(
        uint16 _marketing,
        uint16 _autoLP
    ) external onlyOwner {
        if (_marketing + _autoLP > MAX_FEE_LIMIT) {
            revert FeesLimitExceeds();
        }
        sellFee.marketing = _marketing;
        sellFee.autoLP = _autoLP;
        totalSellFee = _marketing + _autoLP;
        emit SellFeesUpdated(_marketing, _autoLP);
    }

    /// @dev switch to normal tax instantly
    function switchToNormalTax() external onlyOwner {
        normalMode = true;
    }

    /// @notice manage transfers, fees
    /// see {ERC20 - _update}
    /// requirements --
    /// from or to should not be zero
    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (isBlacklisted[from] || isBlacklisted[to]) {
            revert BlacklistedUser();
        }

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }
        uint256 contractBalance = balanceOf(address(this));
        bool canSwapped = contractBalance >= swapTokensAtAmount;
        if (
            canSwapped &&
            !isAutomatedMarketMaker[from] &&
            !inSwap &&
            !isExcludedFromFees[from] &&
            !isExcludedFromFees[to]
        ) {
            swapAndLiquify(contractBalance);
        }

        bool takeFee = true;
        if (isExcludedFromFees[from] || isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;
        /// intital buy fee
        /// get buy tax based on buy txn count,
        /// only for first 16 transfers (i.e wallet to wallet)
        uint256 ibFee = calculateBuyTax();
        /// initial sell fee
        /// get sell  tax based on sell txn count,
        /// only for first 14 transfers (i.e uniswapv2pool to user)
        uint256 isFee = calculateSellTax();
        /// intial transfer fee
        /// get transfer  tax based on transfer txn count,
        /// only for first 30 transfers (i.e wallet to wallet)
        uint256 itFee = calculateTransferTax();

        if (takeFee) {
            if (isAutomatedMarketMaker[from] && totalBuyFee > 0) {
                if (buyCount <= 16 && !normalMode) {
                    buyCount = buyCount + 1;
                    fees = (amount * ibFee) / 100;
                } else {
                    fees = (amount * totalBuyFee) / 100;
                }
            } else if (isAutomatedMarketMaker[to] && totalSellFee > 0) {
                if (sellCount <= 14 && !normalMode) {
                    sellCount = sellCount + 1;
                    fees = (amount * isFee) / 100;
                } else {
                    fees = (amount * totalSellFee) / 100;
                }
            } else {
                if (transferCount <= 30 && !normalMode) {
                    transferCount = transferCount + 1;
                    fees = (amount * itFee) / 100;
                }
            }
            if (fees > 0) {
                super._update(from, address(this), fees);
                amount = amount - fees;
            }
        }
        super._update(from, to, amount);
    }

    /// @notice swap the collected fees to eth / add liquidity
    /// after conversion, it sends eth to marketing wallet, add auto liquidity
    /// @param tokenAmount: tokens to be swapped appropriately as per fee structure
    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        if (totalBuyFee + totalSellFee == 0) {
            swapTokensForEth(tokenAmount);
            bool m;
            (m, ) = payable(marketingWallet).call{value: address(this).balance}(
                ""
            );
        } else {
            uint256 marketingTokens = ((buyFee.marketing + sellFee.marketing) *
                tokenAmount) / (totalBuyFee + totalSellFee);
            uint256 liquidityTokens = tokenAmount - marketingTokens;
            uint256 liquidityTokensHalf = liquidityTokens / 2;
            uint256 swapTokens = tokenAmount - liquidityTokensHalf;
            uint256 ethBalanceBeforeSwap = address(this).balance;
            swapTokensForEth(swapTokens);

            uint256 ethBalanceAfterSwap = address(this).balance -
                ethBalanceBeforeSwap;
            uint256 ethForLiquidity = (liquidityTokensHalf *
                ethBalanceAfterSwap) / swapTokens;
            if (ethForLiquidity > 0 && liquidityTokensHalf > 0) {
                addLiquidity(liquidityTokensHalf, ethForLiquidity);
            }
            bool success;
            uint256 marketingEth = address(this).balance;
            if (marketingEth > 0) {
                (success, ) = payable(marketingWallet).call{
                    value: marketingEth
                }("");
            }

            emit FeesSwapped(
                ethForLiquidity,
                liquidityTokensHalf,
                marketingEth
            );
        }
    }

    /// @notice manages tokens conversion to eth
    /// @param tokenAmount: tokens to be converted to eth
    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        if (allowance(address(this), address(uniswapV2Router)) < tokenAmount) {
            _approve(
                address(this),
                address(uniswapV2Router),
                type(uint256).max
            );
        }

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    /// @notice manage autoLP (liquidity addition)
    /// @param tokenAmount: tokens to be added to liquidity
    /// @param ethAmount: eth to be added to liquidity
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(), // LP tokens recevier
            block.timestamp
        );
    }

    /// @notice convert all or some percentage of collected tax to eth
    /// @param percentage: percentage of collected tax to swap
    function manualSwap(uint256 percentage) external lockTheSwap {
        if (msg.sender != marketingWallet && msg.sender != owner()) {
            revert OnlyOwnerOrMarketingWallet();
        }
        uint256 tokens = balanceOf(address(this));
        uint256 amount = (tokens * percentage) / 100;
        swapTokensForEth(amount);
        uint256 ethAmount = address(this).balance;
        bool success;
        (success, ) = payable(marketingWallet).call{value: ethAmount}("");
    }

    /// internal functions
    // Function to calculate buy tax based on transaction count
    function calculateBuyTax() internal view returns (uint256) {
        if (buyCount <= 5) {
            return 25;
        } else if (buyCount <= 10) {
            return 20;
        } else if (buyCount <= 13) {
            return 15;
        } else if (buyCount <= 16) {
            return 10;
        } else {
            return totalBuyFee;
        }
    }

    // Function to calculate sell tax based on transaction count
    function calculateSellTax() internal view returns (uint256) {
        if (sellCount <= 5) {
            return 25;
        } else if (sellCount <= 10) {
            return 20;
        } else if (sellCount <= 12) {
            return 15;
        } else if (sellCount <= 14) {
            return 10;
        } else {
            return totalSellFee;
        }
    }

    // Function to calculate transfer tax based on transaction count
    function calculateTransferTax() internal view returns (uint256) {
        if (transferCount <= 10) {
            return 15;
        } else if (transferCount <= 30) {
            // 10 + 20 transactions
            return 10;
        } else {
            return 0;
        }
    }
}

/*
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║                    FIXME AI - SMART CONTRACT SUITE                           ║
║                                                                              ║
║  This contract was developed by AstraLabs Inc. as part of a comprehensive    ║
║  investment agreement through AstraX Capital.                                ║
║                                                                              ║
║  Contract Features:                                                          ║
║  • Dynamic Tax System with Transaction-Based Adjustments                     ║
║  • Automated Marketing Fee Distribution                                      ║
║  • Liquidity Management with Anti-Dump Protection                            ║
║  • Multi-Wallet Fee Handling System                                          ║
║                                                                              ║
║  Security: Audited and tested for production deployment                      ║
║  Version: 1.0.0                                                              ║
║  License: MIT                                                                ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
*/