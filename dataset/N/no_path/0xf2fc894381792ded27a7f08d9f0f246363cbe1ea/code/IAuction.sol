// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMatrixAuction {
    /**
     * @notice Represents daily statistics for Matrix emissions and TITAN-X deposits.
     * @param matrixEmitted Amount of Matrix emitted for this day.
     * @param titanXDeposited Total TITAN-X deposited on this day.
     */
    struct DailyStatistic {
        uint128 matrixEmitted;
        uint128 titanXDeposited;
    }

    /**
     * @notice Details of a user's deposit in the MatrixAuction.
     * @param amount Amount of TITAN-X deposited.
     * @param depositedAt Timestamp when the deposit was made.
     */
    struct UserDeposit {
        uint224 amount;
        uint32 depositedAt;
    }

    /**
     * @notice Structure for liquidity position details.
     * @param hasLP Indicates if liquidity has been added.
     * @param tokenId The identifier for the liquidity position.
     * @param isMatrixToken0 Whether Matrix token is the first token in the liquidity pool.
     */
    struct LP {
        bool hasLP;
        uint240 tokenId;
        bool isMatrixToken0;
    }

    /// @notice Emitted when liquidity is added to the HYPER/MATRIX pool
    /// @param deadline The deadline for adding liquidity
    event LiquidityAdded(uint32 deadline);

    event DepositExecuted(address user, uint96 depositId, uint256 titanXAmount);

    /// @notice Emitted when a user executes a claim
    /// @param user The address of the user who claimed MATRIX tokens
    /// @param id The deposit id during which the claim was executed
    /// @param amount Amount of matrix claimed
    /// @param incentivePoolBonusAmount Amount of additional matrix from the incentive pool
    event ClaimExecuted(
        address indexed user, uint96 indexed id, uint256 indexed amount, uint256 incentivePoolBonusAmount
    );

    /// @notice Emitted when a distribution is made
    /// @param toBnbAndMatrixVault The amount distributed to the Matrix Vault/BNB
    /// @param toGenesis The amount distributed to Genesis
    /// @param toLiquidityBonding The amount distributed to the liquidity bonding pool
    /// @param toDragonX The amount distributed to DragonX
    /// @param toPhoenixVault The amount distributed to phoenix vault
    event Distribution(
        uint256 toBnbAndMatrixVault,
        uint256 toGenesis,
        uint256 toLiquidityBonding,
        uint256 toDragonX,
        uint256 toPhoenixVault
    );

    /* ==== ERRORS ==== */

    /// @notice Error thrown when a function call is made with an expired deadline
    error NotExpired();

    /// @notice Error thrown when trying to deposit before the minting has started
    error NotStartedYet();

    /// @notice Error thrown when attempting to claim before the deposit is mature
    error DepositNotMatureYet();

    /// @notice Error thrown when trying to claim but there is nothing to claim
    error NothingToClaim();

    /// @notice Error thrown when the auction has ended
    error AuctionEnded();

    /// @notice Error thrown when liquidity has already been added
    error LiquidityAlreadyAdded();

    /// @notice Error thrown when there isn't enough TitanX for liquidity
    error NotEnoughTitanXForLiquidity();

    /**
     * @return The next available deposit ID.
     */
    function depositId() external view returns (uint96);

    /**
     * @return Total Matrix tokens claimed by users.
     */
    function totalMatrixClaimed() external view returns (uint256);

    /**
     * @return Total Matrix tokens that are yet to be claimed.
     */
    function totalUnclaimedMatrix() external view returns (uint256);

    /**
     * @return Total Matrix tokens in the patience pool.
     */
    function totalMatrixInPatiencePool() external view returns (uint256);

    /**
     * @return Total unlocked Matrix tokens in the patience pool.
     */
    function totalUnlockedMatrixInPatiencePool() external view returns (uint256);

    /**
     * @return Total amount of patience pool tokens that have been claimed.
     */
    function patiencePoolAmountClaimed() external view returns (uint256);

    /**
     * @notice Changes the buy and burn allocation when distributing titanX from the auction.
     * @param _newBnbAllocation The new percentage bnb allocation the auction to use.
     */
    function changeBnBAllocation(uint64 _newBnbAllocation) external;

    /**
     * @notice Adds liquidity to the Hyper-Matrix pool.
     * @param _deadline The deadline by which this transaction must be included in a block.
     * @param _slippage The min amount of LP in WAD
     */
    function addLiquidityToHyperMatrixPool(uint32 _deadline, uint64 _slippage) external;

    /**
     * @notice Allows a user to deposit TITAN-X tokens.
     * @param _amount The amount of TITAN-X to deposit.
     */
    function deposit(uint224 _amount) external;

    /**
     * @notice Deposits ETH which is swapped for TITAN-X and then deposited.
     * @param _amountTitanXMin The minimum amount of TITAN-X to receive from the swap.
     * @param _deadline The deadline by which the swap must occur.
     */
    function depositEth(uint256 _amountTitanXMin, uint32 _deadline) external payable;

    /**
     * @notice Claims Matrix tokens for a specific deposit.
     * @param _id The ID of the deposit to claim rewards for.
     */
    function claim(uint96 _id) external;

    /**
     * @notice Claims fees from uniswap v3 position
     * @return hyperAmount The hyper amount claimed from uniswapv3 position fees
     * @return matrixAmount The matrix amount claimed from uniswapv3 position fees
     */
    function collectFees() external returns (uint256 hyperAmount, uint256 matrixAmount);

    /**
     * @notice Claims matrix tokens for multiple ids
     * @param _ids The ids of the deposits to claim
     */
    function batchClaim(uint96[] calldata _ids) external;

    /**
     * @notice Calculates the amount of Matrix that can be claimed for a user's deposit.
     * @param _user Address of the user.
     * @param _id The ID of the deposit to calculate for.
     * @return claimable The amount of Matrix claimable.
     * @return patiencePooBonus Additional bonus from the patience pool.
     */
    function claimableAmount(address _user, uint96 _id)
        external
        view
        returns (uint256 claimable, uint256 patiencePooBonus);

    /**
     * @notice Calculates the amount of Matrix that can be claimed for a multiple users deposits.
     * @param _user Address of the user.
     * @param _ids The ids of the deposits to calculate for.
     * @return claimable The amount of Matrix claimable.
     * @return patiencePooBonus Additional bonus from the patience pool.
     */
    function batchClaimableAmount(address _user, uint96[] calldata _ids)
        external
        view
        returns (uint256 claimable, uint256 patiencePooBonus);

    /**
     * @notice Returns the total unlocked matrix in patience pool up-to current date
     */
    function totalMatrixUnlockedInPatiencePool() external returns (uint256 totalPoolAmount);

    /**
     * @notice Distributes Matrix tokens to the patience incentive pool.
     * @param _amount The amount of Matrix tokens to distribute.
     */
    function distributeToPatienceIncentivePool(uint256 _amount) external;
}
