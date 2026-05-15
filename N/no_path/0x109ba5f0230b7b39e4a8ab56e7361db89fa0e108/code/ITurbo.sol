// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {TurboAuction} from "@core/Auction.sol";
import {TurboBuyAndBurn} from "@core/TurboBnB.sol";
import {VoltBurn} from "@core/VoltBurn.sol";
import {TurboTreasury} from "@core/TurboTreasury.sol";

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface ITurbo is IERC20 {
    function auction() external view returns (TurboAuction);
    function treasury() external view returns (TurboTreasury);
    function turboBnb() external view returns (TurboBuyAndBurn);
    function voltBurn() external returns (VoltBurn);

    function hyperTurboPool() external view returns (address);
    function voltTurboPool() external view returns (address);

    function setAuction(TurboAuction _auction) external;
    function setTurboBnB(TurboBuyAndBurn _turboBnb) external;
    function setVoltBurn(VoltBurn _voltBurn) external;

    function mint(address _receiver, uint256 _amount) external returns (uint256);
}
