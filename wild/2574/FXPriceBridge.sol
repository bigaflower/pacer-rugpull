// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title USD/RUB Price Bridge
 * @notice Reads A7A5 Uniswap V3 + Wrapper Ratio and sends price to Base
 */
contract FXPriceBridge {
    
    // --- Constants ---
    address public constant POOL = 0xB6d629cb247333DD5e273B75741c55DfEca6f6e9; // USDT/wA7A5
    address public constant WRAPPER = 0xF442fF10b8deF89514560A66C0AD28777094636a; // wA7A5
    address public constant L1_MESSENGER = 0x866E82a600A1414e583f7F13623F1aC5d58b0Afa; // Base Portal on Mainnet
    
    address public l2Receiver;
    address public owner;
    
    // Period for Time Weighted Average Price (e.g., 300 = 5 minutes)
    uint32 public twapInterval = 300; 
    
    // Gas limit for the execution on Base (200k is plenty for a storage update)
    uint32 public l2GasLimit = 200000;

    constructor() {
        owner = msg.sender;
    }

    function setL2Receiver(address _l2Receiver) external {
        require(msg.sender == owner, "Not owner");
        l2Receiver = _l2Receiver;
    }

    /**
     * @notice Main function to trigger the update
     * Calculates USD/RUB
     */
    function updatePrice() external {
        require(l2Receiver != address(0), "L2 Receiver not set");

        // 1. Get the Wrapper Ratio
        // returns 6 decimals. e.g., 1000000 means 1:1
        uint256 wA7A5price = IWrapper(WRAPPER).A7A5PerToken();
        require(wA7A5price > 0, "Invalid ratio");

        // 3. Get Uniswap TWAP Tick
        int24 tick = getTwapTick();

        // 4. Calculate Quote: How much wA7A5 (token1) for 'wA7A5price' of USDT (token0)
        uint256 USDTprice = getQuoteAtTick(tick, uint128(wA7A5price), true); 
        // Note: boolean true means we are selling token0 to buy token1 (USDt -> wA7A5)

        // 5. Result `USDTprice` is 6 decimals. Scale to 18 for Oracle Standard.
        uint256 finalPrice18Dec = USDTprice * 1e12;

        // 6. Send to Base
        bytes memory message = abi.encodeWithSignature("updatePrice(uint256)", finalPrice18Dec);
        
        // This sends the message
        ICrossDomainMessenger(L1_MESSENGER).sendMessage(
            l2Receiver,
            message,
            l2GasLimit
        );
    }

    function getTwapTick() internal view returns (int24) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapInterval;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(POOL).observe(secondsAgos);
        
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 arithmeticMeanTick = int24(tickCumulativesDelta / int56(uint56(twapInterval)));
        
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapInterval)) != 0)) {
            arithmeticMeanTick--;
        }
        return arithmeticMeanTick;
    }

    // --- Math & Quotes ---

    function getQuoteAtTick(int24 tick, uint128 baseAmount, bool baseTokenIsToken0) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if possible
        if (baseTokenIsToken0) {
            // Trade Token0 -> Token1
            // quote = amount * (ratio^2 / 2^192)
            if (sqrtRatioX96 <= type(uint128).max) {
                uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
                quoteAmount = baseTokenIsToken0
                    ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                    : 0; // Unreacheable in this branch
            } else {
                uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
                quoteAmount = baseTokenIsToken0
                    ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                    : 0;
            }
        } else {
            // Trade Token1 -> Token0 (wA7A5 -> USDT)
            // quote = amount * (2^192 / ratio^2)
            // Functionally: amount * 2^192 / ratio^2
             if (sqrtRatioX96 > 0) {
                uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
                quoteAmount = FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
             }
        }
    }
}

// --- Dependencies (Inlined for ease of deployment) ---

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos) external view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}
interface IWrapper {
    function A7A5PerToken() external view returns (uint256);
}
interface ICrossDomainMessenger {
    function sendMessage(address _target, bytes calldata _message, uint32 _gasLimit) external;
}

// Minimal TickMath (from Uniswap V3 core)
library TickMath {
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            require(absTick <= 887272, "T");

            uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc5d757423606) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf332942d29ad6551220db6908e79e5d6) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b496bf7ce066a12dcf24b05) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e50d33e86a53d92af835915878) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x4a3f9cf797edb38613c0e7826378) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }
}

// Minimal FullMath (from Uniswap V3 core)
library FullMath {
    function mulDiv(uint256 a, uint256 b, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            uint256 prod0; 
            uint256 prod1; 
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
            if (prod1 == 0) {
                require(denominator > 0);
                assembly { result := div(prod0, denominator) }
                return result;
            }
            require(denominator > prod1);
            uint256 remainder;
            assembly { remainder := mulmod(a, b, denominator) }
            assembly { prod1 := sub(prod1, gt(remainder, prod0))
                       prod0 := sub(prod0, remainder) }
            uint256 twos = denominator & (~denominator + 1);
            assembly { denominator := div(denominator, twos)
                       prod0 := div(prod0, twos)
                       twos := add(div(sub(0, twos), twos), 1)
                       prod0 := mul(prod0, twos) }
            uint256 inv = (3 * denominator) ^ 2;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            inv *= 2 - denominator * inv;
            result = prod0 * inv;
        }
    }
}