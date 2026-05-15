// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./const/Constants.sol";
import {Phoenix} from "./Phoenix.sol";
import {PhoenixBuyAndBurn} from "./BuyAndBurn.sol";
import {wdiv, wmul, sub, wpow} from "@utils/Math.sol";
import {FluxStakingVault} from "./staking/FluxStakingVault.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {BlazeStakingVault} from "./staking/BlazeStakingVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SwapActions, SwapActionsState} from "@actions/SwapActions.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

struct LP {
    bool hasLP;
    bool isPhoenixToken0;
    uint240 tokenId;
}

struct UserDeposit {
    uint224 amount;
    uint32 depositedAt;
}

/**
 * @title PhoenixMinting
 * @author Decentra
 * @dev This contract allows users to mint PHOENNIX tokens by depositing TITANX tokens during specific minting cycles.
 */
contract PhoenixMinting is SwapActions {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice The duration of 1 mint cycle
    uint32 public constant MINT_CYCLE_DURATION = 24 hours;

    /// @notice The gap between mint cycles
    uint32 public constant GAP_BETWEEN_CYCLE = 24 hours;

    /// @notice The final mint cycle
    uint8 public constant MAX_MINT_CYCLE = 28;

    uint256 constant STARTING_RATIO = 1e18;

    /// @notice The TitanX token
    IERC20 public immutable titanX;
    IERC20 public immutable inferno;

    /// @notice The Phoenix token
    Phoenix public immutable phoenix;

    /// @notice The buy and burn contract
    PhoenixBuyAndBurn public immutable buyAndBurn;
    address public immutable titanXVault;
    BlazeStakingVault public immutable blazeStakingVault;
    FluxStakingVault public immutable fluxStakingVault;

    uint32 public immutable startTimestamp;

    LP lp;

    uint96 public depositId;

    uint256 public totalPhoenixClaimed;
    uint256 public totalPhoenixMinted;
    uint256 public totalTitanXDeposited;

    uint256 lpSlippage = 0.95e18;

    /// @notice Mapping of the users amount to claim in a mint cycle
    mapping(address user => mapping(uint96 depositId => UserDeposit)) public userDeposit;

    error CycleStillOngoing();
    error NotStartedYet();
    error CycleIsOver();
    error NoPhoenixToClaim();
    error InvalidStartTime();
    error NotEnoughTitanXForLiq();
    error LiquidityAlreadyAdded();

    /// @notice Emits when user mints for a cycle
    event MintExecuted(address indexed user, uint256 titanXAmount, uint256 phoenixAmount, uint96 indexed depositId);

    /// @notice Emits when user claims for a cycle
    event ClaimExecuted(address indexed user, uint256 phoenixAmount, uint96 indexed depositId);

    /**
     * @dev Sets the addressess of the required contracts and the start timestamp of the minting cycles.
     * @param _buyAndBurn Address of the Buy and Burn contract
     * @param _titanX Adress of the TitanX token
     * @param _startTimestamp The timestamp of the first minting cycle
     * @param _phoenix The Phoenix token params
     * @param _blazeStakingVault The blaze staking vault contract
     * @notice Constructor is payable to save gas
     */
    constructor(
        uint32 _startTimestamp,
        address _buyAndBurn,
        address _titanX,
        Phoenix _phoenix,
        address _inferno,
        address _blazeStakingVault,
        address _titanXVault,
        address _fluxStakingVault,
        SwapActionsState memory _swapActionsState
    )
        payable
        notAddress0(_buyAndBurn)
        notAddress0(_titanX)
        notAddress0(_inferno)
        notAddress0(_blazeStakingVault)
        notAddress0(_fluxStakingVault)
        notAddress0(address(_phoenix))
        SwapActions(_swapActionsState)
    {
        startTimestamp = _startTimestamp;

        inferno = IERC20(_inferno);

        titanXVault = _titanXVault;
        fluxStakingVault = FluxStakingVault(_fluxStakingVault);
        phoenix = _phoenix;
        titanX = IERC20(_titanX);
        buyAndBurn = PhoenixBuyAndBurn(payable(_buyAndBurn));
        blazeStakingVault = BlazeStakingVault(payable(_blazeStakingVault));
    }

    function changeLpSlippage(uint256 _newSlippage) external onlyOwner {
        lpSlippage = _newSlippage;
    }

    /**
     * @notice Mints Phoenix tokens by depositing TitanX tokens during an ongoing mint cycle.
     * @param _amount The amount of TITANX tokens to deposit.
     */
    function mint(uint256 _amount) external notAmount0(_amount) {
        require(block.timestamp >= startTimestamp, NotStartedYet());

        (uint32 currentCycle,, uint32 endsAt) = getCycleAt(uint32(block.timestamp));

        if (block.timestamp > endsAt) revert CycleIsOver();

        titanX.safeTransferFrom(msg.sender, address(this), _amount);

        _distribute(_amount);

        uint256 phoenixAmount = (_amount * getRatioForCycle(currentCycle)) / 1e18;

        userDeposit[msg.sender][++depositId] =
            UserDeposit({amount: uint224(_amount), depositedAt: uint32(block.timestamp)});

        emit MintExecuted(msg.sender, _amount, phoenixAmount, depositId);

        totalPhoenixMinted = totalPhoenixMinted + phoenixAmount;
        totalTitanXDeposited = totalTitanXDeposited + _amount;
    }

    /**
     * @notice Claims the minted Phoenix tokens after the end of the specified mint cycle.
     * @param _depositId The ID of the mint cycle to claim tokens from.
     */
    function claim(uint96 _depositId) public {
        UserDeposit memory userDep = userDeposit[msg.sender][_depositId];

        require(block.timestamp > userDep.depositedAt + 24 hours, CycleStillOngoing());

        (uint32 cycle,,) = getCycleAt(userDep.depositedAt);

        uint256 toClaim = wmul(userDep.amount, getRatioForCycle(cycle));

        delete userDeposit[msg.sender][_depositId];

        emit ClaimExecuted(msg.sender, toClaim, _depositId);

        totalPhoenixClaimed = totalPhoenixClaimed + toClaim;

        phoenix.mint(msg.sender, toClaim);
    }

    function batchClaim(uint96[] calldata _ids) external {
        for (uint96 i = 0; i < _ids.length; ++i) {
            claim(_ids[i]);
        }
    }

    function batchClaimableAmount(address _user, uint96[] calldata _depositIds) external view returns (uint256 total) {
        for (uint96 i = 0; i < _depositIds.length; ++i) {
            total += amountToClaim(_user, _depositIds[i]);
        }
    }

    function amountToClaim(address _user, uint96 _depositId) public view returns (uint256 toClaim) {
        UserDeposit memory userDep = userDeposit[_user][_depositId];
        (uint32 cycle,,) = getCycleAt(userDep.depositedAt);
        toClaim = wmul(userDep.amount, getRatioForCycle(cycle));
    }

    function _distribute(uint256 _amount) internal {
        uint256 titanXBalance = titanX.balanceOf(address(this));
        // @note - If there is no added liquidity, but the balance exceeds the initial for liquidity, we should distribute the difference
        if (!lp.hasLP) {
            if (titanXBalance <= INITIAL_TITAN_X_FOR_LIQ) return;
            _amount = uint192(titanXBalance - INITIAL_TITAN_X_FOR_LIQ);
        }

        titanX.transfer(address(fluxStakingVault), wmul(_amount, uint256(0.28e18)));
        titanX.transfer(titanXVault, wmul(_amount, uint256(0.2e18)));
        titanX.transfer(address(buyAndBurn), wmul(_amount, uint256(0.35e18)));
        titanX.transfer(address(blazeStakingVault), wmul(_amount, uint256(0.09e18)));
        titanX.transfer(GENESIS, wmul(_amount, TO_GENESIS));
    }

    function getCycleAt(uint32 t) public view returns (uint32 currentCycle, uint32 startsAt, uint32 endsAt) {
        uint32 timeElapsedSince = uint32(t - startTimestamp);

        currentCycle = (timeElapsedSince / GAP_BETWEEN_CYCLE) + 1;

        if (currentCycle > MAX_MINT_CYCLE) currentCycle = MAX_MINT_CYCLE;

        startsAt = startTimestamp + ((currentCycle - 1) * GAP_BETWEEN_CYCLE);

        endsAt = startsAt + MINT_CYCLE_DURATION;
    }

    /**
     * @notice Sends the fees acquired from the UniswapV3 position
     * @return amount0 The amount of token0 collected
     * @return amount1 The amount of token1 collected
     */
    function collectFees() external returns (uint256 amount0, uint256 amount1) {
        LP memory _lp = lp;

        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _lp.tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = INonfungiblePositionManager(positionManager).collect(params);

        (uint256 phoenixAmount, uint256 infernoAmount) = _lp.isPhoenixToken0 ? (amount0, amount1) : (amount1, amount0);

        phoenix.burn(phoenixAmount);
        inferno.transfer(address(fluxStakingVault), infernoAmount);
    }

    function getRatioForCycle(uint32 cycleId) public pure returns (uint256 ratio) {
        if (cycleId == 1) {
            ratio = STARTING_RATIO;
        } else if (cycleId <= 4) {
            ratio = 0.95e18;
        } else if (cycleId <= 8) {
            ratio = 0.925e18;
        } else if (cycleId <= 12) {
            ratio = 0.9e18;
        } else if (cycleId <= 16) {
            ratio = 0.875e18;
        } else if (cycleId <= 20) {
            ratio = 0.85e18;
        } else if (cycleId <= 24) {
            ratio = 0.825e18;
        } else if (cycleId <= 28) {
            ratio = 0.8e18;
        }
    }

    /**
     * @notice Adds liquidity to the INF/PHOENIX UniV3 Pool
     * @param _deadline The deadline for the liquidity addition
     */
    function addLiquidityToInfernoPhoenixPool(uint32 _deadline) external onlyOwner {
        require(!lp.hasLP, LiquidityAlreadyAdded());
        require(titanX.balanceOf(address(this)) >= INITIAL_TITAN_X_FOR_LIQ, NotEnoughTitanXForLiq());

        uint256 infernoReceived =
            swapExactInputV3(address(titanX), address(inferno), INITIAL_TITAN_X_FOR_LIQ, _deadline);

        phoenix.mint(address(this), INITIAL_PHOENIX_FOR_LP);

        (uint256 amount0, uint256 amount1, uint256 amount0Min, uint256 amount1Min, address token0, address token1) =
            _sortAmountsForLP(infernoReceived, INITIAL_PHOENIX_FOR_LP);

        IERC20(token0).approve(positionManager, amount0);
        IERC20(token1).approve(positionManager, amount1);

        // wake-disable-next-line
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: token0,
            token1: token1,
            fee: POOL_FEE,
            tickLower: (TickMath.MIN_TICK / TICK_SPACING) * TICK_SPACING,
            tickUpper: (TickMath.MAX_TICK / TICK_SPACING) * TICK_SPACING,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: _deadline
        });

        // wake-disable-next-line
        (uint256 tokenId,, uint256 amount0Added, uint256 amount1Added) =
            INonfungiblePositionManager(positionManager).mint(params);

        bool isPhoenixToken0 = token0 == address(phoenix);

        if (amount0Added < amount0) {
            IERC20(token0).transfer(owner(), amount0 - amount0Added);
        }
        if (amount1Added < amount1) {
            IERC20(token1).transfer(owner(), amount1 - amount1Added);
        }

        lp = LP({hasLP: true, tokenId: uint240(tokenId), isPhoenixToken0: isPhoenixToken0});
    }

    /**
     * @notice Sorts the tokens and returns the amounts
     * @return amount0 The amount of token0
     * @return amount1 The amount of token1
     * @return amount0Min Minimum amount of token0
     * @return amount1Min Minimum amount of token1
     * @return token0 Address of token0
     * @return token1 Address of token1
     */
    function _sortAmountsForLP(uint256 _infernoAmount, uint256 _phoenixAmount)
        internal
        view
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 amount0Min,
            uint256 amount1Min,
            address token0,
            address token1
        )
    {
        address _phoenix = address(phoenix);
        address _inferno = address(inferno);

        (token0, token1) = _phoenix < _inferno ? (_phoenix, _inferno) : (_inferno, _phoenix);
        (amount0, amount1) = token0 == _phoenix ? (_phoenixAmount, _infernoAmount) : (_infernoAmount, _phoenixAmount);

        (amount0Min, amount1Min) = (wmul(amount0, lpSlippage), wmul(amount1, lpSlippage));
    }
}
