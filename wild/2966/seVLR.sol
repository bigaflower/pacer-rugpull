// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// Contracts
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ERC20Votes } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import { TimeLockedERC20 } from "./token/TimeLockedERC20.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

// Interfaces
import { ISeVLR } from "./interfaces/ISeVLR.sol";
import { IBalancerVault } from "./interfaces/IBalancerVault.sol";
import { IWeightedPool } from "./interfaces/IWeightedPool.sol";

// Libraries
import { SafeTransferLib } from "solady/src/utils/SafeTransferLib.sol";
import { ERC20UtilsLib } from "./libraries/ERC20UtilsLib.sol";

/// @title seVLR Staking Token
/// @author Laita Labs
/// @notice Staking token for Project Miro.
///         Utilizes `TimeLockedERC20` to lock `20WETH/80VLR` liquidity tokens
///         and `ERC20Votes` for DAO voting capabilities.
contract SeVLR is ISeVLR, ERC20Votes, TimeLockedERC20 {
    /*//////////////////////////////////////////////////////////////
                              LIBRARIES
    //////////////////////////////////////////////////////////////*/

    using SafeTransferLib for address;
    using ERC20UtilsLib for address;

    /*//////////////////////////////////////////////////////////////
                             CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Staked token name
    string private constant NAME = "Social Escrowed 20WETH-80VLR BPT";

    /// @notice Staked token symbol
    string private constant SYMBOL = "seVLR";

    /// @notice Balancer Vault address
    address public immutable BALANCER_VAULT;

    /// @notice VLR token address
    address public immutable VLR;

    /// @notice WETH token address
    address public immutable WETH;

    /// @notice 20WETH-80VLR BPT liquidity token address
    address public immutable BPT;

    /// @notice 20WETH-80VLR BPT liquidity pool id
    bytes32 private immutable WETH20_VLR80_POOL_ID;

    /// @notice WeightedPool's ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT
    uint256 private constant EXACT_BPT_IN_FOR_TOKENS_OUT = 1;

    /// @notice WeightedPool's JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT
    uint256 private constant EXACT_TOKENS_IN_FOR_BPT_OUT = 1;

    /*//////////////////////////////////////////////////////////////
                         CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @param asset 20WETH-80VLR BPT liquidity token address
    /// @param timeLockDuration Lock duration for token deposits in seconds
    /// @param minTimeLockDuration Minimum lock duration for token deposits
    /// @param maxTimeLockDuration Maximum lock duration for token deposits
    /// @param balancerVault Balancer Vault address
    /// @param vlr VLR token address
    /// @param weth WETH token address
    /// @param admin Address to grant admin role to
    constructor(
        address asset,
        uint256 timeLockDuration,
        uint256 minTimeLockDuration,
        uint256 maxTimeLockDuration,
        address balancerVault,
        address vlr,
        address weth,
        address admin
    ) TimeLockedERC20(NAME, SYMBOL, asset, timeLockDuration, minTimeLockDuration, maxTimeLockDuration, admin) {
        BALANCER_VAULT = balancerVault;
        VLR = vlr;
        WETH = weth;
        BPT = asset;
        WETH20_VLR80_POOL_ID = IWeightedPool(asset).getPoolId();
    }

    /*//////////////////////////////////////////////////////////////
                          DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISeVLR
    function depositVLRAndEth(
        uint256 vlrAmount,
        uint256 minBptOut,
        address beneficiary,
        bytes calldata vlrPermit
    ) external payable {
        VLR.permit(vlrPermit);

        VLR.safeTransferFrom(msg.sender, address(this), vlrAmount);

        uint256 bptAmount = _joinPool(vlrAmount, msg.value, minBptOut, false);

        if (beneficiary == address(0)) {
            beneficiary = msg.sender;
        }

        _deposit(bptAmount, beneficiary);
    }

    /// @inheritdoc ISeVLR
    function depositVLRAndWeth(
        uint256 vlrAmount,
        uint256 wethAmount,
        uint256 minBptOut,
        address beneficiary,
        bytes calldata vlrPermit
    ) external {
        VLR.permit(vlrPermit);

        VLR.safeTransferFrom(msg.sender, address(this), vlrAmount);
        WETH.safeTransferFrom(msg.sender, address(this), wethAmount);

        uint256 bptAmount = _joinPool(vlrAmount, wethAmount, minBptOut, true);

        if (beneficiary == address(0)) {
            beneficiary = msg.sender;
        }

        _deposit(bptAmount, beneficiary);
    }

    /*//////////////////////////////////////////////////////////////
                          WITHDRAWAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISeVLR
    function withdrawVLRAndEth(
        uint256 id,
        uint256 minVLRAmount,
        uint256 minEthAmount
    ) external returns (uint256 vlrAmount, uint256 ethAmount) {
        uint256 bptAmount = _withdraw(id);
        (ethAmount, vlrAmount) = _exitPool(bptAmount, minVLRAmount, minEthAmount, false);

        VLR.safeTransfer(msg.sender, vlrAmount);
        msg.sender.safeTransferETH(ethAmount);
    }

    /// @inheritdoc ISeVLR
    function withdrawVLRAndWeth(
        uint256 id,
        uint256 minVLRAmount,
        uint256 minEthAmount
    ) external returns (uint256 vlrAmount, uint256 wethAmount) {
        uint256 bptAmount = _withdraw(id);
        (wethAmount, vlrAmount) = _exitPool(bptAmount, minVLRAmount, minEthAmount, true);

        VLR.safeTransfer(msg.sender, vlrAmount);
        WETH.safeTransfer(msg.sender, wethAmount);
    }

    /// @inheritdoc ISeVLR
    function withdrawVLRAndEthMulti(
        uint256[] calldata ids,
        uint256 minVlrAmount,
        uint256 minEthAmount
    ) external returns (uint256 vlrAmount, uint256 ethAmount) {
        uint256 bptAmount;

        // Nothing can overflow
        unchecked {
            for (uint256 i; i < ids.length; i++) {
                bptAmount += _withdraw(ids[i]);
            }
        }

        (ethAmount, vlrAmount) = _exitPool(bptAmount, minVlrAmount, minEthAmount, false);

        VLR.safeTransfer(msg.sender, vlrAmount);
        msg.sender.safeTransferETH(ethAmount);
    }

    /// @inheritdoc ISeVLR
    function withdrawVLRAndWethMulti(
        uint256[] calldata ids,
        uint256 minVlrAmount,
        uint256 minWethAmount
    ) external returns (uint256 vlrAmount, uint256 wethAmount) {
        uint256 bptAmount;

        // Nothing can overflow
        unchecked {
            for (uint256 i; i < ids.length; i++) {
                bptAmount += _withdraw(ids[i]);
            }
        }

        (wethAmount, vlrAmount) = _exitPool(bptAmount, minVlrAmount, minWethAmount, true);

        VLR.safeTransfer(msg.sender, vlrAmount);
        WETH.safeTransfer(msg.sender, wethAmount);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @notice Internal function to join 20WETH-80VLR Pool during deposits
    /// @param vlrAmount VLR token amount
    /// @param ethAmount ETH/WETH amount
    /// @param minBptOut Minimum liquidity tokens to receive after joining
    /// @param isWeth Indicates if deposit is with WETH or ETH
    function _joinPool(
        uint256 vlrAmount,
        uint256 ethAmount,
        uint256 minBptOut,
        bool isWeth
    ) internal returns (uint256 bptAmount) {
        uint256[] memory amountsIn = new uint256[](2);
        amountsIn[0] = ethAmount;
        amountsIn[1] = vlrAmount;

        address[] memory assets = new address[](2);
        assets[0] = isWeth ? address(WETH) : address(0);
        assets[1] = address(VLR);

        if (WETH > VLR) {
            // Balancer Pool Pair is reversed
            (assets[0], assets[1]) = (assets[1], assets[0]);
            (amountsIn[0], amountsIn[1]) = (amountsIn[1], amountsIn[0]);
        }

        bytes memory userDataEncoded = abi.encode(EXACT_TOKENS_IN_FOR_BPT_OUT, amountsIn, minBptOut);

        IBalancerVault.JoinPoolRequest memory joinRequest = IBalancerVault.JoinPoolRequest({
            assets: assets,
            maxAmountsIn: amountsIn,
            userData: userDataEncoded,
            fromInternalBalance: false
        });

        uint256 bptBalanceBefore = BPT.getBalance();

        VLR.safeApprove(BALANCER_VAULT, vlrAmount);
        if (isWeth) {
            WETH.safeApprove(BALANCER_VAULT, ethAmount);
            IBalancerVault(BALANCER_VAULT).joinPool(WETH20_VLR80_POOL_ID, address(this), address(this), joinRequest);
        } else {
            IBalancerVault(BALANCER_VAULT).joinPool{ value: ethAmount }(
                WETH20_VLR80_POOL_ID,
                address(this),
                address(this),
                joinRequest
            );
        }

        bptAmount = BPT.getBalance() - bptBalanceBefore;
    }

    /// @notice Internal function to exit 20WETH-80VLR Pool during withdrawal
    /// @param bptAmount Liquidity token amount to withdraw
    /// @param minVlrAmount Minimum VLR token amount to receive
    /// @param minEthAmount Minimum ETH/WETH amount to receive
    /// @param isWeth Indicates if withdrawal is with WETH or ETH
    function _exitPool(
        uint256 bptAmount,
        uint256 minVlrAmount,
        uint256 minEthAmount,
        bool isWeth
    ) internal returns (uint256 ethAmount, uint256 vlrAmount) {
        uint256[] memory minAmountsOut = new uint256[](2);
        minAmountsOut[0] = minEthAmount;
        minAmountsOut[1] = minVlrAmount;

        address[] memory assets = new address[](2);
        assets[0] = isWeth ? address(WETH) : address(0);
        assets[1] = address(VLR);

        if (WETH > VLR) {
            // Balancer Pool Pair is reversed
            (assets[0], assets[1]) = (assets[1], assets[0]);
            (minAmountsOut[0], minAmountsOut[1]) = (minAmountsOut[1], minAmountsOut[0]);
        }

        bytes memory userDataEncoded = abi.encode(EXACT_BPT_IN_FOR_TOKENS_OUT, bptAmount);

        IBalancerVault.ExitPoolRequest memory exitRequest = IBalancerVault.ExitPoolRequest({
            assets: assets,
            minAmountsOut: minAmountsOut,
            userData: userDataEncoded,
            toInternalBalance: false
        });

        IBalancerVault(BALANCER_VAULT).exitPool(
            WETH20_VLR80_POOL_ID,
            address(this),
            payable(address(this)),
            exitRequest
        );

        vlrAmount = VLR.balanceOf(address(this));
        ethAmount = isWeth ? WETH.balanceOf(address(this)) : address(this).balance;
    }

    /*//////////////////////////////////////////////////////////////
                          OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /// @dev Override required by Solidity compiler
    function _update(address from, address to, uint256 value) internal override(TimeLockedERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    /// @dev Override required by Solidity compiler
    function nonces(address owner) public view virtual override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          RECEIVE
    //////////////////////////////////////////////////////////////*/

    /// @dev To allow the contract to receive ETH
    receive() external payable {}
}
