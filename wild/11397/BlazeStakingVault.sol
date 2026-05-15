// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {IERC20, IWETH9} from "@interfaces/IWETH.sol";
import {IBlazeStaking, IBlazeDiamonHands} from "@interfaces/IBlazeStaking.sol";
import {BaseStakingVault, State, SwapActionsState, BuyState} from "./BaseStakingVault.sol";

struct Tokens {
    address blaze;
    address weth;
    address titanX;
    address inferno;
}

/**
 * @title BlazeStakingVault
 * @author Decentra
 * @notice This contract manages Blaze token staking and claiming ETH rewards distribution.
 * @dev The contract interacts with Blaze staking, manages ETH (WETH) distribution, and enforces
 * staking cooldown periods.
 */
contract BlazeStakingVault is BaseStakingVault {
    uint256 constant BLAZE_MAX_STAKE = 2888; // Maximum Blaze stake amount

    IERC20 public immutable blaze;
    IERC20 immutable titanX;
    IERC20 immutable inferno;
    IBlazeDiamonHands public immutable diamondHands;
    IWETH9 public immutable weth;
    uint32 public immutable startTimestamp;
    IBlazeStaking public immutable blazeStaking;
    address immutable titanXStakingManager;
    address immutable phoenixBuyAndBurn;

    error InvalidPositionId();

    /// @notice Event emitted when ETH is distributed from the contract.
    /// @param ethAmount The amount of ETH distributed.
    event Distribution(uint256 indexed ethAmount);

    /// @notice Event emitted when a new staking position is created.
    /// @param _id The ID of the staking position.
    /// @param _amount The amount of BLAZE tokens staked.
    event Staked(uint96 indexed _id, uint256 indexed _amount);

    /**
     * @notice Initializes the BlazeStakingVault contract with required addresses and parameters.
     * @param _tokens The token used in the staking vault
     * @param _blazeStaking The address of the Blaze staking contract.
     * @param _bnb The address of the Phoenix Buy & Burn contract.
     * @param _stakingCooldown The cooldown period (in seconds) between staking events.
     * @param _firstStakeMin Minimum Blaze amount required for the first stake.
     * @dev Ensures the provided addresses and values are not zero, and assigns ownership to `_owner`.
     */
    constructor(
        Tokens memory _tokens,
        address _blazeStaking,
        address _bnb,
        uint32 _startTimestamp,
        address _titanXStakingManager,
        SwapActionsState memory _state,
        uint24 _stakingCooldown,
        uint80 _firstStakeMin
    )
        notAddress0(_tokens.blaze)
        notAddress0(_tokens.weth)
        notAddress0(_titanXStakingManager)
        notAddress0(_tokens.titanX)
        notAddress0(_tokens.inferno)
        notAddress0(_bnb)
        notAddress0(_blazeStaking)
        BaseStakingVault(_state, _stakingCooldown, _firstStakeMin)
    {
        inferno = IERC20(_tokens.inferno);
        weth = IWETH9(_tokens.weth);
        startTimestamp = _startTimestamp;
        blaze = IERC20(_tokens.blaze);
        titanXStakingManager = _titanXStakingManager;
        titanX = IERC20(_tokens.titanX);
        blazeStaking = IBlazeStaking(_blazeStaking);
        phoenixBuyAndBurn = _bnb;

        diamondHands = blazeStaking.getLastDistributionAddress();

        BuyState memory defaultState = BuyState({
            intervalBetween: 10 minutes,
            incentive: STAKING_INCENTIVE,
            swapCap: type(uint128).max,
            lastCallTs: _startTimestamp + (1 days - 10 minutes)
        });

        defaultState.swapCap = 0.25e18; // ~$1000

        buyActionStates[address(weth)] = defaultState;

        defaultState.swapCap = 1_353_400_000e18; // ~$700
        defaultState.incentive = 0.015e18; // 1.5%

        buyActionStates[address(titanX)] = defaultState;

        defaultState.swapCap = 440_054_000e18; // ~$360
        defaultState.incentive = 0.03e18; // 3% or 10.80

        buyActionStates[address(inferno)] = defaultState;

        blaze.approve(address(blazeStaking), type(uint256).max);
    }

    /**
     * @notice Allows the contract to receive Ether (ETH).
     * @dev All of the ETH will come from Blaze staking rewards.
     * Upon receiving ETH, the contract automatically distributes it according to the predefined logic.
     */
    receive() external payable {
        weth.deposit{value: address(this).balance}();
    }

    function buyTitanX(uint32 _deadline) external onlyEOA notAmount0(erc20Bal(weth)) {
        uint256 titanXReceived = _buyAction(address(weth), address(titanX), _deadline);

        if (block.timestamp - startTimestamp >= 110 days) {
            titanX.transfer(titanXStakingManager, wmul(titanXReceived, TO_TITAN_X_STAKING_VAULT));
            titanX.transfer(address(phoenixBuyAndBurn), wmul(titanXReceived, uint256(0.45e18)));
            titanX.transfer(GENESIS, wmul(titanXReceived, uint256(0.05e18)));
        }
    }

    function buyinferno(uint32 _deadline) external onlyEOA notAmount0(erc20Bal(titanX)) {
        _buyAction(address(titanX), address(inferno), _deadline);
    }

    function buyBlaze(uint32 _deadline) external onlyEOA notAmount0(erc20Bal(inferno)) {
        _buyAction(address(inferno), address(blaze), _deadline);
    }

    /**
     * @notice Stakes all accumulated Blaze tokens in the Blaze staking contract.
     * @dev Requires that either the cooldown has passed or the minimum amount was accumulated
     */
    function stakeBlaze() external onlyByOwnerInPrivateMode {
        State storage _state = state;

        uint256 blazeToStake = blaze.balanceOf(_this());

        if (blazeToStake > _state.maxStakeAmount) blazeToStake = _state.maxStakeAmount;

        uint256 incentive = wmul(blazeToStake, state.incentive);
        blazeToStake -= incentive;

        require(_state.lastStakeTs != 0 || blazeToStake >= _state.minStakeAmount, CooldownNotPassed());
        require(
            block.timestamp - _state.lastStakeTs >= _state.stakingCooldown || blazeToStake >= _state.minStakeAmount,
            CooldownNotPassed()
        );

        blazeStaking.stakeBlaze(blazeToStake, BLAZE_MAX_STAKE);

        if (blazeToStake >= 4000e18) diamondHands.participate();

        blaze.transfer(msg.sender, incentive);

        emit Staked(++_state.lastStakingPosition, blazeToStake);

        _state.lastStakeTs = uint32(block.timestamp);
    }

    /**
     * @notice Claims ETH rewards from the Blaze staking contract.
     * @dev This function forwards the claim request to the Blaze staking contract.
     * @dev This function will claim rewards in ETH which will trigger the receive function
     */
    function claimRewards() external onlyByOwnerInPrivateMode updateRewards {
        uint256 toClaim = blazeStaking.getAvailableRewardsForClaim(_this());
        require(toClaim != 0, NothingToClaim());

        if (diamondHands.getClaimableRewards(address(this)) != 0) {
            diamondHands.claimRewards();
        }

        blazeStaking.claimFeeRewards();

        weth.transfer(msg.sender, wmul(toClaim, state.incentive));
    }

    /// @dev Internal function to update rewards for all stakers.
    function _updateRewards() internal override {
        blazeStaking.distributeFeeRewardsForAll();
    }
}
