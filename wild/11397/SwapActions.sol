// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {Errors} from "@utils/Errors.sol";
import {wmul, min} from "@utils/Math.sol";
import {PoolAddress} from "@libs/v3/PoolAddress.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OracleLibrary} from "@libs/v3/OracleLibrary.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @notice Struct representing slippage settings for a pool.
struct Slippage {
    uint224 slippage; //< Slippage in WAD (scaled by 1e18)
    uint32 twapLookback; //< TWAP lookback period in minutes (used as seconds in code)
}

struct SwapActionsState {
    address v3Router;
    address v3Factory;
    address positionManager;
    address owner;
}

/**
 * @title SwapActions
 * @author Decentra
 * @notice A contract that facilitates token swapping on Uniswap V3 with slippage management.
 * @dev Uses Uniswap V3 Router and Oracle libraries for swap actions and TWAP calculations.
 */
contract SwapActions is Ownable, Errors {
    /// @notice Address of the Uniswap V3 Router
    address public immutable v3Router;

    address public immutable positionManager;

    /// @notice Address of the Uniswap V3 Factory
    address public immutable v3Factory;

    /// @notice Address of the admin responsible for managing slippage settings
    address public slippageAdmin;

    /// @notice Mapping of pool addresses to their respective slippage settings
    mapping(address pool => Slippage) public slippageConfigs;

    /// @notice Thrown when an invalid slippage value is provided
    error SwapActions__InvalidSlippage();

    /// @notice Thrown when a non-admin or non-owner attempts to perform slippage-related actions
    error SwapAction__OnlySlippageAdmin();

    error SwapActions__Observations();

    /**
     * @dev Ensures the caller is either the slippage admin or the contract owner.
     */
    modifier onlySlippageAdminOrOwner() {
        _onlySlippageAdminOrOwner();
        _;
    }

    /**
     * @notice Initializes the SwapActions contract with the required router and factory addresses.
     * @notice Swap action params
     */
    constructor(SwapActionsState memory params)
        Ownable(params.owner)
        notAddress0(params.v3Router)
        notAddress0(params.v3Factory)
    {
        positionManager = params.positionManager;
        v3Router = params.v3Router;
        v3Factory = params.v3Factory;
        slippageAdmin = params.owner;
    }

    /**
     * @notice Change the address of the slippage admin.
     * @param _new New slippage admin address.
     * @dev Only callable by the contract owner.
     */
    function changeSlippageAdmin(address _new) external notAddress0(_new) onlyOwner {
        slippageAdmin = _new;
    }

    /**
     * @notice Change slippage configuration for a specific pool.
     * @param pool Address of the Uniswap V3 pool.
     * @param _newSlippage New slippage value (in WAD).
     * @param _newLookBack New TWAP lookback period (in minutes).
     * @dev Only callable by the slippage admin or the owner.
     */
    function changeSlippageConfig(address pool, uint224 _newSlippage, uint32 _newLookBack)
        external
        notAmount0(_newLookBack)
        onlySlippageAdminOrOwner
    {
        require(_newSlippage <= WAD, SwapActions__InvalidSlippage());

        slippageConfigs[pool] = Slippage({slippage: _newSlippage, twapLookback: _newLookBack});
    }

    /**
     * @notice Perform an exact input swap on Uniswap V3.
     * @param tokenIn Address of the input token.
     * @param tokenOut Address of the output token.
     * @param tokenInAmount Amount of the input token to swap.
     * @param deadline Deadline timestamp for the swap.
     * @return amountReceived Amount of the output token received.
     * @dev The function uses the TWAP (Time-Weighted Average Price) to ensure the swap is performed within slippage tolerance.
     */
    function swapExactInputV3(address tokenIn, address tokenOut, uint256 tokenInAmount, uint32 deadline)
        internal
        returns (uint256 amountReceived)
    {
        (uint256 twapAmount, uint224 slippage) = getTwapAmountV3(tokenIn, tokenOut, tokenInAmount);

        IERC20(tokenIn).approve(v3Router, tokenInAmount);

        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn, POOL_FEE, tokenOut),
            recipient: address(this),
            deadline: deadline,
            amountIn: tokenInAmount,
            amountOutMinimum: wmul(twapAmount, slippage)
        });

        return ISwapRouter(v3Router).exactInput(params);
    }

    /**
     * @notice Get the TWAP (Time-Weighted Average Price) and slippage for a given token pair on Uniswap V3.
     * @param tokenIn Address of the input token.
     * @param tokenOut Address of the output token.
     * @param amount Amount of the input token.
     * @return twapAmount The TWAP amount of the output token for the given input.
     * @return slippage The slippage tolerance for the pool.
     */
    function getTwapAmountV3(address tokenIn, address tokenOut, uint256 amount)
        public
        view
        returns (uint256 twapAmount, uint224 slippage)
    {
        address poolAddress = PoolAddress.computeAddress(v3Factory, PoolAddress.getPoolKey(tokenIn, tokenOut, POOL_FEE));

        Slippage memory slippageConfig = slippageConfigs[poolAddress];

        if (slippageConfig.twapLookback == 0 && slippageConfig.slippage == 0) {
            slippageConfig = Slippage({twapLookback: 15, slippage: WAD - 0.2e18});
        }

        uint32 secondsAgo = slippageConfig.twapLookback * 60;

        uint32 oldestObservation = OracleLibrary.getOldestObservationSecondsAgo(poolAddress);

        require(oldestObservation >= secondsAgo, SwapActions__Observations());

        (int24 arithmeticMeanTick,) = OracleLibrary.consult(poolAddress, secondsAgo);

        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(arithmeticMeanTick);

        slippage = slippageConfig.slippage;

        twapAmount = OracleLibrary.getQuoteForSqrtRatioX96(sqrtPriceX96, amount, tokenIn, tokenOut);
    }

    /**
     * @dev Internal function to check if the caller is the slippage admin or contract owner.
     */
    function _onlySlippageAdminOrOwner() private view {
        require(msg.sender == slippageAdmin || msg.sender == owner(), SwapAction__OnlySlippageAdmin());
    }
}
