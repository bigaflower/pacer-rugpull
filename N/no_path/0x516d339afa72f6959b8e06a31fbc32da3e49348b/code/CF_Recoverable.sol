// SPDX-License-Identifier: MIT

pragma solidity 0.8.25;

import "./CF_Common.sol";
import "./CF_Ownable.sol";

abstract contract CF_Recoverable is CF_Common, CF_Ownable {
  /// @notice Recovers a misplaced amount of an ERC-20 token sitting in the contract balance
  /// @dev Beware of scam tokens!
  /// @dev Note that if the token of this contract is specified, amounts allocated for tax distribution and liquidity are reserved
  /// @param token Address of the ERC-20 token
  /// @param to Recipient
  /// @param amount Amount to be transferred
  function recoverERC20(address token, address to, uint256 amount) external onlyOwner {
    unchecked {
      uint256 balance = IERC20(token).balanceOf(address(this));
      uint256 allocated = token == address(this) ? _amountForTaxDistribution + _amountForLiquidity : (address(_taxToken) == token ? _tokensForTaxDistribution[address(_taxToken)] : 0);

      require(balance - (allocated >= balance ? balance : allocated) >= amount, "Exceeds balance");
    }

    IERC20(token).transfer(to, amount);
  }

  /// @notice Recovers a misplaced ERC-721 (NFT) sitting in the contract
  /// @dev Beware of scam tokens!
  /// @param token Address of the ERC-721 token
  /// @param to Recipient
  /// @param tokenId Unique identifier of the NFT
  function recoverERC721(address token, address to, uint256 tokenId) external onlyOwner {
    IERC721(token).safeTransferFrom(address(this), to, tokenId);
  }

  /// @notice Recovers a misplaced amount of native tokens sitting in the contract balance
  /// @dev Note that if the reflection token is the wrapped native, amounts allocated for tax distribution and/or liquidity are reserved
  /// @param to Recipient
  /// @param amount Amount of native tokens to be transferred
  function recoverNative(address payable to, uint256 amount) external onlyOwner {
    unchecked {
      uint256 balance = address(this).balance;
      uint256 allocated = address(_taxToken) == _dex.WETH ? _ethForTaxDistribution : 0;

      require(balance - (allocated >= balance ? balance : allocated) >= amount, "Exceeds balance");
    }

    (bool success, ) = to.call{ value: amount }("");

    require(success);
  }
}
