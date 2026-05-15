// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

library Constants {
    address constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;
    address constant GENESIS = 0x2DCAb38844EBB1B0F5A77fFbBb66430a51C2aef0;
    address constant PHOENIX_VAULT = 0x6B59b8E9635909B7f0FF2C577BB15c936f32619A;
    address constant LIQUIDITY_BONDING = 0xFc39aBcde6661C84635eBBcab5334eFEbE833456;
    address constant OWNER = 0xC8a38f5e29155D1A349e1c8156C336912994230E;

    uint64 constant WAD = 1e18;

    uint64 constant DEFAULT_INCENTIVE = 0.01e18; //1%

    ///@dev  The initial titan x amount needed to create liquidity pool
    uint256 constant INITIAL_TITAN_X_FOR_LIQ = 9_500_000_000e18;

    uint24 constant POOL_FEE = 10_000; //1%

    int24 constant TICK_SPACING = 200; // Uniswap's tick spacing for 1% pools is 200

    uint32 public constant AUCTION_DURATION = 24 hours;
    uint32 public constant GAP_BETWEEN_AUCTIONS = 24 hours;
    uint8 public constant MAX_AUCTIONS = 28;
    uint32 public constant AUCTION_CLAIM_BUFFER = 1 hours;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000e18;
}
