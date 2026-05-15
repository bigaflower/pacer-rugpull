// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "@const/Constants.sol";
import {wmul} from "@utils/Math.sol";
import {Errors} from "@utils/Errors.sol";
import {Phoenix} from "@core/Phoenix.sol";
import {PhoenixMinting} from "@core/Minting.sol";
import {AuctionTreasury} from "@core/AuctionTreasury.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct DailyStatistic {
    uint128 phoenixEmitted;
    uint128 titanXDeposited;
}

/// @notice Struct is packed to take up exatctly 1 storage slot
struct UserAuction {
    uint32 ts;
    uint32 day;
    uint192 amount;
}
/// @author Decentra

contract PhoenixAuction is Errors {
    using SafeERC20 for IERC20;

    uint32 constant SECONDS_PER_DAY = 86400;

    Phoenix immutable phoenix;
    IERC20 immutable titanX;
    address immutable phoenixBnB;

    uint32 public immutable startTimestamp;
    address immutable titanXStakingVault;

    uint256 depositId;

    mapping(address => mapping(uint256 id => UserAuction)) public depositOf;
    mapping(uint32 day => DailyStatistic) public dailyStats;

    error PhoenixAuctionCannotClaimYet();
    error PhoenixAuction__LiquidityAlreadyAdded();
    error PhoenixAuction__NotStartedYet();
    error PhoenixAuction__NothingToClaim();
    error PhoenixAuction__AuctionEnded();
    error PhoenixAuction__NothingToEmit();

    event UserDeposit(address indexed user, uint256 indexed amount, uint256 indexed id);
    event UserClaimed(address indexed user, uint256 indexed phoenixAmount, uint256 indexed id);

    constructor(
        address _titanX,
        Phoenix _phoenix,
        address _titanXStakingVault,
        address _phoenixBnB,
        uint32 _startTimestamp
    ) {
        titanX = IERC20(_titanX);
        phoenix = Phoenix(_phoenix);
        phoenixBnB = _phoenixBnB;

        titanXStakingVault = _titanXStakingVault;

        startTimestamp = _startTimestamp;
    }

    function deposit(uint192 _amount) external notAmount0(_amount) {
        require(block.timestamp >= startTimestamp, PhoenixAuction__NotStartedYet());

        _updateAuction();

        uint32 daySinceStart = _daySinceStart();

        UserAuction storage userDeposit = depositOf[msg.sender][++depositId];

        DailyStatistic storage stats = dailyStats[daySinceStart];

        userDeposit.ts = uint32(block.timestamp);
        userDeposit.amount = _amount;
        userDeposit.day = daySinceStart;

        stats.titanXDeposited += uint128(_amount);

        _distribute(_amount);

        emit UserDeposit(msg.sender, _amount, depositId);
    }

    function claim(uint256 _id) public {
        UserAuction storage userDep = depositOf[msg.sender][_id];

        uint32 timePassedInThatDay = (userDep.ts - startTimestamp) % SECONDS_PER_DAY;

        ///@dev - If the user has deposited in the first 23 hours they can claim instantly, otherwise they have to wait extra hour to claim
        uint32 claimBuffer = timePassedInThatDay <= SECONDS_PER_DAY - 1 hours ? 0 : 1 hours;

        require(
            block.timestamp >= userDep.ts + (SECONDS_PER_DAY - timePassedInThatDay) + claimBuffer,
            PhoenixAuctionCannotClaimYet()
        );

        uint256 toClaim = amountToClaim(msg.sender, _id);

        if (toClaim == 0) revert PhoenixAuction__NothingToClaim();

        emit UserClaimed(msg.sender, toClaim, _id);

        phoenix.transfer(msg.sender, toClaim);

        userDep.amount = 0;
    }

    function batchClaim(uint256[] calldata _ids) external {
        for (uint256 i; i < _ids.length; ++i) {
            claim(_ids[i]);
        }
    }

    function batchClaimableAmount(address _user, uint256[] calldata _ids) public view returns (uint256 toClaim) {
        for (uint256 i; i < _ids.length; ++i) {
            toClaim += amountToClaim(_user, _ids[i]);
        }
    }

    function amountToClaim(address _user, uint256 _id) public view returns (uint256 toClaim) {
        UserAuction storage userDep = depositOf[_user][_id];
        DailyStatistic memory stats = dailyStats[userDep.day];

        return (userDep.amount * stats.phoenixEmitted) / stats.titanXDeposited;
    }

    function _distribute(uint256 _amount) internal {
        titanX.safeTransferFrom(msg.sender, phoenixBnB, wmul(_amount, uint256(0.8e18)));
        titanX.safeTransferFrom(msg.sender, GENESIS, wmul(_amount, uint256(0.05e18)));
        titanX.safeTransferFrom(msg.sender, titanXStakingVault, wmul(_amount, uint256(0.065e18)));

        PhoenixMinting minting = PhoenixMinting(phoenix.minting());

        titanX.safeTransferFrom(msg.sender, address(minting.fluxStakingVault()), wmul(_amount, uint256(0.065e18)));
        titanX.safeTransferFrom(msg.sender, address(minting.blazeStakingVault()), wmul(_amount, uint256(0.02e18)));
    }

    function _daySinceStart() internal view returns (uint32 daySinceStart) {
        daySinceStart = uint32(((block.timestamp - startTimestamp) / 24 hours) + 1);
    }

    /// @notice Emits the needed Phoenix
    function _updateAuction() internal {
        uint32 daySinceStart = _daySinceStart();

        if (dailyStats[daySinceStart].phoenixEmitted != 0) return;

        uint256 toEmit = AuctionTreasury(phoenix.auctionTreasury()).emitForAuction();

        require(toEmit != 0, PhoenixAuction__NothingToEmit());

        dailyStats[daySinceStart].phoenixEmitted = uint128(toEmit);
    }
}
