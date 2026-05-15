// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {IFluxStaking} from "@interfaces/IFluxStaking.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {BaseStakingVault, State, SwapActionsState, BuyState} from "./BaseStakingVault.sol";

/**
 * @title FluxStakingVault
 * @author Decentra
 * @notice This contract facilitates the creation of Flux staking positions, accumulates rewards, and handles Flux token operations such as buying and staking.
 * @dev The contract interacts with multiple tokens (Inferno, Flux, and TitanX) and swaps between them for staking purposes. It utilizes the IFluxStaking interface for staking.
 */
contract FluxStakingVault is BaseStakingVault {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Immutable reference to the titanX token
    IERC20 public immutable titanX;

    /// @notice Immutable reference to the Inferno token
    IERC20 public immutable inferno;

    /// @notice Immutable reference to the Flux token
    IERC20 public immutable flux;

    /// @notice Address of the BNB holder
    address public immutable bnb;

    /// @notice Immutable address for the titanX staking manager
    address immutable titanXStakingManager;

    EnumerableSet.UintSet positionIds;

    /// @notice Tracks amount of titanX for restaking
    uint256 forRestaking;

    /// @notice Immutable reference to the Flux staking contract
    IFluxStaking public immutable fluxStaking;

    /// @notice Event emitted when a new staking position is created
    /// @param _id The ID of the staking position
    /// @param _amount The amount of Flux tokens staked
    event Staked(uint96 indexed _id, uint256 indexed _amount);

    /**
     * @notice Constructor to initialize the contract with the necessary addresses and configuration values.
     * @param _inferno Address of the Inferno token
     * @param _flux Address of the Flux token
     * @param _titanX Address of the titanX token
     * @param _bnb Address for the BNB holder
     * @param _fluxStaking Address of the Flux staking contract
     * @param _titanXStakingManager Address of the titanX staking vault
     * @param _state Initial swap actions state
     * @param _stakingCooldown Time (in seconds) between staking operations
     * @param _firstStakeMin Minimum amount of Flux required for the first stake
     */
    constructor(
        address _inferno,
        address _flux,
        address _titanX,
        address _bnb,
        address _fluxStaking,
        address _titanXStakingManager,
        SwapActionsState memory _state,
        uint24 _stakingCooldown,
        uint32 _startTimestamp,
        uint256 _firstStakeMin
    ) BaseStakingVault(_state, _stakingCooldown, _firstStakeMin) {
        titanX = IERC20(_titanX);
        flux = IERC20(_flux);
        bnb = _bnb;
        titanXStakingManager = _titanXStakingManager;

        state.incentive = 0.01e18; // 1%

        fluxStaking = IFluxStaking(_fluxStaking);
        inferno = IERC20(_inferno);

        flux.approve(address(fluxStaking), type(uint256).max);

        BuyState memory defaultState = BuyState({
            intervalBetween: 10 minutes,
            incentive: STAKING_INCENTIVE,
            swapCap: type(uint128).max,
            lastCallTs: _startTimestamp + (1 days - 10 minutes)
        });

        defaultState.swapCap = 1_353_400_000e18; // ~$700
        defaultState.incentive = 0.015e18; // 1.5%

        buyActionStates[address(titanX)] = defaultState;

        defaultState.swapCap = 440_054_000e18; // ~$360
        defaultState.incentive = 0.04e18; // 3% or 10.80

        buyActionStates[address(inferno)] = defaultState;
    }

    function buyinferno(uint32 _deadline) external onlyEOA notAmount0(erc20Bal(titanX)) {
        _buyAction(address(titanX), address(inferno), _deadline);
    }

    function buyFlux(uint32 _deadline) external onlyEOA notAmount0(erc20Bal(inferno)) {
        _buyAction(address(inferno), address(flux), _deadline);
    }

    function positions() external view returns (uint256[] memory) {
        return positionIds.values();
    }

    /**
     * @notice Stake Blaze tokens by swapping them through Inferno and Flux tokens, and then staking the Flux tokens.
     * @return id The ID of the new staking position
     * @notice Requires that either the cooldown has passed or the minimum amount was acumulated
     */
    function stake() external onlyByOwnerInPrivateMode returns (uint96 id) {
        State storage _state = state;

        uint256 fluxAmount = flux.balanceOf(_this());

        if (fluxAmount > _state.maxStakeAmount) fluxAmount = _state.maxStakeAmount;

        uint256 incentive = wmul(fluxAmount, state.incentive);
        fluxAmount -= incentive;

        require(_state.lastStakeTs != 0 || fluxAmount >= _state.minStakeAmount, CooldownNotPassed());
        require(
            block.timestamp - _state.lastStakeTs >= _state.stakingCooldown || fluxAmount >= _state.minStakeAmount,
            CooldownNotPassed()
        );

        fluxStaking.stake(fluxStaking.MAX_DURATION(), uint160(fluxAmount));
        flux.transfer(msg.sender, incentive);

        id = fluxStaking.tokenId();
        emit Staked(id, fluxAmount);

        positionIds.add(id);

        _state.lastStakeTs = uint32(block.timestamp);
        _state.lastStakingPosition++;
    }

    /**
     * @notice Unstakes Flux from the specified staking positions in batch.
     * @param _ids The array of staking position IDs to unstake.
     * @dev Loops through each provided position ID and unstakes the corresponding position.
     */
    function batchUnstake(uint160[] memory _ids) external onlyByOwnerInPrivateMode {
        State storage _state = state;
        uint256 totalUnstaked;
        for (uint160 i; i < _ids.length; ++i) {
            totalUnstaked += _unstake(_state, _ids[i]);
        }

        flux.transfer(msg.sender, wmul(totalUnstaked, state.incentive));
    }

    /**
     * @notice Internal function to unstake a specific staking position.
     * @param _id The staking position ID to unstake.
     * @return received Amount of Flux tokens received after unstaking.
     * @dev Updates rewards before unstaking and validates the position ID.
     */
    function _unstake(State storage, uint160 _id) internal notAmount0(_id) returns (uint256 received) {
        IFluxStaking.UserRecord memory record = fluxStaking.userRecords(_id);
        uint256 balanceBefore = flux.balanceOf(_this());

        uint256 titanXBalanceBefore = titanX.balanceOf(_this());

        if (record.endTime != 0) fluxStaking.unstake(uint160(_id), _this());

        positionIds.remove(_id);

        received = flux.balanceOf(_this()) - balanceBefore;
        _distribute(titanX.balanceOf(_this()) - titanXBalanceBefore);
    }

    /**
     * @notice Claim rewards for a batch of staking positions based on their IDs.
     * @param _ids Array of staking position IDs to claim rewards for.
     * @dev Ensures the claimable amount is greater than zero before claiming.
     */
    function claimRewards(uint160[] memory _ids)
        external
        notAmount0(fluxStaking.batchClaimableAmount(_ids))
        onlyByOwnerInPrivateMode
    {
        uint256 balanceBefore = titanX.balanceOf(_this());
        fluxStaking.batchClaim(_ids, _this());
        _distribute(titanX.balanceOf(_this()) - balanceBefore);
    }

    /**
     * @notice Internal function to distribute received tokens after claiming or unstaking.
     * @param _amountReceived The amount of tokens received from the staking or claim action.
     * @dev Distributes tokens based on whether the 8-week Flux staking period has passed.
     */
    function _distribute(uint256 _amountReceived) internal {
        if (_amountReceived == 0) return;

        uint256 incentive = wmul(_amountReceived, state.incentive);
        _amountReceived -= incentive;

        titanX.transfer(msg.sender, incentive);
        titanX.transfer(titanXStakingManager, wmul(_amountReceived, uint256(0.05e18)));
        titanX.transfer(bnb, wmul(_amountReceived, uint256(0.45e18)));
        titanX.transfer(GENESIS, wmul(_amountReceived, uint256(0.05e18)));
    }
}
