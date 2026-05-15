// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {
    ERC20PermitUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/**
 * @title GAIBToken
 * @notice Upgradeable ERC20 token for GAIB with minting, burning, pausing, and permit (EIP-2612).
 * @dev Combines OpenZeppelin upgradeable ERC20, Permit, Pausable, Ownable (2-step), and UUPS.
 *
 * Features:
 * - ERC20 standard compliance
 * - Ownable (access control)
 * - Mintable and Burnable (owner) and bridge-controlled mint/burn
 * - Pausable (emergency stop functionality)
 * - Permit (gasless approvals via EIP-2612)
 *
 * Token Details:
 * - Name: GAIB
 * - Symbol: GAIB
 * - Decimals: 18
 */
contract GAIBToken is
    ERC20Upgradeable,
    ERC20PermitUpgradeable,
    Ownable2StepUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    /// @notice Address allowed to mint/burn via bridge operations.
    address public bridgeMintBurner;
    // Reserve storage to allow future upgrades without shifting storage layout
    uint256[50] private __gap;

    /// @notice Emitted when the bridge mint/burner address is updated.
    /// @param bridgeMintBurner The new bridge minter/burner address
    event BridgeMintBurnerSet(address bridgeMintBurner);

    /// @notice Reverts when a caller is not the configured bridge mint/burner.
    error NotBridgeMintBurner();
    /// @notice Reverts when the owner is not set.
    error OwnerNotSet();

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice Restricts a function to the `bridgeMintBurner` address.
    modifier onlyBridgeMintBurner() {
        if (msg.sender != bridgeMintBurner) revert NotBridgeMintBurner();
        _;
    }

    /**
     * @notice Initializes the upgradeable token contract.
     * @dev Replaces the constructor for upgradeable contracts.
     * @param initialOwner The address that will become the contract owner
     * @param initAmount Initial token amount to mint to `initialOwner`
     */
    function initialize(address initialOwner, uint256 initAmount) public initializer {
        __ERC20_init("GAIB", "GAIB");
        __ERC20Permit_init("GAIB");
        __Pausable_init();
        __Ownable_init(initialOwner);
        _mint(initialOwner, initAmount);
    }

    /**
     * @notice Mints new tokens to a specified address.
     * @dev Callable only by the owner.
     * @param to The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens from a specified address.
     * @dev Callable only by the owner.
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) public onlyOwner {
        _burn(from, amount);
    }

    /**
     * @notice Sets the bridge address that is allowed to mint and burn via bridge flows.
     * @dev Callable only by the owner.
     * @param _bridgeMintBurner The address to grant bridge mint/burn permissions to
     */
    function setBridgeMintBurner(address _bridgeMintBurner) public onlyOwner {
        bridgeMintBurner = _bridgeMintBurner;
        emit BridgeMintBurnerSet(_bridgeMintBurner);
    }

    /**
     * @notice Mints tokens as part of a bridge inflow.
     * @dev Callable only by the `bridgeMintBurner`.
     * @param to Recipient of minted tokens
     * @param amount Amount of tokens to mint
     */
    function bridgeMint(address to, uint256 amount) public onlyBridgeMintBurner whenNotPaused {
        if (owner() == address(0)) revert OwnerNotSet();
        _mint(to, amount);
    }

    /**
     * @notice Burns tokens as part of a bridge outflow.
     * @dev Callable only by the `bridgeMintBurner`.
     * @param from Address whose tokens are burned
     * @param amount Amount of tokens to burn
     */
    function bridgeBurn(address from, uint256 amount) public onlyBridgeMintBurner whenNotPaused {
        if (owner() == address(0)) revert OwnerNotSet();
        _burn(from, amount);
    }

    /**
     * @notice Pauses the token contract, disabling transfers.
     * @dev Callable only by the owner. Mint and burn remain allowed while paused.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @notice Unpauses the token contract, enabling transfers.
     * @dev Callable only by the owner.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Overrides ERC20 `_update` to allow mint (from == address(0)) and burn (to == address(0))
     * while paused, but blocks regular transfers when paused.
     * @param from Sender address
     * @param to Recipient address
     * @param value Transfer amount
     */
    function _update(address from, address to, uint256 value) internal virtual override {
        // Allow mint (from == address(0)) and burn (to == address(0)) while paused.
        // Block only regular transfers when paused.
        if (from != address(0) && to != address(0)) {
            _requireNotPaused();
        }
        super._update(from, to, value);
    }

    /**
     * @dev UUPS authorization hook, restricted to the owner.
     * @param newImplementation Address of the new implementation
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
