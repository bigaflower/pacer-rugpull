// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {Phoenix} from "@core/Phoenix.sol";
import {SwapActions, SwapActionsState} from "@actions/SwapActions.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

struct State {
    uint32 lastBurnTs;
    uint32 intervalBetweenBurns;
    uint128 swapCap;
    uint64 incentive;
}

/// @author Decentra
contract PhoenixBuyAndBurn is SwapActions {
    Phoenix immutable phoenix;
    ERC20Burnable immutable inferno;
    ERC20Burnable immutable titanX;

    State public state;

    uint256 public totalPhoenixBurnt;

    event BuyAndBurn(uint256 indexed phoenixAmount, uint256 indexed infernoAmount);

    error IntervalWait();

    constructor(address _phoenix, address _inferno, address _titanX, SwapActionsState memory _s) SwapActions(_s) {
        phoenix = Phoenix(_phoenix);
        inferno = ERC20Burnable(_inferno);
        titanX = ERC20Burnable(_titanX);

        state.intervalBetweenBurns = 10 minutes;
        state.incentive = BUY_AND_BURN_INCENTIVE;
    }

    function changeIntervalBetweenBurns(uint32 _newIntervalBetweenBurns)
        external
        onlyOwner
        notAmount0(_newIntervalBetweenBurns)
    {
        state.intervalBetweenBurns = _newIntervalBetweenBurns;
    }

    function changeIncentive(uint64 _newIncentive) external onlyOwner notGt(_newIncentive, 0.1e18) {
        state.incentive = _newIncentive;
    }

    function changeSwapCap(uint128 _newCap) external onlyOwner {
        state.swapCap = _newCap;
    }

    function buyNBurn(uint32 _deadline) external notExpired(_deadline) onlyEOA notAmount0(erc20Bal(titanX)) {
        State storage $ = state;

        require(block.timestamp - $.intervalBetweenBurns >= $.lastBurnTs, IntervalWait());
        uint256 balance = erc20Bal(titanX);

        if (balance > $.swapCap) balance = $.swapCap;

        uint256 incentive = wmul(balance, $.incentive);

        balance -= incentive;

        uint256 infernoAmount = swapExactInputV3(address(titanX), address(inferno), balance, _deadline);
        uint256 phoenixAmount = swapExactInputV3(address(inferno), address(phoenix), infernoAmount, _deadline);

        phoenix.transfer(phoenix.auctionTreasury(), wmul(phoenixAmount, uint256(0.5e18)));

        burnPhoenix();
        titanX.transfer(msg.sender, incentive);

        emit BuyAndBurn(phoenixAmount, balance);

        $.lastBurnTs = uint32(block.timestamp);
    }

    function burnPhoenix() public {
        uint256 toBurn = erc20Bal(phoenix);
        totalPhoenixBurnt += toBurn;

        phoenix.burn(toBurn);
    }

    function erc20Bal(ERC20Burnable t) internal view returns (uint256) {
        return t.balanceOf(address(this));
    }
}
