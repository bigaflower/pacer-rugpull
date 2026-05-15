// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {IERC20} from "@interfaces/IWETH.sol";
import {SwapActions, SwapActionsState} from "@actions/SwapActions.sol";

struct State {
    uint24 stakingCooldown; // < Cooldown period for creating the next staking position
    uint32 lastStakeTs; // < Timestamp of the last staking position creation
    uint16 lastStakingPosition; // < Counter for staking positions (max 65535 weeks ~ 458,745 days)
    uint256 minStakeAmount; // < Minimum amount of TOKEN required for the stake
    uint256 maxStakeAmount; // Maximum amount of Token required for the stake
    bool privateMode; // < When toggled only the owner can call the functions
    uint256 incentive; // < The incentive percentage used
}

struct BuyState {
    uint32 lastCallTs;
    uint32 intervalBetween;
    uint128 swapCap;
    uint64 incentive;
}

/// @author Decentra
contract BaseStakingVault is SwapActions {
    State public state;

    mapping(address inputToken => BuyState) public buyActionStates;

    error CooldownNotPassed();
    error OnlyPermissionedInPrivateMode();
    error IntervalWait();
    error NothingToClaim();

    /**
     * @notice Emitted when a buy action is executed, swapping an input token for an output token.
     * @param inputToken The address of the input token used in the swap.
     * @param outputToken The address of the output token received from the swap.
     * @param outputAmount The amount of the output token received from the swap.
     */
    event BuyAction(address indexed inputToken, address indexed outputToken, uint256 indexed outputAmount);

    modifier onlyByOwnerInPrivateMode() {
        _onlyByOwnerInPrivateMode();
        _;
    }

    /**
     * @dev Updates rewards for staking before executing the function.
     */
    modifier updateRewards() {
        _updateRewards();
        _;
    }

    constructor(SwapActionsState memory _state, uint24 _stakingCooldown, uint256 _firstStakeMin) SwapActions(_state) {
        state.stakingCooldown = _stakingCooldown;
        state.minStakeAmount = _firstStakeMin;
        state.maxStakeAmount = type(uint256).max;

        state.incentive = STAKING_INCENTIVE;
    }

    /**
     * @notice Changes the minimum TOKEN required for the first stake.
     * @param _minStakeAmount The new minimum amount required.
     * @dev Only the contract owner can call this function.
     */
    function changeMinStakeAmount(uint256 _minStakeAmount) external onlyOwner notAmount0(_minStakeAmount) {
        state.minStakeAmount = _minStakeAmount;
    }

    /**
     * @notice Changes the incentive percentage.
     * @param _incentive The new incentive percentage.
     * @dev Only the contract owner can call this function.
     */
    function changeIncentive(uint64 _incentive) external onlyOwner notGt(_incentive, WAD) {
        state.incentive = _incentive;
    }

    function changeBuyActionState(address _inputToken, BuyState memory _s)
        external
        notGt(_s.incentive, WAD)
        notAmount0(_s.intervalBetween)
        notAmount0(_s.swapCap)
        onlyOwner
    {
        require(_s.lastCallTs == buyActionStates[_inputToken].lastCallTs);
        buyActionStates[_inputToken] = _s;
    }

    /**
     * @notice Changes the minimum TOKEN required for the first stake.
     * @param _newMaxStakeAmount The new maximum amount.
     * @dev Only the contract owner can call this function.
     */
    function changeMaxStakeAmount(uint256 _newMaxStakeAmount) external onlyOwner notAmount0(_newMaxStakeAmount) {
        state.maxStakeAmount = _newMaxStakeAmount;
    }

    /**
     * @notice Toggles private mode
     * @param _state The boleean value to set the variable to
     */
    function togglePrivateMode(bool _state) external onlyOwner {
        state.privateMode = _state;
    }

    /**
     * @notice Changes the staking cooldown period.
     * @param _newCooldown The new cooldown period (in seconds).
     * @dev Only the contract owner can call this function.
     */
    function changeStakingCooldown(uint24 _newCooldown) external onlyOwner {
        state.stakingCooldown = _newCooldown;
    }

    function _this() internal view returns (address) {
        return address(this);
    }

    function _onlyByOwnerInPrivateMode() internal view {
        require(
            !state.privateMode || (msg.sender == owner() || msg.sender == slippageAdmin),
            OnlyPermissionedInPrivateMode()
        );
    }

    function erc20Bal(IERC20 t) internal view returns (uint256) {
        return t.balanceOf(address(this));
    }

    function _buyAction(address inputToken, address outputToken, uint32 _deadline)
        internal
        returns (uint256 outputAmount)
    {
        BuyState storage $ = buyActionStates[address(inputToken)];

        require(block.timestamp - $.intervalBetween >= $.lastCallTs, IntervalWait());
        uint256 balance = erc20Bal(IERC20(inputToken));

        if (balance > $.swapCap) balance = $.swapCap;

        uint256 incentive = wmul(balance, $.incentive);

        balance -= incentive;

        outputAmount = swapExactInputV3(inputToken, outputToken, balance, _deadline);

        IERC20(inputToken).transfer(msg.sender, incentive);

        emit BuyAction(inputToken, outputToken, outputAmount);

        $.lastCallTs = uint32(block.timestamp);
    }

    function _unstake(State storage _state, uint16 _id) internal virtual returns (uint256) {}

    /**
     * @dev Internal function to update rewards for all stakers.
     */
    function _updateRewards() internal virtual {}
}
