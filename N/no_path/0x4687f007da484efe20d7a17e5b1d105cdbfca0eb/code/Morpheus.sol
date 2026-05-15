// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* === OZ === */
import {ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/* = SYSTEM */
import {MorpheusMinting} from "./MorpheusMinting.sol";
import {MorpheusBuyAndBurn} from "./MorpheusBuyAndBurn.sol";

/* = LIBS =  */
import {FullMath} from "../lib/v3-core/contracts/libraries/FullMath.sol";
import {Math} from "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

/* = UNIV3 = */
import {IUniswapV3Pool} from "../lib/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {INonfungiblePositionManager} from "../lib/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./const/BuyAndBurnConst.sol";

/**
 * @title Morpheus
 * @author 0xkmmm
 * @dev ERC20 token contract for MORPHEUS tokens.
 * @notice It can be minted by MorpheusMinting during cycles
 * @notice It can be minted by MorpheusBuyAndBurn when forming an LP
 */
contract Morpheus is ERC20Burnable {
    using FullMath for uint256;

    /* ==== IMMUTABLES ==== */

    MorpheusMinting public immutable minting;
    MorpheusBuyAndBurn public immutable buyAndBurn;
    address public dragonXMorpheusPool;

    /* ==== ERRORS ==== */

    error OnlyMinting();
    error OnlyBuyAndBurn();
    error InvalidInput();

    /* ==== CONSTRUCTOR ==== */

    /**
     * @dev Sets the minting and buy and burn contract address.
     * @param _morpheusMintingStartTimestamp The start of the first mint cycle
     * @param _morpheusBuyAndBurnStartTimestamp The start of the buy and burn contract
     * @param _titanX The titanX token
     * @param _dragonX The dragonX token
     * @param _owner The owner of the buyAndBurn
     * @notice Constructor is payable to save gas
     */
    constructor(
        uint32 _morpheusMintingStartTimestamp,
        uint32 _morpheusBuyAndBurnStartTimestamp,
        address _dragonXTitanXPool,
        address _titanX,
        address _dragonX,
        address _owner
    ) payable ERC20("Morpheus", "MORPH") {
        buyAndBurn = new MorpheusBuyAndBurn(
            _morpheusBuyAndBurnStartTimestamp,
            _dragonXTitanXPool,
            _titanX,
            _dragonX,
            _owner
        );
        minting = new MorpheusMinting(
            address(buyAndBurn),
            _titanX,
            _morpheusMintingStartTimestamp
        );
    }

    /* == MODIFIERS == */

    /// @dev Modifier to ensure the function is called only by the minter contract.
    modifier onlyMinting() {
        _onlyMinting();
        _;
    }

    /// @dev Modifier to ensure the function is called only by the buy and burn contract.
    modifier onlyBuyAndBurn() {
        _onlyBuyAndBurn();
        _;
    }

    /* == EXTERNAL == */

    /**
     * @notice Mints MORPHEUS tokens to a specified address.
     * @notice This is only callable by the MorpheusMinting contract
     * @param _to The address to mint the tokens to.
     * @param _amount The amount of tokens to mint.
     */
    function mint(address _to, uint256 _amount) external onlyMinting {
        _mint(_to, _amount);
    }

    /// @notice Mints morpheus tokens for the initial LP creation
    function mintTokensForLP() external onlyBuyAndBurn {
        _mint(address(buyAndBurn), INITIAL_LP_MINT);
    }

    /* == INTERNAL == */

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _onlyBuyAndBurn() internal view {
        if (msg.sender != address(buyAndBurn)) revert OnlyBuyAndBurn();
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function _onlyMinting() internal view {
        if (msg.sender != address(minting)) revert OnlyMinting();
    }

    ///@notice - Creates the DRAGONX/MORPHEUS Pool on uniswapV3
    ///@notice - Only called once when liquidity is added from BuyAndBurn
    function createDragonXMorpheusPool(
        address _dragonX,
        address _dragonXTitanXPool,
        uint256 _dragonxReceived
    ) external onlyBuyAndBurn returns (address _dragonXMorpheusPool) {
        address _morpheus = address(this);

        (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(_dragonXTitanXPool)
            .slot0();
    
        (address token0, address token1) = _dragonX < _morpheus
            ? (_dragonX, _morpheus)
            : (_morpheus, _dragonX);

        uint256 dragonXAmount = _dragonxReceived;
        uint256 morpheusAmount = INITIAL_LP_MINT;

        (uint256 amount0, uint256 amount1) = token0 == _dragonX
            ? (dragonXAmount, morpheusAmount)
            : (morpheusAmount, dragonXAmount);

        sqrtPriceX96 = uint160(
            (Math.sqrt((amount1 * 1e18) / amount0) * 2 ** 96) / 1e9
        );

        INonfungiblePositionManager manager = INonfungiblePositionManager(
            UNISWAP_V3_POSITION_MANAGER
        );

        dragonXMorpheusPool = manager.createAndInitializePoolIfNecessary(
            token0,
            token1,
            POOL_FEE,
            sqrtPriceX96
        );

        _dragonXMorpheusPool = dragonXMorpheusPool;

        IUniswapV3Pool(dragonXMorpheusPool).increaseObservationCardinalityNext(uint16(100));
    }
}
