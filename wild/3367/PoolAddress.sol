// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Pool Address Computation
/// @notice Provides functions for computing Uniswap V2/V3 pool addresses
library LibPoolAddress {
    bytes32 internal constant V3_POOL_INIT_CODE_HASH =
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    // V2 pair init code hash - Standard Uniswap V2 hash
    // Factory 0xF62c03E08ada871A0bEb309762E260a7a6a880E6 on Sepolia uses mainnet hash
    // This is also the standard Uniswap V2 mainnet hash
    bytes32 internal constant V2_PAIR_INIT_CODE_HASH =
        0x96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Computes Uniswap V3 pool address
    /// @param factory The Uniswap V3 factory contract address
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @param fee Pool fee tier
    /// @return pool The V3 pool address
    function computeV3PoolAddress(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (address pool) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encode(token0, token1, fee)),
                            V3_POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }

    /// @notice Computes Uniswap V2 pair address
    /// @param factory The Uniswap V2 factory contract address
    /// @param tokenA First token
    /// @param tokenB Second token
    /// @return pair The V2 pair address
    function computeV2PoolAddress(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            V2_PAIR_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}
