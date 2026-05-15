// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/* === OZ === */
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Math} from "../lib/openzeppelin-contracts/contracts/utils/math/Math.sol";

/* === SYSTEM === */
import {MorpheusBuyAndBurn} from "./MorpheusBuyAndBurn.sol";
import {Morpheus} from "./Morpheus.sol";

/* === CONST === */
import "./const/BuyAndBurnConst.sol";

/**
 * @title MorpheusMinting
 * @author 0xkmmm
 * @dev This contract allows users to mint Morpheus tokens by depositing TITANX tokens during specific minting cycles.
 */
contract MorpheusMinting {
    using SafeERC20 for IERC20;
    using Math for uint256;

    /* == CONSTANTS ==  */

    ///@notice  The duration of 1 mint cycle
    uint32 public constant MINT_CYCLE_DURATION = 24 hours;

    ///@notice The starting ratio of the first mint cycle
    uint256 constant STARTING_RATIO = 1e18;

    ///@notice The gap between mint cycles
    uint32 public constant GAP_BETWEEN_CYCLE = 1 days;

    ///@notice  The final mint cycle
    uint8 public constant MAX_MINT_CYCLE = 14;

    /* == IMMUTABLES == */

    ///@notice The titanX token
    IERC20 public immutable titanX;

    uint256 public totalTitanXDeposited;
    uint256 public totalMorpheusClaimed;
    uint256 public totalMorpheusMinted;

    ///@notice The buy and burn contract
    MorpheusBuyAndBurn public immutable buyAndBurn;

    uint32 public immutable startTimestamp;

    /* == STATE == */

    ///@notice  Morpheus token
    Morpheus public morpheus;

    ///@notice The start of the first minting cycle

    ///@notice Mapping of the users amount to claim in a mint cycle
    mapping(address user => mapping(uint32 cycleId => uint256 amount))
        public amountToClaim;

    /* == ERRORS == */

    error InvalidInput();
    error CycleStillOngoing();
    error NotStartedYet();
    error CycleIsOver();
    error NoMorpheusToClaim();
    error InvalidStartTime();

    /* == EVENTS === */

    ///@notice Emits when user mints for a cycle
    event MintExecuted(
        address indexed user,
        uint256 morpheusAmount,
        uint32 indexed mintCycleId
    );

    ///@notice Emits when user claims for a cycle
    event ClaimExecuted(
        address indexed user,
        uint256 morpheusAmount,
        uint8 indexed mintCycleId
    );

    /* == CONSTRUCTOR == */

    /**
     * @dev Sets the addresses for the TITANX and Morpheus tokens.
     * @param _buyAndBurn Address of the buy and burn contract
     * @param _titanX Adress of the TitanX token
     * @param _startTimestamp The time stamp of the first minting cycle
     * @notice Constructor is payable to save gas
     */
    constructor(
        address _buyAndBurn,
        address _titanX,
        uint32 _startTimestamp
    ) payable {
        if (_buyAndBurn == address(0)) revert InvalidInput();
        
        startTimestamp = _startTimestamp;
        morpheus = Morpheus(msg.sender);
        titanX = IERC20(_titanX);
        buyAndBurn = MorpheusBuyAndBurn(_buyAndBurn);
    }

    /* == EXTERNAL == */

    function getRatioForCycle(
        uint32 cycleId
    ) public pure returns (uint256 ratio) {
        unchecked {
            uint256 adjustedRatioDiscount = cycleId == 1
                ? 0
                : uint256(cycleId - 1) * 4e16;
            ratio = STARTING_RATIO - adjustedRatioDiscount;
        }
    }

    /**
     * @notice Mints Morpheus tokens by depositing TITANX tokens during an ongoing mint cycle.
     * @param _amount The amount of TITANX tokens to deposit.
     */
    function mint(uint256 _amount) external {
        if (_amount == 0) revert InvalidInput();
        titanX.safeTransferFrom(msg.sender, address(this), _amount);

        if (block.timestamp < startTimestamp) revert NotStartedYet();

        (uint32 currentCycle, , uint32 endsAt) = getCurrentMintCycle();

        if (block.timestamp > endsAt) revert CycleIsOver();

        uint256 adjustedAmount = _vaultAndSendToGenesisAndPrize(_amount);
        uint256 morpheusAmount = (_amount * getRatioForCycle(currentCycle)) /
            1e18;

        amountToClaim[msg.sender][currentCycle] += morpheusAmount;

        emit MintExecuted(msg.sender, morpheusAmount, currentCycle);

        totalMorpheusMinted = totalMorpheusMinted + morpheusAmount;
        totalTitanXDeposited = totalTitanXDeposited + _amount;

        titanX.approve(address(buyAndBurn), _amount);
        buyAndBurn.distributeTitanXForBurning(adjustedAmount);

        if (!buyAndBurn.liquidityAdded() && titanX.balanceOf(address(buyAndBurn)) >= INITIAL_TITAN_X_FOR_LIQ) {
            buyAndBurn.addLiquidityToMorpheusDragonxPool(uint32(block.timestamp));
        }
    }

    /**
     * @notice Claims the minted Morpheus tokens after the end of the specified mint cycle.
     * @param _cycleId The ID of the mint cycle to claim tokens from.
     */
    function claim(uint8 _cycleId) external {
        if (_getCycleEndTime(_cycleId) > block.timestamp)
            revert CycleStillOngoing();

        uint256 toClaim = amountToClaim[msg.sender][_cycleId];

        if (toClaim == 0) revert NoMorpheusToClaim();

        delete amountToClaim[msg.sender][_cycleId];

        emit ClaimExecuted(msg.sender, toClaim, _cycleId);

        totalMorpheusClaimed = totalMorpheusClaimed + toClaim;

        morpheus.mint(msg.sender, toClaim);
    }

    /* == INTERNAL/PRIVATE == */

    function _vaultAndSendToGenesisAndPrize(
        uint256 _amount
    ) internal returns (uint256 newAmount) {

        unchecked {
            uint256 titanXForPrize = _amount.mulDiv(
                PRIZE_BPS,
                BPS_DENOM,
                Math.Rounding.Ceil
            );
            uint256 titanXForGenesis = _amount.mulDiv(
                GENESIS_BPS,
                BPS_DENOM,
                Math.Rounding.Ceil
            );
            uint256 titanXToVault = _amount.mulDiv(
                DRAGON_X_VAULT_BPS,
                BPS_DENOM,
                Math.Rounding.Ceil
            );

            newAmount = _amount - titanXForGenesis - titanXToVault - titanXForPrize;
            titanX.safeTransfer(
                PRIZE_WALLET,
                titanXForPrize
            );
            titanX.safeTransfer(
                DRAGON_X_ADDRESS,
                titanXToVault
            );
            titanX.safeTransfer(
                GENESIS_WALLET,
                titanXForGenesis
            );
        }
    }

    function getCurrentMintCycle()
        public
        view
        returns (uint32 currentCycle, uint32 startsAt, uint32 endsAt)
    {
        uint32 timeElapsedSince = uint32(block.timestamp - startTimestamp);

        currentCycle = uint8(timeElapsedSince / GAP_BETWEEN_CYCLE) + 1;

        if (currentCycle > MAX_MINT_CYCLE) currentCycle = MAX_MINT_CYCLE;

        startsAt = startTimestamp + ((currentCycle - 1) * GAP_BETWEEN_CYCLE);

        endsAt = startsAt + MINT_CYCLE_DURATION;
    }

    function _getCycleEndTime(
        uint8 cycleNumber
    ) internal view returns (uint32 endsAt) {
        uint32 cycleStartTime = startTimestamp +
            ((cycleNumber - 1) * GAP_BETWEEN_CYCLE);

        endsAt = cycleStartTime + MINT_CYCLE_DURATION;
    }
}