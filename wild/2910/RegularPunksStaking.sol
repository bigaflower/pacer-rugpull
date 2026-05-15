// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRegularPunksStats} from "./interfaces/IRegularPunksStats.sol";
import {IRegularPunksRenderer} from "./interfaces/IRegularPunksRenderer.sol";

interface IRegularPunksMinimal {
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// @notice Simple staking/training wrapper for Regular Punks.
/// Tokens are held in this contract while a single stat trains on-chain inside RegularPunksStats.
contract RegularPunksStaking {
    uint256 public constant MAX_SUPPLY = 10_000;

    IRegularPunksMinimal public immutable punks;
    IRegularPunksStats public immutable stats;
    IRegularPunksRenderer public immutable renderer;

    mapping(uint256 => address) public stakerOf;

    bool private _locked;

    event Staked(uint256 indexed tokenId, address indexed staker, uint8 statIndex);
    event TrainingChanged(uint256 indexed tokenId, uint8 statIndex);
    event Unstaked(uint256 indexed tokenId, address indexed staker);

    constructor(address punks_, address stats_, address renderer_) {
        punks = IRegularPunksMinimal(punks_);
        stats = IRegularPunksStats(stats_);
        renderer = IRegularPunksRenderer(renderer_);
    }

    modifier nonReentrant() {
        require(!_locked, "reentrancy");
        _locked = true;
        _;
        _locked = false;
    }

    /// @notice Stake and start training a stat (0=Attack,1=Defense,2=Agility) for multiple tokenIds.
    function stakeAndTrain(uint256[] calldata tokenIds, uint8 statIndex) external nonReentrant {
        if (statIndex > 2) revert("bad stat");
        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ) {
            uint256 tokenId = tokenIds[i];
            if (stakerOf[tokenId] != address(0)) revert("already staked");
            if (punks.ownerOf(tokenId) != msg.sender) revert("not owner");

            punks.transferFrom(msg.sender, address(this), tokenId);
            stakerOf[tokenId] = msg.sender;
            stats.startTraining(tokenId, statIndex);
            _refresh(tokenId);

            emit Staked(tokenId, msg.sender, statIndex);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Switch the active training stat for an already staked punk.
    function changeStat(uint256 tokenId, uint8 statIndex) external nonReentrant {
        if (statIndex > 2) revert("bad stat");
        if (stakerOf[tokenId] != msg.sender) revert("not staker");

        stats.changeTrainingStat(tokenId, statIndex);
        _refresh(tokenId);
        emit TrainingChanged(tokenId, statIndex);
    }

    /// @notice Unstake and settle training for multiple tokenIds.
    function unstake(uint256[] calldata tokenIds) external nonReentrant {
        uint256 len = tokenIds.length;
        for (uint256 i; i < len; ) {
            uint256 tokenId = tokenIds[i];
            address staker = stakerOf[tokenId];
            if (staker != msg.sender) revert("not staker");

            stats.finishTraining(tokenId);
            delete stakerOf[tokenId];
            punks.transferFrom(address(this), staker, tokenId);
            _refresh(tokenId);

            emit Unstaked(tokenId, staker);
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Lightweight view helper: iterates over all 10k punks and returns
    /// the tokenIds the user currently owns (i.e. held in their wallet, not staked)
    /// and the tokenIds they have staked in this contract.
    /// @dev This does a full 10k scan; keep it as an off-chain eth_call, not in a tx.
    function ownedAndStakedBy(address user) external view returns (uint256[] memory owned, uint256[] memory staked) {
        uint256[] memory ownedTmp = new uint256[](MAX_SUPPLY);
        uint256[] memory stakedTmp = new uint256[](MAX_SUPPLY);
        uint256 ownedCount;
        uint256 stakedCount;

        for (uint256 tokenId; tokenId < MAX_SUPPLY; ) {
            address staker = stakerOf[tokenId];
            if (staker == user) {
                stakedTmp[stakedCount] = tokenId;
                unchecked {
                    ++stakedCount;
                }
            } else if (staker == address(0)) {
                // Only check ownership when the token is not already held by the staking contract.
                try punks.ownerOf(tokenId) returns (address owner) {
                    if (owner == user) {
                        ownedTmp[ownedCount] = tokenId;
                        unchecked {
                            ++ownedCount;
                        }
                    }
                } catch {
                    // ownerOf may revert for non-existent tokens; ignore and continue.
                }
            }

            unchecked {
                ++tokenId;
            }
        }

        owned = new uint256[](ownedCount);
        staked = new uint256[](stakedCount);

        for (uint256 i; i < ownedCount; ) {
            owned[i] = ownedTmp[i];
            unchecked {
                ++i;
            }
        }
        for (uint256 i; i < stakedCount; ) {
            staked[i] = stakedTmp[i];
            unchecked {
                ++i;
            }
        }
    }

    function _refresh(uint256 tokenId) internal {
        // Notify renderer to emit ERC4906 metadata update on the collection.
        renderer.notifyTrainingChange(tokenId);
    }
}

