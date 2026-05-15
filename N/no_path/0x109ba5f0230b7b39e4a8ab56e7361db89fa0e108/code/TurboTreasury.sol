// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./const/Constants.sol";
import {Turbo} from "@core/Turbo.sol";
import {wmul} from "./utils/Math.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title TurboTreasury
 */
contract TurboTreasury {
    using SafeERC20 for Turbo;

    uint64 public constant DISTRIBUTION = 0.2e18; // 20%

    Turbo public immutable turbo;
    address public immutable auction;

    error TurboTreasury__OnlyAuction();

    constructor(address _auction, address _turbo) {
        auction = _auction;
        turbo = Turbo(_turbo);
    }

    modifier onlyAuction() {
        _onlyAuction();
        _;
    }

    function emitForAuction() external onlyAuction returns (uint256 emitted) {
        uint256 balanceOf = turbo.balanceOf(address(this));

        emitted = wmul(balanceOf, DISTRIBUTION);

        turbo.safeTransfer(msg.sender, emitted);
    }

    function _onlyAuction() internal view {
        if (msg.sender != auction) revert TurboTreasury__OnlyAuction();
    }
}
