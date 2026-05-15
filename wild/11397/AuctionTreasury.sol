// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {Phoenix} from "./Phoenix.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title AuctionTreasury
 * @author DecentaX
 * @notice This contract acumulates Phoenix from the buy and burn and later distributes them to the auction for recycling
 */
contract AuctionTreasury {
    using SafeERC20 for Phoenix;

    Phoenix immutable phoenix;
    address immutable auction;

    error AuctionTreasury__OnlyAuction();

    constructor(address _auction, address _phoenix) {
        auction = _auction;
        phoenix = Phoenix(_phoenix);
    }

    modifier onlyAuction() {
        _onlyAuction();
        _;
    }

    function emitForAuction() external onlyAuction returns (uint256 emitted) {
        uint256 balanceOf = phoenix.balanceOf(address(this));

        emitted = wmul(balanceOf, uint256(0.01e18)); // 1%

        phoenix.safeTransfer(msg.sender, emitted);
    }

    function _onlyAuction() internal view {
        require(msg.sender == auction, AuctionTreasury__OnlyAuction());
    }
}
