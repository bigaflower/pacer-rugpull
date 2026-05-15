// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

// Distribution addresses
address constant DEAD_ADDR = 0x000000000000000000000000000000000000dEaD;
address constant GENESIS_WALLET = 0xBeb2363cA0A7A9FEB75D88aC27A46Fc8bB75Eb6C;
address constant VOLT_TREASURY = 0xb638BFB7BC3B8398bee48569CFDAA6B3Bb004224;
address constant OWNER = 0xeC0Db0059F749d2a97B216ffd65270E80Db46383;
address constant LIQUIDITY_BONDING_ADDR = 0x45C03d66229d01dF2645E813222b16C8B8b86894;
address constant DEV_WALLET = 0xB22830174575Cd1c43591A8Ed9806aD4C4FEb9BB;

uint128 constant AUCTION_EMIT = 100_000_000e18;

// Percentages in WAD
uint64 constant INCENTIVE_FEE = 0.015e18; //1.5%

uint64 constant TO_GENESIS = 0.07e18; //7%
uint64 constant TO_DEV_WALLET = 0.01e18; //1%
uint64 constant HYPER_BURN = 0.05e18; //5%
uint64 constant TO_LP = 0.1e18; //10%
uint64 constant TO_VOLT_BURN = 0.05e18; //5%
uint64 constant TO_TURBO_BNB = 0.72e18; //72%

// PRECISION
uint64 constant WAD = 1e18;

// INTERVALS
uint16 constant INTERVAL_TIME = 5 minutes;
uint16 constant INTERVALS_PER_DAY = uint16(24 hours / INTERVAL_TIME);

//UNIV3
uint24 constant POOL_FEE = 10_000; //1%
int16 constant TICK_SPACING = 200; // Uniswap's tick spacing for 1% pools is 200

//LIQUIDITY CONFIG

///@dev The initial hyper amount needed to create liquidity pool
uint256 constant INITIAL_HYPER_FOR_LP = 4_000_000_000e18; // The initial hyper amount needed to create liquidity pool

uint256 constant INITIAL_TURBO_FOR_LP = 5_000_000e18; // 5 million TURBO tokens
