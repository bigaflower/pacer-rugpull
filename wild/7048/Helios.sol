// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import "./@openzeppelin/contracts/ERC20Blocklist.sol";
import "./@openzeppelin/contracts/Ownable.sol";
import "./@openzeppelin/contracts/ERC20.sol";

/**
 * @title Helios HLS
 *
 * @notice
 * Helios is an ERC20 token whose entire maximum supply (5,000,000,000 HLS) is
 * minted at deployment time and immediately distributed on-chain to its
 * designated allocation wallets (team, advisors, foundation, community,
 * liquidity, etc.). The allocation percentages, recipient addresses, and
 * initial balances are fully transparent and verifiable directly on-chain.
 *
 * In addition, 1,450,000,000 HLS are immediately burned on Ethereum mainnet,
 * since these tokens are intended to be generated natively on the Helios mainnet.
 * This ensures that the effective circulating supply on Ethereum reflects the
 * intended tokenomics while reserving the node rewards issuance for the Helios
 * network itself.
 *
 * The contract also integrates a blocklist mechanism that can prevent specific
 * addresses from transferring or receiving tokens, as well as from creating
 * approvals. This mechanism is administered by the contract owner
 * (expected to be a DAO, a regulated entity, or a properly configured
 * multisig) and is intended to enable regulatory compliance in line with
 * current European frameworks such as MiCA, including measures against illicit
 * activities, sanctioned addresses, or fraudulent behavior.
 *
 * The Helios token is therefore designed to support transparent initial
 * distribution while providing compliance-oriented controls when required,
 * without altering the publicly verifiable tokenomics.
 */
contract Helios is ERC20Blocklist, Ownable {

    constructor() ERC20("Helios", "HLS") {
        // 18 decimals (hardcoded)
        // Seed — 2.00% — 100,000,000 - 0x3F83181F3B5B46186307Ed1b45639b429B30a271 (Treasury Wallet)
        // Strategic — 2.00% — 100,000,000 - 0x3F83181F3B5B46186307Ed1b45639b429B30a271 (Treasury Wallet)
        // Public — 3.00% — 150,000,000 - 0x3F83181F3B5B46186307Ed1b45639b429B30a271 (Treasury Wallet)
        // Team — 15.00% — 750,000,000 - 0x5F0Cf2D3738E67BbA660D354E8483977bC61Ba68 (Team Wallet)
        // Advisors — 5.00% — 250,000,000 - 0x825fe6Db349d3A020c588D8f748A14f182DA84c8 (Advisors Wallet)
        // Foundation — 24.00% — 1,200,000,000 - 0xf948be20f0b732994f14027d9a04A46a74393c06 (Foundation Wallet)
        // Community — 10.00% — 500,000,000 - 0x53Cf9DD4db705b2e15C1027B74699C361c27bEDD (Community Wallet)
        // Airdrop — 5.00% — 250,000,000 - 0xb25c18bC0763B5CEE424aDBF3078c9C284E38cCF (Airdrop Wallet)
        // Node Rewards Phase 1 — 12.50% — 625,000,000 - 0x0000000000000000000000000000000000000000 (Node Rewards Phase 1 Wallet)
        // Node Rewards Phase 2 — 9.00% — 450,000,000 - 0x0000000000000000000000000000000000000000 (Node Rewards Phase 2 Wallet)
        // Node Rewards Phase 3 — 7.50% — 375,000,000 - 0x0000000000000000000000000000000000000000 (Node Rewards Phase 3 Wallet)
        // Liquidity — 5.00% — 250,000,000 - 0x3F83181F3B5B46186307Ed1b45639b429B30a271 (Treasury Wallet who manage liquidity)
        // Total Supply: 3,550,000,000
        // Supply Via Node Rewards: 1,450,000,000 - burnt on Ethereum Mainnet (0x000000000000000000000000000000000000dEaD)
        // Max Total Supply: 5,000,000,000
        // 1 ether = 10^18 HLS
        _mint(address(this), 5000000000 ether); // Max Total Supply
        // Transfer to the wallets
        _transfer(address(this), 0x3F83181F3B5B46186307Ed1b45639b429B30a271, 100000000 ether); // Seed
        _transfer(address(this), 0x3F83181F3B5B46186307Ed1b45639b429B30a271, 100000000 ether); // Strategic
        _transfer(address(this), 0x3F83181F3B5B46186307Ed1b45639b429B30a271, 150000000 ether); // Public
        _transfer(address(this), 0x5F0Cf2D3738E67BbA660D354E8483977bC61Ba68, 750000000 ether); // Team
        _transfer(address(this), 0x825fe6Db349d3A020c588D8f748A14f182DA84c8, 250000000 ether); // Advisors
        _transfer(address(this), 0xf948be20f0b732994f14027d9a04A46a74393c06, 1200000000 ether); // Foundation
        _transfer(address(this), 0x53Cf9DD4db705b2e15C1027B74699C361c27bEDD, 500000000 ether); // Community
        _transfer(address(this), 0xb25c18bC0763B5CEE424aDBF3078c9C284E38cCF, 250000000 ether); // Airdrop
        _transfer(address(this), 0x000000000000000000000000000000000000dEaD, 625000000 ether); // Node Rewards Phase 1
        _transfer(address(this), 0x000000000000000000000000000000000000dEaD, 450000000 ether); // Node Rewards Phase 2
        _transfer(address(this), 0x000000000000000000000000000000000000dEaD, 375000000 ether); // Node Rewards Phase 3
        _transfer(address(this), 0x3F83181F3B5B46186307Ed1b45639b429B30a271, 250000000 ether); // Liquidity
    }

    /**
     * @dev Block a user from receiving and transferring tokens.
     * @param user The address of the user to block.
     */
    function blockUser(address user) external onlyOwner {
        _blockUser(user);
    }

    /**
     * @dev Unblock a user from receiving and transferring tokens.
     * @param user The address of the user to unblock.
     */
    function unblockUser(address user) external onlyOwner {
        _unblockUser(user);
    }
}
