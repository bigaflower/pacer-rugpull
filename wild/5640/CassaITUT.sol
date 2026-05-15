// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Memory} from "@openzeppelin/contracts/utils/Memory.sol";
import {LowLevelCall} from "@openzeppelin/contracts/utils/LowLevelCall.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {ICassaERC20} from "cassa-interfaces/ICassaERC20.sol";
import {ICassaPolicy} from "cassa-interfaces/ICassaPolicy.sol";
import {ICassaITUT} from "cassa-interfaces/ICassaITUT.sol";
import {IAdmin} from "cassa-interfaces/utils/IAdmin.sol";
import {IFeeRate} from "cassa-interfaces/utils/IFeeRate.sol";

import {CassaERC20} from "./CassaERC20.sol";

contract CassaITUT is Pausable, ICassaITUT, IAdmin, IFeeRate {
    ICassaERC20 public immutable IT;
    ICassaERC20 public immutable UT;
    ICassaPolicy public immutable policy;

    uint256 public feeRate;
    address public feeReceiver;

    IERC20 internal immutable _asset;
    uint8 private immutable _underlyingDecimals;

    string internal _name;

    uint64 private _settlementRatio;
    bool private _isSettled;

    modifier onlyBeforeEffectiveDate() {
        require(block.timestamp < policy.effectiveDate(), "Action not allowed after policy effective date");
        _;
    }

    modifier onlyAfterEffectiveDate() {
        require(block.timestamp >= policy.effectiveDate(), "Action not allowed before policy effective date");
        _;
    }

    modifier onlyBeforeExpirationDate() {
        require(block.timestamp < policy.expirationDate(), "Action not allowed after policy expiration date");
        _;
    }

    modifier onlyAfterExpirationDate() {
        require(block.timestamp >= policy.expirationDate(), "Action not allowed before policy expiration date");
        _;
    }

    modifier onlyDuringPolicyPeriod() {
        require(
            block.timestamp >= policy.effectiveDate() && block.timestamp < policy.expirationDate(),
            "Action not allowed outside policy period"
        );
        _;
    }

    modifier onlyBeforeSettlement() {
        require(!_isSettled, "Action not allowed after settlement");
        _;
    }

    modifier onlyAfterSettlement() {
        require(_isSettled, "Action noy allowed before settlement");
        _;
    }

    modifier returnsZeroIfPaused() {
        if (paused()) {
            return;
        }
        _;
    }

    modifier onlyAdmin() {
        require(_msgSender() == admin(), "Caller is not the admin");
        _;
    }

    constructor(string memory __name, address __asset, address __policy) {
        _name = __name;
        _asset = IERC20(__asset);

        (bool success, uint8 assetDecimals) = _tryGetAssetDecimals(_asset);
        _underlyingDecimals = success ? assetDecimals : 18;
        uint8 _decimals = _underlyingDecimals + _decimalsOffset();

        IT = ICassaERC20(_deployInsuredToken(__name, _decimals));
        UT = ICassaERC20(_deployUnderwritingToken(__name, _decimals));
        policy = ICassaPolicy(__policy);
    }

    /// @dev  Attempts to fetch the asset decimals. A return value of false indicates that the attempt failed in some way.
    function _tryGetAssetDecimals(IERC20 asset_) private view returns (bool ok, uint8 assetDecimals) {
        Memory.Pointer ptr = Memory.getFreeMemoryPointer();
        (bool success, bytes32 returnedDecimals,) =
            LowLevelCall.staticcallReturn64Bytes(address(asset_), abi.encodeCall(IERC20Metadata.decimals, ()));
        Memory.setFreeMemoryPointer(ptr);

        return (success && LowLevelCall.returnDataSize() >= 32 && uint256(returnedDecimals) <= type(uint8).max)
            ? (true, uint8(uint256(returnedDecimals)))
            : (false, 0);
    }

    function _deployInsuredToken(string memory __name, uint8 _decimals) internal returns (address) {
        CassaERC20 token = new CassaERC20(
            string.concat(
                "Cassa Insured Token ",
                __name /* ... */
            ),
            string.concat(
                "IT-",
                __name /* ... */
            ),
            _decimals,
            address(this)
        );
        return address(token);
    }

    function _deployUnderwritingToken(string memory __name, uint8 _decimals) internal returns (address) {
        CassaERC20 token = new CassaERC20(
            string.concat(
                "Cassa Underwriting Token ",
                __name /* ... */
            ),
            string.concat(
                "UT-",
                __name /* ... */
            ),
            _decimals,
            address(this)
        );
        return address(token);
    }

    /// @inheritdoc ICassaITUT
    function asset() public view returns (address __asset) {
        return address(_asset);
    }

    function admin() public view virtual returns (address __admin) {
        return address(policy);
    }

    /// @inheritdoc ICassaITUT
    function name() external view returns (string memory __name) {
        return _name;
    }

    /// @inheritdoc ICassaITUT
    function maxDeposit(
        address /* receiver */
    )
        public
        view
        virtual
        returnsZeroIfPaused
        returns (uint256 max)
    {
        return type(uint256).max;
    }

    /// @inheritdoc ICassaITUT
    /// @dev {depositITUT} is not implemented
    function maxDepositITUT(
        address,
        /* vault */
        address /* receiver */
    )
        public
        view
        virtual
        returnsZeroIfPaused
        returns (uint256 max)
    {
        return 0;
    }

    /// @inheritdoc ICassaITUT
    function maxRedeem(address owner) public view virtual returnsZeroIfPaused returns (uint256 max) {
        return Math.min(IT.balanceOf(owner), UT.balanceOf(owner));
    }

    /// @inheritdoc ICassaITUT
    function maxRedeemIT(address owner) public view virtual returnsZeroIfPaused returns (uint256 max) {
        if (!_isSettled) {
            return 0;
        }
        return IT.balanceOf(owner);
    }

    /// @inheritdoc ICassaITUT
    function maxRedeemUT(address owner) public view virtual returnsZeroIfPaused returns (uint256 max) {
        if (!_isSettled) {
            return 0;
        }
        return UT.balanceOf(owner);
    }

    /// @inheritdoc ICassaITUT
    function previewDeposit(uint256 assets) public view virtual returns (uint256 tokens) {
        (tokens,) = _previewDeposit(assets);
        return tokens;
    }

    /// @inheritdoc ICassaITUT
    /// @dev {depositITUT} is not implemented
    function previewDepositITUT(address parent, uint256 amount) public view virtual returns (uint256 tokens) {
        return _previewDepositITUT(parent, amount);
    }

    /// @inheritdoc ICassaITUT
    function previewRedeem(uint256 tokens) public view virtual returns (uint256 assets) {
        return _previewRedeem(tokens);
    }

    /// @inheritdoc ICassaITUT
    function previewRedeemIT(uint256 tokens) public view virtual returns (uint256 assets) {
        return _previewRedeemIT(tokens);
    }

    /// @inheritdoc ICassaITUT
    function previewRedeemUT(uint256 tokens) public view virtual returns (uint256 assets) {
        return _previewRedeemUT(tokens);
    }

    /// @inheritdoc ICassaITUT
    function deposit(uint256 assets, address receiver)
        public
        virtual
        onlyBeforeExpirationDate
        whenNotPaused
        returns (uint256 tokens)
    {
        if (assets > maxDeposit(_msgSender())) {
            revert("Deposit exceeds maximum limit");
        }
        uint256 fee;
        (tokens, fee) = _previewDeposit(assets);
        _transferAssetsIn(_msgSender(), assets);
        if (fee > 0) _transferAssetsOut(feeReceiver, fee);
        IT.mint(receiver, tokens);
        UT.mint(receiver, tokens);
        return tokens;
    }

    /// @inheritdoc ICassaITUT
    /// @dev Not implemented
    function depositITUT(
        address,
        /* vault */
        uint256,
        /* amount */
        address /* receiver */
    )
        public
        virtual
        returns (
            uint256 /* tokens */
        )
    {
        revert("Not implemented");
    }

    /// @inheritdoc ICassaITUT
    function redeem(uint256 tokens, address receiver, address owner) public virtual returns (uint256 assets) {
        address caller = _msgSender();
        if (tokens > maxRedeem(owner)) {
            revert("Redeem exceeds maximum limit");
        }
        if (caller != owner) {
            IT.spendAllowance(owner, caller, tokens);
            UT.spendAllowance(owner, caller, tokens);
        }
        assets = _previewRedeem(tokens);
        IT.burn(owner, tokens);
        UT.burn(owner, tokens);
        _transferAssetsOut(receiver, assets);
        return assets;
    }

    /// @inheritdoc ICassaITUT
    function redeemIT(uint256 tokens, address receiver, address owner)
        public
        virtual
        onlyAfterSettlement
        returns (uint256 assets)
    {
        address caller = _msgSender();
        if (tokens > maxRedeemIT(owner)) {
            revert("Redeem exceeds maximum limit");
        }
        if (caller != owner) {
            IT.spendAllowance(owner, caller, tokens);
        }
        assets = _previewRedeemIT(tokens);
        IT.burn(owner, tokens);
        _transferAssetsOut(receiver, assets);
        return assets;
    }

    /// @inheritdoc ICassaITUT
    function redeemUT(uint256 tokens, address receiver, address owner)
        public
        virtual
        onlyAfterSettlement
        returns (uint256 assets)
    {
        address caller = _msgSender();
        if (tokens > maxRedeemUT(owner)) {
            revert("Redeem exceeds maximum limit");
        }
        if (caller != owner) {
            UT.spendAllowance(owner, caller, tokens);
        }
        assets = _previewRedeemUT(tokens);
        UT.burn(owner, tokens);
        _transferAssetsOut(receiver, assets);
        return assets;
    }

    function pause() public virtual onlyAdmin {
        _pause();
    }

    function unpause() public virtual onlyAdmin {
        _unpause();
    }

    /// @inheritdoc ICassaITUT
    function settle() public virtual onlyAfterExpirationDate onlyBeforeSettlement onlyAdmin {
        (uint256 ratio, bool isSettled, bool ok) = policy.settlementRatio();
        require(ok, "Failed to get settlement ratio from policy");
        require(isSettled, "Policy not settled");
        _settlementRatio = SafeCast.toUint64(ratio);
        _isSettled = true;
    }

    /// @inheritdoc ICassaITUT
    function settlementRatio() public view returns (uint256 __ratio, bool __isSettled) {
        return (uint256(_settlementRatio), _isSettled);
    }

    function setFeeRate(uint256 newFeeRate) external onlyAdmin {
        feeRate = newFeeRate;
    }

    function setFeeReceiver(address newFeeReceiver) external onlyAdmin {
        feeReceiver = newFeeReceiver;
    }

    function _transferAssetsIn(address from, uint256 amount) internal virtual {
        SafeERC20.safeTransferFrom(_asset, from, address(this), amount);
    }

    function _transferAssetsOut(address to, uint256 amount) internal virtual {
        SafeERC20.safeTransfer(_asset, to, amount);
    }

    /// @dev Decimal convert from tokens to assets, rounding down
    function _convertToAssets(uint256 tokens) internal view virtual returns (uint256 assets) {
        return tokens / 10 ** _decimalsOffset();
    }

    /// @dev Decimal convert from assets to tokens
    function _convertToTokens(uint256 assets) internal view virtual returns (uint256 tokens) {
        return assets * 10 ** _decimalsOffset();
    }

    function _previewDeposit(uint256 assets) internal view virtual returns (uint256 tokens, uint256 fee) {
        fee = feeReceiver == address(0) ? 0 : Math.mulDiv(assets, feeRate, 1e18, Math.Rounding.Ceil);
        return (_convertToTokens(assets - fee), fee);
    }

    function _previewDepositITUT(
        address,
        /* vault */
        uint256 /* amount */
    )
        internal
        view
        virtual
        returns (uint256 tokens)
    {
        return 0;
    }

    function _previewRedeem(uint256 tokens) internal view virtual returns (uint256 assets) {
        return _convertToAssets(tokens);
    }

    function _previewRedeemIT(uint256 tokens) internal view virtual returns (uint256 assets) {
        if (!_isSettled) {
            return 0;
        }
        return _convertToAssets(Math.mulDiv(_settlementRatio, tokens, 1e18));
    }

    function _previewRedeemUT(uint256 tokens) internal view virtual returns (uint256 assets) {
        if (!_isSettled) {
            return 0;
        }
        uint256 inverseRatio = 1e18 - _settlementRatio;
        return _convertToAssets(Math.mulDiv(inverseRatio, tokens, 1e18));
    }

    function _decimalsOffset() internal view virtual returns (uint8 offset) {
        return _underlyingDecimals >= 18 ? 0 : 18 - _underlyingDecimals;
    }
}
