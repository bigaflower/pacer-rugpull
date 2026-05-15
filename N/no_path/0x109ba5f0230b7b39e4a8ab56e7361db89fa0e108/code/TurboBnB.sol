// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {Time} from "@utils/Time.sol";
import {Turbo} from "@core/Turbo.sol";
import {wmul, min} from "@utils/Math.sol";
import {SwapActions, SwapActionParams} from "@actions/SwapActions.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title TurboBuyAndBurn
 */
contract TurboBuyAndBurn is SwapActions {
    using SafeERC20 for *;

    /// @notice Struct to represent intervals for burning
    struct Interval {
        uint128 amountAllocated;
        uint128 amountBurned;
    }

    ///@notice The startTimestamp
    uint32 public immutable startTimeStamp;
    Turbo immutable turbo;
    ERC20Burnable public immutable hyper;

    /// @notice Timestamp of the last burn call
    uint32 public lastBurnedIntervalStartTimestamp;

    /// @notice Last interval number
    uint32 public lastIntervalNumber;

    /// @notice That last snapshot timestamp
    uint32 lastSnapshot;

    /// @notice Total turbo burnt by this contract
    uint256 public totalTurboBurnt;

    /// @notice Maximum amount of Hyper to be swapped and then burned
    uint128 public swapCap;

    /// @notice The last burned interval
    uint256 public lastBurnedInterval;

    /// @notice Mapping from interval number to Interval struct
    mapping(uint32 interval => Interval) public intervals;

    /// @notice Total Hyper tokens distributed
    uint256 public totalHyperDistributed;

    /// @notice Event emitted when tokens are bought and burnt
    event BuyAndBurn(uint256 indexed hyperAmount, uint256 indexed turboAmount, address indexed caller);

    error NotStartedYet();
    error IntervalAlreadyBurned();

    constructor(uint32 startTimestamp, address _hyper, address _turbo, SwapActionParams memory _params)
        SwapActions(_params)
    {
        startTimeStamp = startTimestamp;

        turbo = Turbo(_turbo);

        hyper = ERC20Burnable(_hyper);

        swapCap = type(uint128).max;
    }

    /// @notice Updates the contract state for intervals
    modifier intervalUpdate() {
        _intervalUpdate();
        _;
    }

    function setSwapCap(uint128 _newCap) external onlySlippageAdminOrOwner {
        swapCap = _newCap == 0 ? type(uint128).max : _newCap;
    }

    function getCurrentInterval()
        public
        view
        returns (
            uint32 _lastInterval,
            uint128 _amountAllocated,
            uint16 _missedIntervals,
            uint32 _lastIntervalStartTimestamp,
            uint256 beforeCurrday,
            bool updated
        )
    {
        uint32 startPoint = lastBurnedIntervalStartTimestamp == 0 ? startTimeStamp : lastBurnedIntervalStartTimestamp;
        uint32 timeElapseSinceLastBurn = Time.blockTs() - startPoint;

        if (lastBurnedIntervalStartTimestamp == 0 || timeElapseSinceLastBurn > INTERVAL_TIME) {
            (_lastInterval, _amountAllocated, _missedIntervals, beforeCurrday) =
                _calculateIntervals(timeElapseSinceLastBurn);

            _lastIntervalStartTimestamp = startPoint;
            _missedIntervals += timeElapseSinceLastBurn > INTERVAL_TIME && lastBurnedIntervalStartTimestamp != 0 ? 1 : 0;
            updated = true;
        }
    }

    /**
     * @notice Swaps Hyper for TURBO and disitributes the TURBO tokens
     * @param _deadline The deadline for which the passes should pass
     */
    function swapHyperToTurboAndBurn(uint32 _deadline) external intervalUpdate notExpired(_deadline) {
        require(msg.sender == tx.origin, OnlyEOA());

        Interval storage currInterval = intervals[lastIntervalNumber];
        require(currInterval.amountBurned == 0, IntervalAlreadyBurned());

        if (currInterval.amountAllocated > swapCap) currInterval.amountAllocated = swapCap;

        currInterval.amountBurned = currInterval.amountAllocated;

        uint256 incentive = wmul(currInterval.amountAllocated, INCENTIVE_FEE);

        uint256 hyperToSwapAndBurn = currInterval.amountAllocated - incentive;

        uint256 turboAmount = swapExactInput(address(hyper), address(turbo), hyperToSwapAndBurn, 0, _deadline);

        {
            ///@note - Allocations
            turbo.transfer(LIQUIDITY_BONDING_ADDR, wmul(turboAmount, uint256(0.08e18)));
            turbo.transfer(address(turbo.treasury()), wmul(turboAmount, uint256(0.5e18)));
            burnTurbo();
        }

        hyper.safeTransfer(msg.sender, incentive);

        lastBurnedInterval = lastIntervalNumber;

        emit BuyAndBurn(hyperToSwapAndBurn, turboAmount, msg.sender);
    }

    /**
     * @notice Distributes Hyper tokens for burning
     * @param _amount The amount of Hyper tokens
     */
    function distributeHyperForBurning(uint256 _amount) external notAmount0(_amount) {
        hyper.safeTransferFrom(msg.sender, address(this), _amount);

        if (Time.blockTs() > startTimeStamp && Time.blockTs() - lastBurnedIntervalStartTimestamp > INTERVAL_TIME) {
            _intervalUpdate();
        }
    }

    function burnTurbo() public {
        uint256 turboToBurn = turbo.balanceOf(address(this));

        totalTurboBurnt = totalTurboBurnt + turboToBurn;
        turbo.burn(turboToBurn);
    }

    function getDailyHyperAllocation(uint32 t) public view returns (uint256 dailyWadAllocation) {
        uint256 STARTING_ALOCATION = 0.24e18;
        uint256 MIN_ALOCATION = 0.15e18;
        uint256 daysSinceStart = Time.dayGap(startTimeStamp, t);

        dailyWadAllocation = daysSinceStart >= 10 ? MIN_ALOCATION : STARTING_ALOCATION - (daysSinceStart * 0.01e18);
    }

    function _calculateIntervals(uint256 timeElapsedSince)
        internal
        view
        returns (
            uint32 _lastIntervalNumber,
            uint128 _totalAmountForInterval,
            uint16 missedIntervals,
            uint256 beforeCurrDay
        )
    {
        missedIntervals = _calculateMissedIntervals(timeElapsedSince);

        _lastIntervalNumber = lastIntervalNumber + missedIntervals + 1;

        uint32 currentDay = Time.dayGap(startTimeStamp, uint32(block.timestamp));

        uint32 dayOfLastInterval = lastBurnedIntervalStartTimestamp == 0
            ? currentDay
            : Time.dayGap(startTimeStamp, lastBurnedIntervalStartTimestamp);

        if (currentDay == dayOfLastInterval) {
            uint256 dailyAllocation = wmul(totalHyperDistributed, getDailyHyperAllocation(Time.blockTs()));

            uint128 _amountPerInterval = uint128(dailyAllocation / INTERVALS_PER_DAY);

            uint128 additionalAmount = _amountPerInterval * missedIntervals;

            _totalAmountForInterval = _amountPerInterval + additionalAmount;
        } else {
            uint32 _lastBurnedIntervalStartTimestamp = lastBurnedIntervalStartTimestamp;

            uint32 theEndOfTheDay = Time.getDayEnd(_lastBurnedIntervalStartTimestamp);

            uint256 balanceOf = hyper.balanceOf(address(this));

            while (currentDay >= dayOfLastInterval) {
                uint32 end = uint32(Time.blockTs() < theEndOfTheDay ? Time.blockTs() : theEndOfTheDay - 1);

                uint32 accumulatedIntervalsForTheDay = (end - _lastBurnedIntervalStartTimestamp) / INTERVAL_TIME;

                uint256 diff = balanceOf > _totalAmountForInterval ? balanceOf - _totalAmountForInterval : 0;

                //@note - If the day we are looping over the same day as the last interval's use the cached allocation, otherwise use the current balance
                uint256 forAllocation = Time.dayGap(startTimeStamp, lastBurnedIntervalStartTimestamp)
                    == dayOfLastInterval
                    ? totalHyperDistributed
                    : balanceOf >= _totalAmountForInterval + wmul(diff, getDailyHyperAllocation(end)) ? diff : 0;

                uint256 dailyAllocation = wmul(forAllocation, getDailyHyperAllocation(end));

                ///@notice ->  minus INTERVAL_TIME minutes since, at the end of the day the new epoch with new allocation
                _lastBurnedIntervalStartTimestamp = theEndOfTheDay - INTERVAL_TIME;

                ///@notice ->  plus INTERVAL_TIME minutes to flip into the next day
                theEndOfTheDay = Time.getDayEnd(_lastBurnedIntervalStartTimestamp + INTERVAL_TIME);

                if (dayOfLastInterval == currentDay) beforeCurrDay = _totalAmountForInterval;

                _totalAmountForInterval +=
                    uint128((dailyAllocation * accumulatedIntervalsForTheDay) / INTERVALS_PER_DAY);

                dayOfLastInterval++;
            }
        }

        Interval memory prevInt = intervals[lastIntervalNumber];

        //@note - If the last interval was only updated, but not burned add its allocation to the next one.
        uint128 additional = prevInt.amountBurned == 0 ? prevInt.amountAllocated : 0;

        if (_totalAmountForInterval + additional > hyper.balanceOf(address(this))) {
            _totalAmountForInterval = uint128(hyper.balanceOf(address(this)));
        } else {
            _totalAmountForInterval += additional;
        }
    }

    function _calculateMissedIntervals(uint256 timeElapsedSince) internal view returns (uint16 _missedIntervals) {
        _missedIntervals = uint16(timeElapsedSince / INTERVAL_TIME);

        if (lastBurnedIntervalStartTimestamp != 0) _missedIntervals--;
    }

    function _updateSnapshot(uint256 deltaAmount) internal {
        if (Time.blockTs() < startTimeStamp || lastSnapshot + 24 hours > Time.blockTs()) return;

        uint32 timeElapsed = Time.blockTs() - startTimeStamp;

        uint32 snapshots = timeElapsed / 24 hours;

        uint256 balance = hyper.balanceOf(address(this));

        totalHyperDistributed = deltaAmount > balance ? 0 : balance - deltaAmount;
        lastSnapshot = startTimeStamp + (snapshots * 24 hours);
    }

    /// @notice Updates the contract state for intervals
    function _intervalUpdate() private {
        require(Time.blockTs() >= startTimeStamp, NotStartedYet());

        if (lastSnapshot == 0) _updateSnapshot(0);

        (
            uint32 _lastInterval,
            uint128 _amountAllocated,
            uint16 _missedIntervals,
            uint32 _lastIntervalStartTimestamp,
            uint256 beforeCurrentDay,
            bool updated
        ) = getCurrentInterval();

        _updateSnapshot(beforeCurrentDay);

        if (updated) {
            lastBurnedIntervalStartTimestamp = _lastIntervalStartTimestamp + (uint32(_missedIntervals) * INTERVAL_TIME);
            intervals[_lastInterval] = Interval({amountAllocated: _amountAllocated, amountBurned: 0});
            lastIntervalNumber = _lastInterval;
        }
    }
}
