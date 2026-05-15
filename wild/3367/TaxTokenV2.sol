// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {
    ERC20Upgradeable
} from "@openzeppelin-contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {
    Initializable
} from "@openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import {ISpawnTaxTokenV2} from "src/interfaces/Tax/ISpawnTaxTokenV2.sol";
import {LibPoolAddress} from "src/libraries/PoolAddress.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin-contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {
    OwnableUpgradeable
} from "@openzeppelin-contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITaxProcessor} from "src/interfaces/Tax/ITaxProcessor.sol";
import {
    IERC20Permit
} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract SpawnTaxTokenV2 is
    Initializable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable,
    ISpawnTaxTokenV2
{
    using SafeERC20 for IERC20;

    /// @notice The minimum liquidation threshold
    uint256 public constant MIN_LIQ_THRESHOLD = 50_000 ether;
    /// @notice The starting liquidation threshold
    uint256 public constant START_LIQ_THRESHOLD = 400_000 ether;
    /// @notice The maximum supply of the token
    /// @dev make it compatible with the previous version
    uint256 public constant maxSupply = 1e9 ether; // 1 billion tokens

    /// @notice The address of the Uniswap/PancakeSwap V2 router contract
    address public v2Router;
    /// @notice The quote token used for pools (can be WETH or any ERC20)
    address public quoteToken;
    /// @notice The expected output amount in each liquidation
    /// @dev i.e, the expected output quoteToken amount in each liquidation
    uint256 public liqExpectedOutputAmount;
    /// @notice The duration of the anti-farmer tax in seconds
    uint256 public antiFarmerDuration;

    /// @notice The address of the V2 pool
    address public mainPool;
    /// @notice The address responsible for processing collected tax (optional handler)
    address public taxProcessor;

    /// @notice Enum to represent the state of the pool
    enum PoolState {
        BondingCurve, // state0: Token is trading on the bonding curve, no tax, no transfers to pools
        Migrating, // state1: Token is in the process of migration
        TaxEnforcedAntiFarmer, // state2: Token listed on DEX, tax applied for transfers involving any pool
        TaxEnforced, // state3: Token listed on DEX, tax applied for transfers involving mainPool
        TaxFree // state4: Token is free of tax
    }

    /// @notice Gas-optimized struct containing all pool-related state variables
    /// @dev Packed into a single 256-bit storage slot for gas efficiency
    /// Field breakdown:
    ///   - state: 8 bits (PoolState enum)
    ///   - taxRate: 16 bits (basis points, max 65535)
    ///   - notLiquidating: 8 bits (boolean, padded to 8 bits for alignment)
    ///   - liquidationThreshold: 96 bits (supports up to ~79B tokens with 18 decimals)
    ///   - taxExpirationTime: 64 bits (timestamp, valid until year 2554)
    ///   - antiFarmerExpirationTime: 64 bits (timestamp, valid until year 2554)
    /// Total: 8 + 16 + 8 + 96 + 64 + 64 = 256 bits (exactly one storage slot)
    ///
    /// @custom:security-note CRITICAL: If the total supply limit of the token is changed
    /// to more than 1 billion ether (10^27 wei), the liquidationThreshold field type
    /// (uint96) must be revisited to ensure it can accommodate the new supply limit
    /// without causing overflow issues. Current uint96 max value: ~79,228,162,514 ether.
    struct PackedPoolState {
        uint8 state; // Current state of the pool (PoolState enum)
        uint16 taxRate; // The tax rate for the token in basis points
        bool notLiquidating; // Indicates whether contract is not in middle of tax liquidation
        uint96 liquidationThreshold; // The threshold of tokens for liquidity
        uint64 taxExpirationTime; // Timestamp when the tax expires
        uint64 antiFarmerExpirationTime; // Timestamp when the anti-farmer tax expires
    }

    /// @notice All pool-related state variables packed into a single storage slot
    PackedPoolState public poolState;

    /// @notice Include all the pools related to this token
    /// Of course, this does not include all the pools, we only put some most
    /// used pools here.
    mapping(address => bool) public pools;

    /// @notice Addresses exempt from tax (e.g., Portal contract)
    mapping(address => bool) public taxExempt;

    /// @notice The metadata URI of the token
    string public override metaURI;

    /// @notice Parameterless constructor for upgradeable pattern
    constructor() {
        _disableInitializers();
    }
    // https://spawn.meme Tax Token V2
    /// @notice Initializes the token with the given parameters
    /// @param params The initialization parameters
    function initialize(
        InitParams memory params
    ) external override initializer {
        // Initialize router and configuration values that were previously immutable
        v2Router = params.v2Router;
        antiFarmerDuration = params.antiFarmerDuration;

        // Validate that tax duration is at least as long as anti-farmer duration
        require(
            params.taxDuration >= antiFarmerDuration,
            "Tax duration must be >= anti-farmer duration"
        );

        __ERC20_init(params.name, params.symbol);
        __ERC20Permit_init(params.name);
        __Ownable_init(msg.sender);

        metaURI = params.meta;
        // taxProcessor is provided via InitParams and must be set
        require(params.taxProcessor != address(0), "taxProcessor required");
        taxProcessor = params.taxProcessor;

        // Initialize poolState in memory first, then write to storage once
        PackedPoolState memory newPoolState = PackedPoolState({
            state: uint8(PoolState.BondingCurve), // default initial state
            taxRate: params.tax,
            notLiquidating: true,
            liquidationThreshold: uint96(START_LIQ_THRESHOLD),
            taxExpirationTime: uint64(params.taxDuration), // stores duration initially
            antiFarmerExpirationTime: 0 // will be set in finalizeMigration
        });
        poolState = newPoolState;

        // mint 1B to the msg.sender
        _mint(msg.sender, maxSupply);

        // Set quoteToken
        quoteToken = params.quoteToken;

        // Set liqExpectedOutputAmount from params
        liqExpectedOutputAmount = params.liqExpectedOutputAmount;

        // Set mainPool from the first pool in the array
        require(params.pools.length > 0, "At least one pool address required");
        mainPool = params.pools[0];

        // Add all pool addresses to the mapping
        for (uint256 i = 0; i < params.pools.length; i++) {
            pools[params.pools[i]] = true;
        }
    }

    /// @notice Starts the migration process by transitioning the state of the pool
    function startMigration() external override onlyOwner {
        PackedPoolState memory currentPoolState = poolState;
        if (PoolState(currentPoolState.state) == PoolState.BondingCurve) {
            currentPoolState.state = uint8(PoolState.Migrating);
            poolState = currentPoolState;
            emit PoolStateChanged(
                uint8(PoolState.BondingCurve),
                currentPoolState.state
            );
        }
    }

    /// @notice Set tax exemption for an address (e.g., Portal contract)
    /// @param account Address to set exemption for
    /// @param exempt Whether the address is exempt from tax
    function setTaxExempt(address account, bool exempt) external onlyOwner {
        taxExempt[account] = exempt;
        emit TaxExemptSet(account, exempt);
    }

    /// @notice Event emitted when tax exemption is set
    event TaxExemptSet(address indexed account, bool exempt);

    /// @notice Finalizes the migration by transitioning the state of the pool
    function finalizeMigration() external override onlyOwner {
        PackedPoolState memory currentPoolState = poolState;
        if (PoolState(currentPoolState.state) == PoolState.Migrating) {
            currentPoolState.state = uint8(PoolState.TaxEnforcedAntiFarmer);
            currentPoolState.taxExpirationTime = uint64(
                currentPoolState.taxExpirationTime + block.timestamp
            );
            currentPoolState.antiFarmerExpirationTime = uint64(
                block.timestamp + antiFarmerDuration
            );
            poolState = currentPoolState;
            emit PoolStateChanged(
                uint8(PoolState.Migrating),
                currentPoolState.state
            );
        }
    }

    /// @notice Internal function to perform a plain (no tax) transfer
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    function _plainTransfer(address from, address to, uint256 amount) internal {
        // In OZ v5, _update is the hook that actually moves tokens
        _update(from, to, amount);
    }

    /// @notice Internal function to calculate the tax amount
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    /// @return The tax amount
    function _getTax(
        address from,
        address to,
        uint256 amount
    ) internal view returns (uint256) {
        // Check if either party is tax exempt (e.g., Portal)
        if (taxExempt[from] || taxExempt[to]) {
            return 0;
        }

        PackedPoolState memory currentPoolState = poolState;
        if (currentPoolState.notLiquidating) {
            if (
                PoolState(currentPoolState.state) ==
                PoolState.TaxEnforcedAntiFarmer
            ) {
                // Apply tax if transfer involves any pool
                if (pools[from] || pools[to]) {
                    return (amount * currentPoolState.taxRate) / 10000;
                }
            } else if (
                PoolState(currentPoolState.state) == PoolState.TaxEnforced
            ) {
                // Apply tax only if transfer involves v2Pool
                if (from == mainPool || to == mainPool) {
                    return (amount * currentPoolState.taxRate) / 10000;
                }
            }
        }
        return 0;
    }

    /// @notice Internal function to calculate the tax amount using provided poolState
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    /// @param currentPoolState The current pool state in memory
    /// @return The tax amount
    function _getTaxWithPoolState(
        address from,
        address to,
        uint256 amount,
        PackedPoolState memory currentPoolState
    ) internal view returns (uint256) {
        // Check if either party is tax exempt (e.g., Portal)
        if (taxExempt[from] || taxExempt[to]) {
            return 0;
        }

        if (currentPoolState.notLiquidating) {
            if (
                PoolState(currentPoolState.state) ==
                PoolState.TaxEnforcedAntiFarmer
            ) {
                // Apply tax if transfer involves any pool
                if (pools[from] || pools[to]) {
                    return (amount * currentPoolState.taxRate) / 10000;
                }
            } else if (
                PoolState(currentPoolState.state) == PoolState.TaxEnforced
            ) {
                // Apply tax only if transfer involves v2Pool
                if (from == mainPool || to == mainPool) {
                    return (amount * currentPoolState.taxRate) / 10000;
                }
            }
        }
        return 0;
    }

    /// @notice Internal function to perform a taxed transfer
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    /// @param tax The tax amount for the transfer
    function _taxedTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 tax
    ) internal {
        uint256 remainingAmount = amount - tax;

        _plainTransfer(from, address(this), tax);
        _plainTransfer(from, to, remainingAmount);
    }

    /// @notice Internal function to handle tax and liquidation logic
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param amount The amount of tokens to transfer
    function _customTransfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        _liquidateTax(to);

        // load poolState after liquidation
        PackedPoolState memory currentPoolState = poolState;

        PoolState currentState = PoolState(currentPoolState.state);
        if (currentState == PoolState.BondingCurve) {
            require(
                !pools[from] && !pools[to],
                "Transfers to/from pools are restricted in BondingCurve state"
            );
            _plainTransfer(from, to, amount);
        } else if (currentState == PoolState.Migrating) {
            _plainTransfer(from, to, amount);
        } else if (
            currentState == PoolState.TaxEnforcedAntiFarmer ||
            currentState == PoolState.TaxEnforced
        ) {
            uint256 tax = _getTaxWithPoolState(
                from,
                to,
                amount,
                currentPoolState
            );
            if (tax > 0) {
                _taxedTransfer(from, to, amount, tax);
            } else {
                _plainTransfer(from, to, amount);
            }
        } else {
            // TaxFree state
            _plainTransfer(from, to, amount);
        }
    }

    /// @notice Override transfer to include tax logic (OZ v5 compatible)
    /// @param to The address receiving the tokens
    /// @param value The amount of tokens to transfer
    /// @return True if the transfer was successful
    function transfer(
        address to,
        uint256 value
    ) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        address owner = _msgSender();
        _customTransfer(owner, to, value);
        return true;
    }

    /// @notice Override transferFrom to include tax logic (OZ v5 compatible)
    /// @param from The address sending the tokens
    /// @param to The address receiving the tokens
    /// @param value The amount of tokens to transfer
    /// @return True if the transfer was successful
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override(ERC20Upgradeable, IERC20) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _customTransfer(from, to, value);
        return true;
    }

    /// @notice Internal function to liquidate the accrued tax amount
    /// @param to the recipient of the current transfer call
    function _liquidateTax(address to) internal {
        // Note: from == mainPool does not work and leads to a DOS vector.
        // Uniswap v2 pair has a lock, if the user swaps WETH for the token, the pair first locks the pair and then
        // transfers the token to the user (i.e from == mainPool).  We could not liquidate in that "transfer" as the pair is already locked.
        // Besides, the flash swap does not work even when swapping the token for WETH due to the same reason.
        // For the tax token, you should follow the normal flow:
        //  (1) transfer token/WETH to the pair
        //  (2) call the pair's swap function.

        PackedPoolState memory currentPoolState = poolState;
        PoolState currentState = PoolState(currentPoolState.state);
        if (
            (currentState == PoolState.TaxEnforced ||
                currentState == PoolState.TaxEnforcedAntiFarmer) && // only when tax is enforced
            currentPoolState.notLiquidating && // not in the middle of liquidation
            (to == mainPool) // possibly selling to the main v2 pool
        ) {
            bool stateChanged = false;

            // State transition
            if (block.timestamp > currentPoolState.taxExpirationTime) {
                PoolState oldState = PoolState(currentPoolState.state);
                currentPoolState.state = uint8(PoolState.TaxFree);
                currentPoolState.taxRate = 0; // reset tax rate
                stateChanged = true;
                emit PoolStateChanged(uint8(oldState), currentPoolState.state);
            } else if (
                block.timestamp > currentPoolState.antiFarmerExpirationTime &&
                currentState != PoolState.TaxEnforced
            ) {
                PoolState oldState = PoolState(currentPoolState.state);
                currentPoolState.state = uint8(PoolState.TaxEnforced);
                stateChanged = true;
                emit PoolStateChanged(uint8(oldState), currentPoolState.state);
            }

            uint256 taxAmount = balanceOf(address(this));

            if (
                taxAmount > 0 && // Tax to liquidate
                (PoolState(currentPoolState.state) == PoolState.TaxFree ||
                    taxAmount >= currentPoolState.liquidationThreshold) // Enough tax to liquidate or last liquidation
            ) {
                currentPoolState.notLiquidating = false; // start liquidation

                // Write state changes to storage once
                poolState = currentPoolState;

                // process tax via TaxProcessor
                _processTax(taxAmount);

                // Re-read poolState and update notLiquidating, then write back
                currentPoolState = poolState;
                currentPoolState.notLiquidating = true; // end of liquidation
                poolState = currentPoolState;
            } else if (stateChanged) {
                // Write state changes to storage if any occurred
                poolState = currentPoolState;
            }
        }
    }

    /// @notice Adjusts the liquidation threshold based on the tax amount and output amount
    /// @param taxAmount The amount of tax being liquidated
    /// @param outputAmount The output amount from the liquidation
    function _adjustLiquidationThreshold(
        uint256 taxAmount,
        uint256 outputAmount
    ) internal {
        // We only monotonically reduce the liquidation threshold until it reaches the minimum threshold
        PackedPoolState memory currentPoolState = poolState;
        uint256 expectedOutputAmount = (outputAmount *
            currentPoolState.liquidationThreshold) / taxAmount;
        if (expectedOutputAmount > liqExpectedOutputAmount) {
            currentPoolState.liquidationThreshold = uint96(
                (currentPoolState.liquidationThreshold * 99) / 100
            ); // Reduce by 1%
            if (currentPoolState.liquidationThreshold < MIN_LIQ_THRESHOLD) {
                currentPoolState.liquidationThreshold = uint96(
                    MIN_LIQ_THRESHOLD
                );
            }
            poolState = currentPoolState;
        }
    }

    /// @notice OZ v5 hook: Called during every token transfer (including mint/burn)
    /// @param from The address sending tokens (address(0) for minting)
    /// @param to The address receiving tokens (address(0) for burning)
    /// @param value The amount being transferred
    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        // Call parent implementation first
        super._update(from, to, value);
        emit TransferSpawnToken(from, to, value);
    }

    /// @notice Internal helper to process tax tokens
    /// @param taxAmount The amount of tax tokens to process
    function _processTax(uint256 taxAmount) internal returns (bool) {
        if (taxAmount == 0) return true;

        // Approve TaxProcessor to pull tokens
        if (allowance(address(this), taxProcessor) < taxAmount) {
            _approve(address(this), taxProcessor, type(uint256).max);
        }

        // Call TaxProcessor.processTaxTokens with total tax amount
        // The TaxProcessor will read configuration from this contract (msg.sender)
        // and handle fee computation, remainder splitting, deflation burning, and distribution
        try ITaxProcessor(taxProcessor).processTaxTokens(taxAmount) {
            // Success
        } catch (bytes memory reason) {
            emit TaxLiquidationError(reason);
            // If processing failed, transfer remaining tokens directly to taxProcessor
            // to prevent them from being permanently locked here
            uint256 remainingBalance = balanceOf(address(this));
            if (remainingBalance > 0) {
                _plainTransfer(address(this), taxProcessor, remainingBalance);
            }
        }
        return true;
    }

    // Getter functions for individual packed fields to maintain external API compatibility

    /// @notice Returns the current state of the pool
    /// @return The current PoolState enum value
    function state() external view returns (PoolState) {
        return PoolState(poolState.state);
    }

    /// @notice Returns the current tax rate in basis points
    /// @return The tax rate for the token in basis points
    function taxRate() external view returns (uint16) {
        return poolState.taxRate;
    }

    /// @notice Returns the liquidation threshold
    /// @return The threshold of tokens for liquidity
    function liquidationThreshold() external view returns (uint256) {
        return poolState.liquidationThreshold;
    }

    /// @notice Returns the timestamp when the tax expires
    /// @return Timestamp when the tax expires
    function taxExpirationTime() external view returns (uint256) {
        return poolState.taxExpirationTime;
    }

    /// @notice Returns the timestamp when the anti-farmer tax expires
    /// @return Timestamp when the anti-farmer tax expires
    function antiFarmerExpirationTime() external view returns (uint256) {
        return poolState.antiFarmerExpirationTime;
    }

    /// @notice Returns all pool state data in a single call (gas-optimized)
    /// @return currentState The current PoolState enum value
    /// @return currentTaxRate The tax rate for the token in basis points
    /// @return currentLiquidationThreshold The threshold of tokens for liquidity
    /// @return currentTaxExpirationTime Timestamp when the tax expires
    /// @return currentAntiFarmerExpirationTime Timestamp when the anti-farmer tax expires
    function getPoolStateData()
        external
        view
        returns (
            PoolState currentState,
            uint16 currentTaxRate,
            uint256 currentLiquidationThreshold,
            uint256 currentTaxExpirationTime,
            uint256 currentAntiFarmerExpirationTime
        )
    {
        PackedPoolState memory currentPoolState = poolState;
        return (
            PoolState(currentPoolState.state),
            currentPoolState.taxRate,
            currentPoolState.liquidationThreshold,
            currentPoolState.taxExpirationTime,
            currentPoolState.antiFarmerExpirationTime
        );
    }

    /// @notice Override nonces to resolve diamond inheritance conflict (OZ v5)
    /// @param owner The address to get the nonce for
    /// @return The current nonce for the owner
    function nonces(
        address owner
    )
        public
        view
        virtual
        override(ERC20PermitUpgradeable, IERC20Permit)
        returns (uint256)
    {
        return super.nonces(owner);
    }
}

/// @dev This is a stripped version of the Uniswap SwapRouter02 interface
/// https://github.com/Uniswap/swap-router-contracts/blob/v1.3.0/contracts/SwapRouter02.sol
/// In the context of PancakeSwap, it is named as SmartRouter:
/// https://bscscan.com/address/0x13f4EA83D0bd40E75C8222255bc855a974568Dd4#code
interface ISmartRouter {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(
        bytes[] calldata data
    ) external payable returns (bytes[] memory results);

    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    /// @param amountIn The amount of token to swap
    /// @param amountOutMin The minimum amount of output that must be received
    /// @param path The ordered list of tokens to swap through
    /// @param to The recipient address
    /// @return amountOut The amount of the received token
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

interface IUniswapRouter02 {
    // @notice Swaps an exact amount of input tokens for as many output tokens as possible, with support for fee-on-transfer tokens
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    // @notice Swaps an exact amount of input tokens for as many output tokens as possible, with support for fee-on-transfer tokens
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    // Add liquidity (UniswapV2-style)
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    // @notice Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}
