// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC721} from "solady/tokens/ERC721.sol";
import {SafeTransferLib} from "solady/utils/SafeTransferLib.sol";

import {NFTStrategy} from "../../NFTStrategy.sol";

/// @title VibeStrategy - An custom strategy for GVC
/// @author TokenWorks (https://token.works/)
contract VibeStrategy is NFTStrategy {
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™                ™™™™™™™™™™™                ™™™™™™™™™™™ */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™               ™™™™™™™™™™™™™              ™™™™™™™™™™  */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™              ™™™™™™™™™™™™™              ™™™™™™™™™™™  */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™            ™™™™™™™™™™™   */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™            ™™™™™™™™™™™™™™™            ™™™™™™™™™™™   */
    /*                ™™™™™™™™™™™            ™™™™™™™™™™™           ™™™™™™™™™™™™™™™           ™™™™™™™™™™™    */
    /*                ™™™™™™™™™™™             ™™™™™™™™™™          ™™™™™™™™™™™™™™™™™          ™™™™™™™™™™™    */
    /*                ™™™™™™™™™™™             ™™™™™™™™™™          ™™™™™™™™™™™™™™™™™          ™™™™™™™™™™     */
    /*                ™™™™™™™™™™™              ™™™™™™™™™™        ™™™™™™™™™™™™™™™™™™™        ™™™™™™™™™™™     */
    /*                ™™™™™™™™™™™              ™™™™™™™™™™™       ™™™™™™™™™ ™™™™™™™™™       ™™™™™™™™™™™      */
    /*                ™™™™™™™™™™™               ™™™™™™™™™™      ™™™™™™™™™™ ™™™™™™™™™™      ™™™™™™™™™™™      */
    /*                ™™™™™™™™™™™               ™™™™™™™™™™      ™™™™™™™™™   ™™™™™™™™™      ™™™™™™™™™™       */
    /*                ™™™™™™™™™™™                ™™™™™™™™™™    ™™™™™™™™™™    ™™™™™™™™™    ™™™™™™™™™™        */
    /*                ™™™™™™™™™™™                 ™™™™™™™™™™   ™™™™™™™™™     ™™™™™™™™™™  ™™™™™™™™™™™        */
    /*                ™™™™™™™™™™™                 ™™™™™™™™™™  ™™™™™™™™™™     ™™™™™™™™™™  ™™™™™™™™™™         */
    /*                ™™™™™™™™™™™                  ™™™™™™™™™™™™™™™™™™™™       ™™™™™™™™™™™™™™™™™™™™          */
    /*                ™™™™™™™™™™™                   ™™™™™™™™™™™™™™™™™™         ™™™™™™™™™™™™™™™™™™           */
    /*                ™™™™™™™™™™™                   ™™™™™™™™™™™™™™™™™™         ™™™™™™™™™™™™™™™™™™           */
    /*                ™™™™™™™™™™™                    ™™™™™™™™™™™™™™™™           ™™™™™™™™™™™™™™™™            */
    /*                ™™™™™™™™™™™                     ™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™             */
    /*                ™™™™™™™™™™™                     ™™™™™™™™™™™™™™             ™™™™™™™™™™™™™™             */
    /*                ™™™™™™™™™™™                      ™™™™™™™™™™™™               ™™™™™™™™™™™™              */

    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */
    /*                 MECHANISM FUNCTIONS                 */
    /* ™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™™ */

    /// @notice Buys a specific NFT using accumulated fees
    /// @param value Amount of ETH to spend on the NFT purchase
    /// @param data Calldata for the external marketplace call
    /// @param expectedId The token ID expected to be acquired
    /// @param target The marketplace contract to call
    /// @dev Protected against reentrancy, validates NFT acquisition
    function buyTargetNFT(
        uint256 value,
        bytes calldata data,
        uint256 expectedId,
        address target
    ) external override nonReentrant {
        // Store both balance and nft amount before calling external
        uint256 ethBalanceBefore = address(this).balance;
        uint256 nftBalanceBefore = collection.balanceOf(address(this));

        // Make sure we are not owner of the expected id
        if (collection.ownerOf(expectedId) == address(this)) {
            revert AlreadyNFTOwner();
        }

        // Ensure value is not more than currentFees
        if (value > currentFees) {
            revert NotEnoughEth();
        }

        // Ensure value doesn't exceed the time-based maximum price
        if (value > getMaxPriceForBuy()) {
            revert PriceTooHigh();
        }

        // Ensure target is not the collection itself
        if (target == address(collection)) revert InvalidTarget();

        // Call external
        (bool success, bytes memory reason) = target.call{value: value}(data);
        if (!success) {
            revert ExternalCallFailed(reason);
        }

        // Ensure we now have one more NFT
        uint256 nftBalanceAfter = collection.balanceOf(address(this));

        if (nftBalanceAfter != nftBalanceBefore + 1) {
            revert NeedToBuyNFT();
        }

        // Ensure we are now owner of expectedId
        if (collection.ownerOf(expectedId) != address(this)) {
            revert NotNFTOwner();
        }

        // Calculate actual cost of the NFT to base new price on
        uint256 cost = ethBalanceBefore - address(this).balance;
        currentFees -= cost;

        uint256 multiplier;
        if (priceMultiplier == 6900) {
            // Generate random number between 1.1x (1100) and 2.0x (2000) in 0.1x increments
            bytes32 hash = keccak256(
                abi.encodePacked(block.timestamp, msg.sender)
            );
            multiplier = 1100 + (uint256(hash) % 10) * 100;
        } else {
            multiplier = priceMultiplier;
        }

        // List NFT for sale at multiplier times the cost
        uint256 salePrice = (cost * multiplier) / 1000;
        nftForSale[expectedId] = salePrice;

        // Update last buy block to reset max price calculation
        lastBuyBlock = block.number;

        emit NFTBoughtByProtocol(expectedId, cost, salePrice);
    }
}
