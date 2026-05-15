// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {SwapActions, SwapActionParams} from "@actions/SwapActions.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

struct State {
    uint32 lastBurnTs;
    uint32 intervalBetweenBurns;
    uint128 swapCap;
    uint64 incentive;
}

contract VoltBurn is SwapActions {
    ERC20Burnable immutable hyper;
    ERC20Burnable public immutable volt;

    uint256 public totalVoltSentToTreasury;

    State public state;

    event SentToVoltTreasury(uint256 indexed voltAmount);

    error IntervalWait();

    constructor(address _hyper, address _volt, SwapActionParams memory _s) SwapActions(_s) {
        hyper = ERC20Burnable(_hyper);
        volt = ERC20Burnable(_volt);

        state.intervalBetweenBurns = 10 minutes;
        state.swapCap = 1_000_000_000e18;
        state.incentive = 0.01e18;
    }

    function changeIntervalBetweenBurns(uint32 _newIntervalBetweenBurns)
        external
        onlyOwner
        notAmount0(_newIntervalBetweenBurns)
    {
        state.intervalBetweenBurns = _newIntervalBetweenBurns;
    }

    function changeIncentive(uint64 _newIncentive) external onlyOwner notGt(_newIncentive, WAD) {
        state.incentive = _newIncentive;
    }

    function changeSwapCap(uint128 _newCap) external onlyOwner notAmount0(_newCap) {
        state.swapCap = _newCap;
    }

    function buyNSendToVoltTreasury(uint32 _deadline)
        external
        notExpired(_deadline)
        onlyEOA
        notAmount0(erc20Bal(hyper))
    {
        State storage $ = state;

        require(block.timestamp - $.intervalBetweenBurns >= $.lastBurnTs, IntervalWait());
        uint256 balance = erc20Bal(hyper);

        if (balance > $.swapCap) balance = $.swapCap;

        uint256 incentive = wmul(balance, $.incentive);

        balance -= incentive;

        uint256 voltAmount = swapExactInput(address(hyper), address(volt), balance, 0, _deadline);

        emit SentToVoltTreasury(voltAmount);

        volt.transfer(VOLT_TREASURY, voltAmount);
        hyper.transfer(msg.sender, incentive);

        totalVoltSentToTreasury += voltAmount;
        $.lastBurnTs = uint32(block.timestamp);
    }

    function erc20Bal(ERC20Burnable t) internal view returns (uint256) {
        return t.balanceOf(address(this));
    }
}
