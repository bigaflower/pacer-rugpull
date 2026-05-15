// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import "@actions/SwapActions.sol";
import {Time} from "@utils/Time.sol";
import {Turbo} from "@core/Turbo.sol";
import {Errors} from "@utils/Errors.sol";
import {IHyper} from "@interfaces/IHyper.sol";
import {ITurbo} from "@interfaces/ITurbo.sol";
import {wdiv, wmul, sub, sqrt} from "@utils/Math.sol";
import {TurboTreasury} from "@core/TurboTreasury.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

struct LP {
    bool hasLP;
    bool isTurboToken0;
    uint240 tokenId;
}

struct DailyStatistic {
    uint128 turboEmitted;
    uint128 hyperDeposited;
}

/**
 * @title TurboAuction
 * @dev Contract to auction Hyper to earn a proportional amount of 100M TURBO.
 */
contract TurboAuction is Ownable, Errors {
    using SafeERC20 for *;

    ITurbo immutable turbo;
    IHyper public immutable hyper;
    uint32 public immutable startTimestamp;
    address immutable v3PositionManager;

    LP public lp;
    TurboTreasury public immutable treasury;

    uint128 public lpSlippage = WAD - 0.2e18;

    mapping(address => mapping(uint32 day => uint256 amount)) public depositOf;
    mapping(uint32 day => DailyStatistic) public dailyStats;

    error OnlyClaimableTheNextDay();
    error LiquidityAlreadyAdded();
    error NotStartedYet();
    error NothingToClaim();
    error InvalidSlippage();
    error NotEnoughHyperForLiquidity();
    error TreasuryVoltIsEmpty();
    error MustStartAt2PMUTC();

    event UserDeposit(address indexed user, uint256 indexed amount, uint32 indexed day);
    event UserClaimed(address indexed user, uint256 indexed turboAmount, uint32 indexed day);

    constructor(uint32 _startTimestamp, address _turbo, address _hyper, address _v3PositionManager, address _owner)
        notAddress0(_turbo)
        notAddress0(_hyper)
        Ownable(_owner)
    {
        if ((_startTimestamp - 14 hours) % 1 days != 0) revert MustStartAt2PMUTC();

        turbo = ITurbo(_turbo);
        v3PositionManager = _v3PositionManager;
        hyper = IHyper(_hyper);

        treasury = new TurboTreasury(address(this), address(turbo));
        startTimestamp = _startTimestamp;
    }

    function changeLPSlippage(uint128 _newSlippage) external onlyOwner notAmount0(_newSlippage) {
        if (_newSlippage > WAD) revert InvalidSlippage();
        lpSlippage = _newSlippage;
    }

    function deposit(uint192 _amount) external notAmount0(_amount) {
        if (startTimestamp > Time.blockTs()) revert NotStartedYet();

        _updateAuction();

        uint32 daySinceStart = Time.dayGap(startTimestamp, Time.blockTs()) + 1;

        DailyStatistic storage stats = dailyStats[daySinceStart];

        hyper.safeTransferFrom(msg.sender, address(this), _amount);

        _distribute(_amount);

        depositOf[msg.sender][daySinceStart] += _amount;

        stats.hyperDeposited += uint128(_amount);

        emit UserDeposit(msg.sender, _amount, daySinceStart);
    }

    function claim(uint32 _day) public {
        uint32 daySinceStart = Time.dayGap(startTimestamp, Time.blockTs()) + 1;
        if (_day == daySinceStart) revert OnlyClaimableTheNextDay();

        uint256 toClaim = amountToClaim(msg.sender, _day);

        if (toClaim == 0) revert NothingToClaim();

        emit UserClaimed(msg.sender, toClaim, _day);

        turbo.transfer(msg.sender, toClaim);

        depositOf[msg.sender][_day] = 0;
    }

    function batchClaim(uint32[] calldata _days) external {
        for (uint256 i; i < _days.length; ++i) {
            claim(_days[i]);
        }
    }

    function batchClaimableAmount(address _user, uint32[] calldata _days) public view returns (uint256 toClaim) {
        for (uint256 i; i < _days.length; ++i) {
            toClaim += amountToClaim(_user, _days[i]);
        }
    }

    function amountToClaim(address _user, uint32 _day) public view returns (uint256 toClaim) {
        uint32 daySinceStart = Time.dayGap(startTimestamp, Time.blockTs()) + 1;

        if (_day == daySinceStart) return 0;
        uint256 depositAmount = depositOf[_user][_day];

        DailyStatistic memory stats = dailyStats[_day];

        return (depositAmount * stats.turboEmitted) / stats.hyperDeposited;
    }

    /**
     * @notice Adds initial liquidity to the TURBO/VOLT and TURBO/HYPER Uniswap V3 pools
     * @param _deadline The deadline for the liquidity addition
     */
    function addInitialLiquidity(uint32 _deadline) external onlyOwner notExpired(_deadline) {
        require(!lp.hasLP, LiquidityAlreadyAdded());
        require(hyper.balanceOf(address(this)) >= INITIAL_HYPER_FOR_LP, NotEnoughHyperForLiquidity());

        turbo.mint(address(this), INITIAL_TURBO_FOR_LP);

        // Add liquidity to TURBO/HYPER pool
        _addLiquidityToPool(address(turbo), address(hyper), INITIAL_TURBO_FOR_LP, INITIAL_HYPER_FOR_LP, _deadline);

        _transferOwnership(address(0));
    }

    /**
     * @notice Collects the fees accumulated from the Uniswap V3 liquidity pools
     */
    function collectFees() external returns (uint256 _turboAmount, uint256 _hyperAmount) {
        // Collect fees from TURBO/HYPER pool
        (_turboAmount, _hyperAmount) = _collectFeesFromPool(lp);

        // Transfer collected TURBO tokens
        if (_turboAmount > 0) turbo.safeTransfer(LIQUIDITY_BONDING_ADDR, _turboAmount);

        // Transfer collected HYPER tokens
        if (_hyperAmount > 0) hyper.safeTransfer(LIQUIDITY_BONDING_ADDR, _hyperAmount);
    }

    ///@notice Collects the fees from a pool
    function _collectFeesFromPool(LP memory _lp) internal returns (uint256 turboAmount, uint256 otherAmount) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _lp.tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (uint256 amount0, uint256 amount1) = INonfungiblePositionManager(v3PositionManager).collect(params);

        (turboAmount, otherAmount) = _lp.isTurboToken0 ? (amount0, amount1) : (amount1, amount0);
    }

    ///@notice - Distributes the tokens
    function _distribute(uint256 _amount) internal {
        uint256 hyperBalance = hyper.balanceOf(address(this));
        //@note - If there is no added liquidity, but the balance exceeds the initial for liquidity, we should distribute the difference
        if (!lp.hasLP) {
            if (hyperBalance <= INITIAL_HYPER_FOR_LP) return;

            _amount = uint192(hyperBalance - INITIAL_HYPER_FOR_LP);
        }

        hyper.transfer(DEAD_ADDR, wmul(_amount, HYPER_BURN));

        hyper.transfer(LIQUIDITY_BONDING_ADDR, wmul(_amount, TO_LP));
        hyper.transfer(DEV_WALLET, wmul(_amount, TO_DEV_WALLET));
        hyper.transfer(GENESIS_WALLET, wmul(_amount, TO_GENESIS));
        hyper.transfer(address(turbo.voltBurn()), wmul(_amount, TO_VOLT_BURN));

        hyper.approve(address(turbo.turboBnb()), wmul(_amount, TO_TURBO_BNB));
        turbo.turboBnb().distributeHyperForBurning(wmul(_amount, TO_TURBO_BNB));
    }

    function _addLiquidityToPool(address token0, address token1, uint256 amount0, uint256 amount1, uint32 deadline)
        internal
    {
        (
            uint256 amount0Sorted,
            uint256 amount1Sorted,
            uint256 amount0Min,
            uint256 amount1Min,
            address sortedToken0,
            address sortedToken1
        ) = _sortAmounts(token0, token1, amount0, amount1);

        IERC20(sortedToken0).approve(address(v3PositionManager), amount0Sorted);
        IERC20(sortedToken1).approve(address(v3PositionManager), amount1Sorted);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: sortedToken0,
            token1: sortedToken1,
            fee: POOL_FEE,
            tickLower: (TickMath.MIN_TICK / TICK_SPACING) * TICK_SPACING,
            tickUpper: (TickMath.MAX_TICK / TICK_SPACING) * TICK_SPACING,
            amount0Desired: amount0Sorted,
            amount1Desired: amount1Sorted,
            amount0Min: amount0Min,
            amount1Min: amount1Min,
            recipient: address(this),
            deadline: deadline
        });

        (uint256 tokenId,, uint256 amount0Added, uint256 amount1Added) =
            INonfungiblePositionManager(v3PositionManager).mint(params);

        IERC20(sortedToken0).approve(address(v3PositionManager), 0);
        IERC20(sortedToken1).approve(address(v3PositionManager), 0);

        if (amount0Added < amount0Sorted) {
            IERC20(sortedToken0).transfer(owner(), amount0Sorted - amount0Added);
        }

        if (amount1Added < amount1Sorted) {
            IERC20(sortedToken1).transfer(owner(), amount1Sorted - amount1Added);
        }

        LP memory newLP = LP({hasLP: true, tokenId: uint240(tokenId), isTurboToken0: sortedToken0 == address(turbo)});

        lp = newLP;
    }

    ///@notice Emits the needed TURBO
    function _updateAuction() internal {
        uint32 daySinceStart = Time.dayGap(startTimestamp, Time.blockTs()) + 1;

        if (dailyStats[daySinceStart].turboEmitted != 0) return;

        if (daySinceStart > 8 && turbo.balanceOf(address(treasury)) == 0) revert TreasuryVoltIsEmpty();

        uint256 emitted = daySinceStart <= 8 ? turbo.mint(address(this), AUCTION_EMIT) : treasury.emitForAuction();

        dailyStats[daySinceStart].turboEmitted = uint128(emitted);
    }

    ///@notice Sorts tokens and amounts for adding liquidity
    function _sortAmounts(address _tokenA, address _tokenB, uint256 _amountA, uint256 _amountB)
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
        (token0, token1) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
        (amount0, amount1) = token0 == _tokenA ? (_amountA, _amountB) : (_amountB, _amountA);

        (amount0Min, amount1Min) = (wmul(amount0, lpSlippage), wmul(amount1, lpSlippage));
    }
}
