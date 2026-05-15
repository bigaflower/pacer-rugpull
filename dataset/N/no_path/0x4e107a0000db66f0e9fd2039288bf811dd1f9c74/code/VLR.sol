// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import { SafeTransferLib } from "solady/src/utils/SafeTransferLib.sol";

/// @title VLR Token
/// @dev This contract implements a full-featured ERC20 token with the following features:
///
/// - Fixed initial supply of 2 billion tokens
/// - Annual mint cap of 2% after Nov 15, 2025
/// - One-year cooldown between mint operations
/// - ERC20Permit for improved UX with gasless approvals
/// - Token Recovery: Ability to recover accidentally sent tokens
contract VLR is IERC165, Ownable, ERC20, ERC20Burnable, ERC20Permit {
    using SafeTransferLib for address;

    // Events for tracking operations
    event TokensMinted(address indexed to, uint256 amount);
    event TokenRecovered(address indexed token, uint256 amount, address indexed to);

    // Custom errors
    error MintingTimelockActive();
    error ZeroAddressNotAllowed();
    error AnnualMintLimitExceeded();
    error CannotRecoverBaseToken();
    error ZeroAmountNotAllowed();

    // Constants
    uint256 public constant MINT_COOLDOWN = 1 days * 365;
    uint256 public constant MINT_CAP = 2;

    // Initial token supply: 2 billion tokens with 18 decimals
    uint256 public constant INITIAL_SUPPLY = 2_000_000_000 * 10 ** 18; // 2 billion tokens

    // Hardcoded mint start date: November 15, 2025
    uint256 public constant MINT_UNLOCK_TIMESTAMP = 1763208000; // Timestamp for Nov 15, 2025, 12:00:00 UTC

    // Next minting allowed timestamp, starts with hardcoded value
    uint256 public mintingAllowedAfter = MINT_UNLOCK_TIMESTAMP;

    /// @notice Constructor that initializes the token with its fixed initial supply
    /// @param _owner Address that will be set as the owner and receive the initial supply
    constructor(address _owner) ERC20("Velora", "VLR") ERC20Permit("Velora") Ownable(_owner) {
        // Revert if owner is zero address
        if (_owner == address(0)) revert ZeroAddressNotAllowed();

        // mint the initial supply to the specified owner
        _mint(_owner, INITIAL_SUPPLY);
    }

    /// @notice Calculate the maximum amount of tokens that can be minted
    /// @dev Based on the current total supply and MINT_CAP percentage
    /// @return maxMintAmount The maximum amount of tokens that can be minted (2% of total supply)
    function getMaxMintAmount() public view returns (uint256) {
        return (totalSupply() * MINT_CAP) / 100;
    }

    /// @notice Mint new tokens
    /// @dev Only callable by owner, minting limited to 2% per year
    /// @param _dst Address to mint tokens to
    /// @param _amount Amount of tokens to mint
    function mint(address _dst, uint256 _amount) external onlyOwner {
        if (_dst == address(0)) revert ZeroAddressNotAllowed();
        if (block.timestamp < mintingAllowedAfter) revert MintingTimelockActive();
        if (_amount > getMaxMintAmount()) revert AnnualMintLimitExceeded();

        // record the mint time & mint the amount
        mintingAllowedAfter = block.timestamp + MINT_COOLDOWN;
        _mint(_dst, _amount);

        emit TokensMinted(_dst, _amount);
    }

    /// @notice Recover ERC20 tokens accidentally sent to this contract
    /// @dev Only callable by owner
    /// @param _token Address of the token to recover
    /// @param _to Address to send recovered tokens to
    /// @param _amount Amount of tokens to recover
    function recoverERC20(address _token, address _to, uint256 _amount) external onlyOwner {
        if (_token == address(0)) revert ZeroAddressNotAllowed();
        if (_to == address(0)) revert ZeroAddressNotAllowed();
        if (_amount == 0) revert ZeroAmountNotAllowed();
        // Prevent recovering the base token (VLR)
        if (_token == address(this)) revert CannotRecoverBaseToken();

        // Transfer the tokens to the specified address
        _token.safeTransfer(_to, _amount);

        // Emit event for transparency
        emit TokenRecovered(_token, _amount, _to);
    }

    /// @notice Check if this contract supports a given interface
    /// @param _interfaceId The interface identifier to check
    /// @return True if the contract supports the interface, false otherwise
    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
        return
            _interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IERC20).interfaceId ||
            _interfaceId == type(IERC20Permit).interfaceId;
    }
}
