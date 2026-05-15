// SPDX-License-Identifier: None

pragma solidity ^0.8.24;

import "./IDataStore.sol";

interface ITokenWhitelist is IDataStoreResponse {
    
    struct TokenInfo {
        string name;
        string symbol;
        address owner;
        address mainWallet;
        address secondaryWallet;
        uint256 totalSupply;
        uint256 percentToLP;
        uint256 lpLockDuration;
        uint256 initMaxWallet;
        FeeInfo buyFees;
        FeeInfo sellFees;
        address[] whitelist;
        uint256 whitelistDuration;
        address rewardToken;
        address futureOwner;
    }

    struct FeeInfo {
        uint256 main;      // Stored in basis points (1 = 0.01%)
        uint256 secondary; // Stored in basis points (1 = 0.01%)
        uint256 liquidity; // Stored in basis points (1 = 0.01%)
        uint256 proof;     // Stored in basis points (1 = 0.01%)
        uint256 total;     // Stored in basis points (1 = 0.01%)
    }

    error ExceedsMaxTxAmount();
    error ExceedsMaxWalletAmount();
    error InvalidConfiguration();
    error TradingNotEnabled();
    error NotWhitelisted();

}