// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IUniswapV4Router04} from "v4-router/interfaces/IUniswapV4Router04.sol";

/// @title Interfaces - Core interfaces for the Strategic Reserve ecosystem
/// @author Strategic Reserve (https://strategicreserve.fun/)
/// @notice This file contains all the interfaces used by the Strategic Reserve contracts

/// @notice Interface for Universal Router (legacy, kept for compatibility)
interface IUniversalRouter {
    /// @notice Thrown when a required command has failed
    error ExecutionFailed(uint256 commandIndex, bytes message);

    /// @notice Thrown when attempting to send ETH directly to the contract
    error ETHNotAccepted();

    /// @notice Thrown when executing commands with an expired deadline
    error TransactionDeadlinePassed();

    /// @notice Thrown when attempting to execute commands and an incorrect number of inputs are provided
    error LengthMismatch();

    // @notice Thrown when an address that isn't WETH tries to send ETH to the router without calldata
    error InvalidEthSender();

    /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;
}

/// @notice Parameters for exact input single swaps (legacy, kept for compatibility)
struct ExactInputSingleParams {
    PoolKey poolKey;
    bool zeroForOne;
    uint128 amountIn;
    uint128 amountOutMinimum;
    bytes hookData;
}

/// @notice Interface for ERC20 tokens (standard interface)
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @notice Interface for ERC721 NFT collections
/// @dev Standard ERC721 interface with additional owner() function for collection ownership
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
    function owner() external view returns (address);
}

/// @notice Interface for StrategicReserve contracts
/// @dev Core interface for NFT-backed ERC20 reserve tokens
interface IStrategicReserve {
    function initialize(
        address _collection,
        address _hook,
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _buyIncrement,
        address _owner,
        bool _isIdRestricted,
        bool _upgradeBlock
    ) external;
    function factory() external view returns (address);
    function router() external view returns (address);
    function poolManager() external view returns (address);
    function owner() external view returns (address);
    function addFees() external payable;
    function setPricingParams(uint256 _multiplier, uint256 _floor, uint256 _days, uint256 _lockUntil) external;
    function updateName(string memory _tokenName) external;
    function updateSymbol(string memory _tokenSymbol) external;
    function updateHookAddress(address _hookAddress) external;
    function nftForSale(uint256 tokenId) external view returns (uint256);
    function sellTargetNFT(uint256 tokenId, address feeRecipient, uint256 requestedFeeBips) external payable;
    function increaseTransferAllowance(uint256 amountAllowed) external;
    function getTransferAllowance() external view returns (uint256);
    function getImplementation() external view returns (address);
    function upgradeToAndCall(address newImplementation, bytes memory data) external;
    function setMarketEnforce(bool _enable) external;
    function isMarketEnforced() external view returns (bool);
    function setOpBlock(uint8 _mode) external;
    function opBlock() external view returns (uint8);
    function recoverUntrackedFees() external;
    function setRecoverFeesAllowance(uint8 _mode) external;
    function recoverFeesAllowance() external view returns (uint8);
    function adjustFloorProtect(uint256 _buyIncrement, uint256 _maxBuyCapPct, uint256 _floorResetPct, bool _disableAdaptive) external;
    function setAllowedTokenIds(uint256[] calldata tokenIds, bool status) external;
    function isIdRestricted() external view returns (bool);
    function allowedTokenId(uint256 tokenId) external view returns (bool);
    function collection() external view returns (address);
    function isDistributor(address) external view returns (bool);
    function setDistributor(address distributor, bool status) external;
    function reserveVaultFee() external view returns (uint128);
    function communityAddr() external view returns (address);
    function communityFee() external view returns (uint128);
    function isFeesLocked() external view returns (bool);
    function maxReserveFee() external view returns (uint128);
    function setCustomFees(uint128 _vaultFeeBips, uint128 _communityFeeBips) external;
    function setMaxReserveFee(uint128 _newMax) external;
    function lockCustomFees() external;
    function setCommunityAddr(address _addr) external;
    function setPubSelfBuy(bool enabled) external;
    function setPubSync(bool enabled) external;
    function setStrategist(address strategist, uint8 level) external;
    function clearAllStrategists() external;
    function setGuardian(address guardian, bool status) external;
    function strategistLevel(address) external view returns (uint8);
    function isGuardian(address) external view returns (bool);
    function isPubSelfBuy() external view returns (bool);
    function isPubSync() external view returns (bool);
    function processVaultChange(address current, address proposed) external returns (bool);
}

