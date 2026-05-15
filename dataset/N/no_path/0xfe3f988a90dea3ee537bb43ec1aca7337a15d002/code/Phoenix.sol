// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {sqrt} from "@utils/Math.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {FullMath} from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

/**
 * @title Phoenix
 * @author Decentra
 * @dev ERC20 token contract for Phoenix tokens.
 * @notice It can be minted by PhoenixMinting during cycles
 */
contract Phoenix is ERC20Burnable, Ownable {
    using FullMath for uint256;

    address public auction;
    address public minting;
    address public auctionTreasury;

    address public immutable pool;

    error OnlyAuctionOrMinting();
    error InvalidInput();

    modifier onlyMinting() {
        _onlyMinting();
        _;
    }

    /**
     * @dev Sets the Minting and Buy and Burn contract addresses.
     * @param _titanX The TitanX token
     * @param _inferno The INFERNO token
     * @param _v3Quoter The UniswapV3 Quoter
     * @param _v3PositionManager The UniswapV3 Position Manager
     */
    constructor(address _titanX, address _inferno, address _v3Quoter, address _v3PositionManager)
        ERC20("PHOENIX", "PHX")
        Ownable(msg.sender)
    {
        pool = _createUniswapV3Pool(_titanX, _inferno, _v3Quoter, _v3PositionManager);
    }

    function setAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    function setMinting(address _minting) external onlyOwner {
        minting = _minting;
    }

    function setAuctionTreasury(address _auctionTreasury) external onlyOwner {
        auctionTreasury = _auctionTreasury;
    }

    /**
     * @notice Mints Phoenix tokens to a specified address.
     * @notice This is only callable by the Minting contract
     * @param _to The address to mint the tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external onlyMinting {
        _mint(_to, _amount);
    }

    function _onlyMinting() internal view {
        require(msg.sender == minting, OnlyAuctionOrMinting());
    }

    function _createUniswapV3Pool(
        address _titanX,
        address _inferno,
        address UNISWAP_V3_QUOTER,
        address UNISWAP_V3_POSITION_MANAGER
    ) internal returns (address _pool) {
        address _phoenix = address(this);

        IQuoter quoter = IQuoter(UNISWAP_V3_QUOTER);

        bytes memory path = abi.encodePacked(address(_titanX), POOL_FEE, address(_inferno));

        uint256 infernoAmount = quoter.quoteExactInput(path, INITIAL_TITAN_X_FOR_LIQ);

        uint256 phoenixAmount = INITIAL_PHOENIX_FOR_LP;

        (address token0, address token1) = _phoenix < _inferno ? (_phoenix, _inferno) : (_inferno, _phoenix);

        (uint256 amount0, uint256 amount1) =
            token0 == _inferno ? (infernoAmount, phoenixAmount) : (phoenixAmount, infernoAmount);

        uint160 sqrtPX96 = uint160((sqrt((amount1 * 1e18) / amount0) * 2 ** 96) / 1e9);

        INonfungiblePositionManager manager = INonfungiblePositionManager(UNISWAP_V3_POSITION_MANAGER);

        _pool = manager.createAndInitializePoolIfNecessary(token0, token1, POOL_FEE, sqrtPX96);

        IUniswapV3Pool(_pool).increaseObservationCardinalityNext(uint16(100));
    }
}
