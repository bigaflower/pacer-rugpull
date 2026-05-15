// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {sqrt} from "@utils/Math.sol";
import {VoltBurn} from "@core/VoltBurn.sol";
import {TurboAuction} from "@core/Auction.sol";
import {TurboBuyAndBurn} from "@core/TurboBnB.sol";
import {TurboTreasury} from "@core/TurboTreasury.sol";
import {OracleLibrary} from "@libs/OracleLibrary.sol";
import {SwapActionParams} from "./actions/SwapActions.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

/**
 * @title Turbo
 * @dev ERC20 token contract for TURBO tokens.
 */
contract Turbo is ERC20Burnable, Ownable {
    TurboAuction public auction;
    TurboTreasury public treasury;
    TurboBuyAndBurn public turboBnb;
    VoltBurn public voltBurn;

    address public voltTurboPool;
    address public hyperTurboPool;

    error OnlyAuction();

    constructor(address _v3PositionManager, address _hyper, address _volt, address _v3Quoter)
        ERC20("TURBO.WIN", "TURBO")
        Ownable(msg.sender)
    {
        _mint(LIQUIDITY_BONDING_ADDR, 95_000_000e18);
        _mint(msg.sender, 100_000_000e18); // Turbos treasury allocation

        (hyperTurboPool, voltTurboPool) = _createUniswapV3Pools(_hyper, _volt, _v3PositionManager, _v3Quoter);
    }

    modifier onlyAuction() {
        _onlyAuction();
        _;
    }

    function setAuction(TurboAuction _auction) external onlyOwner {
        auction = _auction;

        treasury = _auction.treasury();
    }

    function setTurboBnB(TurboBuyAndBurn _turboBnb) external onlyOwner {
        turboBnb = _turboBnb;
    }

    function setVoltBurn(VoltBurn _voltBurn) external onlyOwner {
        voltBurn = _voltBurn;
    }

    function mint(address _receiver, uint256 _amount) external onlyAuction returns (uint256 minted) {
        minted = _amount;
        _mint(_receiver, _amount);
    }

    /**
     * @notice Internal function to create and initialize Uniswap V3 pools for TURBO/HYPER and TURBO/VOLT.
     * @param _hyper The address of the Hyper ERC20 contract.
     * @param _volt The address of the Volt ERC20 contract
     * @param _v3PositionManager The address of the Uniswap V3 Position Manager contract.
     * @param _v3Quoter The address of Uniswap V3 Quoter contract
     */
    function _createUniswapV3Pools(address _hyper, address _volt, address _v3PositionManager, address _v3Quoter)
        internal
        returns (address _hyperTurboPool, address _voltTurboPool)
    {
        address _turbo = address(this);

        IQuoter quoter = IQuoter(_v3Quoter);

        // Create TURBO/HYPER pool
        {
            (address token0, address token1) =
                _turbo < address(_hyper) ? (_turbo, address(_hyper)) : (address(_hyper), _turbo);
            (uint256 amount0, uint256 amount1) = token0 == _turbo
                ? (INITIAL_TURBO_FOR_LP, INITIAL_HYPER_FOR_LP)
                : (INITIAL_HYPER_FOR_LP, INITIAL_TURBO_FOR_LP);

            uint160 sqrtPX96 = uint160((sqrt((amount1 * 1e18) / amount0) * 2 ** 96) / 1e9);

            INonfungiblePositionManager manager = INonfungiblePositionManager(_v3PositionManager);

            _hyperTurboPool = manager.createAndInitializePoolIfNecessary(token0, token1, POOL_FEE, sqrtPX96);

            IUniswapV3Pool(_hyperTurboPool).increaseObservationCardinalityNext(uint16(100));
        }

        // Create TURBO/VOLT pool
        {
            (address token0, address token1) =
                _turbo < address(_volt) ? (_turbo, address(_volt)) : (address(_volt), _turbo);

            bytes memory path = abi.encodePacked(address(_hyper), POOL_FEE, address(_volt));

            uint256 voltAmount = quoter.quoteExactInput(path, INITIAL_HYPER_FOR_LP);

            (uint256 amount0, uint256 amount1) =
                token0 == _turbo ? (INITIAL_TURBO_FOR_LP, voltAmount) : (voltAmount, INITIAL_TURBO_FOR_LP);

            uint160 sqrtPX96 = uint160((sqrt((amount1 * 1e18) / amount0) * 2 ** 96) / 1e9);

            INonfungiblePositionManager manager = INonfungiblePositionManager(_v3PositionManager);

            _voltTurboPool = manager.createAndInitializePoolIfNecessary(token0, token1, POOL_FEE, sqrtPX96);

            IUniswapV3Pool(_voltTurboPool).increaseObservationCardinalityNext(uint16(100));
        }
    }

    function _onlyAuction() internal view {
        require(msg.sender == address(auction), OnlyAuction());
    }
}
