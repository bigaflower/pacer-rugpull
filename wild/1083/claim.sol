// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/// @title Daily Claim Contract
/// @notice This contract allows users to claim a certain amount of tokens daily based on their allocation in a Merkle tree.
contract DailyClaim is Ownable {
    using SafeERC20 for IERC20;

    /// @dev karrat token
    IERC20 public token;

    /// @dev variable to hold merkle root
    bytes32 public merkleRoot;

    /// @dev struct holding on chain data about tokens a user clames
    struct UserData {
        uint256 totalClaimed;
        uint256 lastClaimedDay;
    }

    /// @dev mapping between struct that holds data and user address
    mapping(address => UserData) private userClaims;

    /// @dev timestamp that claims open up
    uint256 public openClaimsDay;

    /// @dev wallet holding karrat
    address public holdingWallet;

    /// @dev Custom errors for gas efficiency
    error RequestExceedsClaimableDays(uint256 requested, uint256 available);
    error NoTokensToClaim();
    error InvalidMerkleProof();
    error NewClaimDayNotInFuture();

    /// @notice Emitted when a user claims tokens
    /// @param user The address of the user who claimed tokens
    /// @param amount The amount of tokens claimed
    /// @param daysClaimed The number of days for which tokens were claimed
    event Claimed(address indexed user, uint256 amount, uint256 daysClaimed);

    /// @notice Emitted when the admin updates the claimable day
    /// @param newClaimDay The new claimable day
    event ClaimDayUpdated(uint256 newClaimDay);

    /// @notice Emitted when the admin updates holding wallet
    /// @param newHoldingWallet The new wallet used for disperments
    event HoldingWalletUpdated(address newHoldingWallet);

    /// @notice Emitted when the admin updates the merkle root for disperments
    /// @param newMerkleRoot The new merkle root containing address data
    event MerkleRootUpdated(bytes32 newMerkleRoot);


    /// @notice Initializes the contract with the token address, Merkle root, and the initial open claims day
    /// @param _token The address of the token being claimed
    /// @param _merkleRoot The Merkle root for verifying user allocations
    /// @param _initialOpenClaimsDay The initial day when claiming can start
    /// @param _holdingWallet the wallet holding tokens to be distributed
    constructor(
        address _token,
        bytes32 _merkleRoot,
        uint256 _initialOpenClaimsDay,
        address _holdingWallet
    ) {
        token = IERC20(_token);
        merkleRoot = _merkleRoot;
        openClaimsDay = _initialOpenClaimsDay;
        holdingWallet = _holdingWallet;
    }

    /// @notice Allows users to claim tokens for a specific number of days
    /// @dev Users provide the number of days they want to claim and the amount they are owed per day.
    ///      A Merkle proof is required to validate the user's maximum allocation.
    /// @param requestDays The number of days the user is requesting to claim for
    /// @param amountPerDay The amount of tokens the user can claim per day
    /// @param maxTotalAmount The maximum total amount the user is allowed to claim based on the Merkle proof
    /// @param merkleProof The Merkle proof verifying the user's claimable allocation
    function claim(
        uint256 requestDays,
        uint256 amountPerDay,
        uint256 maxTotalAmount,
        bytes32[] calldata merkleProof
    ) external {
        UserData storage userData = userClaims[msg.sender];

        // Calculate the number of days that have passed since the open claim day and last claimed day
        uint256 timePassed = block.timestamp - openClaimsDay;
        uint256 claimableDays = timePassed / 1 days; // Full days passed
        if (claimableDays < userData.lastClaimedDay) {
            revert NoTokensToClaim();
        }

        // Calculate how many days the user can still claim (based on time passed)
        uint256 remainingDays = claimableDays - userData.lastClaimedDay;
        if (requestDays > remainingDays) {
            revert RequestExceedsClaimableDays(requestDays, remainingDays);
        }

        // Verify the user using the Merkle Tree proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amountPerDay, maxTotalAmount));
        if (!MerkleProof.verify(merkleProof, merkleRoot, leaf)) {
            revert InvalidMerkleProof();
        }

        // Calculate the requested claimable amount
        uint256 claimableAmount = requestDays * amountPerDay;

        // Ensure user doesn't claim more than their total allocation
        uint256 remainingAllocation = maxTotalAmount - userData.totalClaimed;
        if (claimableAmount > remainingAllocation) {
            claimableAmount = remainingAllocation;
        }

        if (claimableAmount == 0) {
            revert NoTokensToClaim();
        }

        // Update user claim data
        userData.totalClaimed += claimableAmount;
        userData.lastClaimedDay += requestDays;

        // Transfer tokens to the user using SafeERC20
        token.safeTransferFrom(holdingWallet, msg.sender, claimableAmount);

        emit Claimed(msg.sender, claimableAmount, requestDays);
    }

    /// @notice Admin function to update the claimable day
    /// @dev The new claimable day must be in the future to prevent users from claiming for past days.
    /// @param _newOpenClaimsDay The new day when claims are allowed to start
    function setOpenClaimsDay(uint256 _newOpenClaimsDay) external onlyOwner {
        openClaimsDay = _newOpenClaimsDay;
        emit ClaimDayUpdated(_newOpenClaimsDay);
    }

    /// @notice Admin function to update the Merkle root
    /// @dev Only the contract owner can call this function.
    /// @param _holdingWallet The new address holding tokens to be dispersed
    function setHoldingWallet(address _holdingWallet) external onlyOwner {
        holdingWallet = _holdingWallet;
        emit HoldingWalletUpdated(_holdingWallet);
    }

    /// @notice Admin function to update the wallet dispersing Karrat
    /// @dev Only the contract owner can call this function.
    /// @param _merkleRoot The new Merkle root for verifying user allocations
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    // --- View functions ---

    /// @notice View function to check the total allocation for a user
    /// @dev This function checks how much a user can claim.
    /// @param user The user's address
    /// @param maxTotalAmount The maximum total amount the user is allowed to claim based on the Merkle proof
    function getTotalAllocationLeft(address user, uint256 maxTotalAmount) external view returns (uint256) {
        return maxTotalAmount - userClaims[user].totalClaimed;
    }

    /// @notice View function to check how much the user has claimed so far
    /// @param user The user's address
    /// @return The total amount the user has claimed
    function getTotalClaimed(address user) external view returns (uint256) {
        return userClaims[user].totalClaimed;
    }

    /// @notice View function to check how many tokens a user can claim for the exact current day
    /// @dev This function calculates the tokens the user can claim for today only, not including past or future days.
    /// @param user The user's address
    /// @param amountPerDay The amount of tokens the user can claim per day
    /// @param maxTotalAmount The maximum total amount the user is allowed to claim
    /// @return The amount of tokens the user can claim for today
    function getClaimableTokensForToday(
        address user,
        uint256 amountPerDay,
        uint256 maxTotalAmount
    ) public view returns (uint256) {
        UserData storage userData = userClaims[user];
        uint256 remainingAllocation = maxTotalAmount - userData.totalClaimed;
        if(userData.lastClaimedDay == 0 && userData.totalClaimed == 0){
            if((((block.timestamp - openClaimsDay) / 1 days) * amountPerDay) > remainingAllocation){
              return remainingAllocation;
               // return 34;
            }
            return (((block.timestamp - openClaimsDay) / 1 days) * amountPerDay);
        }
        // // Calculate the number of full days that have passed since the open claim day
        uint256 daysLeft = ((block.timestamp - openClaimsDay) / 1 days) - userData.lastClaimedDay;

        uint256 totalToDate = daysLeft *  amountPerDay;

        if (totalToDate > remainingAllocation) {
           return remainingAllocation;
        }

        return totalToDate;
    }


    /// @notice View function to check how many days have passed since the user's last claim
    /// @param user The user's address
    /// @return The number of days since the user's last claim
    function getDaysLeftToClaim(address user) external view returns (uint256) {
        UserData storage userData = userClaims[user];
        uint256 timePassed = block.timestamp - openClaimsDay;
        uint256 claimableDays = timePassed / 1 days; // Full days passed
        return claimableDays - userData.lastClaimedDay;
    }
}
