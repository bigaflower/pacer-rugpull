// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

address constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;
address constant GENESIS = 0x24BF5cE05f732381CbCb79966607977FC21B4A18;
address constant OWNER = 0x8D40E3Bb356a02A3A4dd6Dba6CC890fD89675BDA;

uint64 constant TO_BUY_AND_BURN = 0.435e18; // 43.5%
uint64 constant TO_GENESIS = 0.08e18; // 8%
uint64 constant TO_TITAN_X_STAKING_VAULT = 0.05e18; // 5%
uint64 constant BUY_AND_BURN_INCENTIVE = 0.01e18; // 1%
uint64 constant STAKING_INCENTIVE = 0.01e18; // 1%

uint64 constant WAD = 1e18;

///@dev  The initial titan x amount needed to create liquidity pool
uint256 constant INITIAL_TITAN_X_FOR_LIQ = 10_000_000_000e18;

///@dev The intial phoenix that pairs with the inferno received from the swap
uint256 constant INITIAL_PHOENIX_FOR_LP = 10_000_000_000e18;

uint24 constant POOL_FEE = 10_000; //1%

int24 constant TICK_SPACING = 200; // Uniswap's tick spacing for 1% pools is 200