/// @notice Interface for StrategicFactory contracts
/// @dev Factory interface for deploying and managing StrategicReserve contracts
interface IStrategicFactory {
    function loadingLiquidity() external view returns (bool);
    function owner() external view returns (address);
    function v1Reserve() external view returns (address);
    function reserveImplementation() external view returns (address);
    function reserveList(uint256 index) external view returns (address);
    function collectionToReserve(address collection, uint256 index) external view returns (address);
    function setReserveImplementation(address _reserveImplementation) external;
    function updateHookAddress(address _hookAddress) external;
    function ownerLaunchReserve(
        address collection,
        string memory tokenName,
        string memory tokenSymbol,
        uint256 buyIncrement,
        bool isIdRestricted,
        uint256 specialAlloc
    ) external payable returns (address);
    function isCallAllowed(address target, bytes4 sig) external view returns (bool);
    function addMarket(address market) external;
    function removeMarket(address market) external;
    function addMarketSig(address market, bytes4 sig) external;
    function removeMarketSig(address market, bytes4 sig) external;
    function strategicVault(address reserve) external view returns (address);
    function setVaultOwner(address reserve, address newOwner) external;
    function validTransfer(address from, address to, address tokenAddress) external view returns (bool isValid, bool shouldTaxEOA);
    function reserveEOAConfig(address reserve) external view returns (bool enabled, uint8 taxMode, uint8 discount, bool sigEnabled, uint8 sigTaxMode, uint8 sigDiscount);
    function setEOAConfig(address reserve, bool enabled, uint8 taxMode, uint8 discount, bool sigEnabled, uint8 sigTaxMode, uint8 sigDiscount) external;
    function setLocalBypass(address reserve, address addr, bool allowed, bool taxExempt) external;
    function strategicAirdrop(address reserve) external view returns (address);
    function localBypass(address reserve, address addr) external view returns (bool allowed, bool taxExempt);
    function reserveLauncher(address reserve) external view returns (address);
    function strategicAdvance(address reserve) external view returns (address);
    function getStrategicAdvance(address reserve) external view returns (address);
    function strategicLens() external view returns (address);
    function strategicRegister() external view returns (address);
}

/// @notice Interface for StrategicHook contracts
/// @dev Hook interface for fee management and distribution
interface IStrategicHook {
    function updateFeeAddress(address collection, address destination) external;
    function setV1Reserve(address _v1Reserve) external;
    function setStartingBuyFee(uint128 _newFee) external;
    function setDefaultFee(uint128 _buyFee, uint128 _sellFee) external;
    function lockDefaultFees() external;
    function v1Reserve() external view returns (address);
    function defaultReserveVaultFee() external view returns (uint128);
    function defaultFeeBuy() external view returns (uint128);
    function defaultFeeSell() external view returns (uint128);
}

/// @notice Interface for StrategicAdvance contracts
/// @dev Helper contract interface for advanced NFT operations and royalty calculations
interface IStrategicAdvance {
    function royaltyCalc(address collection, uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 amount);
    function handleReserveAlloc(uint256 amount) external;
}

/// @notice Interface for StrategicLens view aggregator
/// @dev Used for NFT enumeration and data aggregation across Reserves
interface IStrategicLens {
    function getAcctNFTs(
        address acct,
        address collection,
        uint256 startTokenId,
        uint256 endTokenId
    ) external view returns (uint256[] memory tokenIds);
}

/// @notice Interface for StrategicDrop airdrop contracts
/// @dev Used for querying claim status in airdrop contracts
interface IStrategicDrop {
    function hasClaimed(uint256 nftId) external view returns (bool);
    function startTokenId() external view returns (uint256);
    function endTokenId() external view returns (uint256);
    function initialized() external view returns (bool);
}

