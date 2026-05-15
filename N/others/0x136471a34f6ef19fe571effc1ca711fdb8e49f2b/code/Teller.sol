/**
 * Copyright 2025 Circle Internet Group, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

// imported contracts and libraries
import {Access} from "../entitlements/Access.sol";
import {BokkyPooBahsDateTimeLibrary as DateTimeUtil} from "bpb-dateTime/BokkyPooBahsDateTimeLibrary.sol";
import {DaylightSavingsCalendar} from "./calendars/DaylightSavingsCalendar.sol";
import {DaylightSavingsLibrary} from "./calendars/DaylightSavingsLibrary.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {Ownable} from "../entitlements/Ownable.sol";
import {Math} from "openzeppelin/utils/math/Math.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// interfaces
import {IToken} from "../../interfaces/IToken.sol";
import {IOracle} from "../../interfaces/IOracle.sol";

import "../../config/constants.sol";
import "../../config/errors.sol";
import "../../config/types.sol";

/**
 * @title   Token Teller 3
 * @author  dsshap (Circle)
 * @dev     Provides liquidity for Share/Asset pair.
 */
contract Teller is Access, Initializable, Ownable, UUPSUpgradeable {
    using DaylightSavingsLibrary for DaylightSavingsCalendar;
    using Math for uint256;
    using DateTimeUtil for uint256;
    using SafeERC20 for IToken;

    /*///////////////////////////////////////////////////////////////
                        Constants & Immutables
    //////////////////////////////////////////////////////////////*/

    /// @notice Data contract encoding DST start/end timestamps through 2123.
    DaylightSavingsCalendar public immutable dst;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
    event Subscribe(address indexed from, address indexed receiver, uint256 assets, uint256 shares, uint256 price, uint256 fee);
    event Redeem(address indexed from, address indexed receiver, uint256 assets, uint256 shares, uint256 price, uint256 fee);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Sweep(address indexed token, address indexed treasury, uint256 amount, address indexed recipient);
    event FeesSet(address indexed owner, uint256 subscribe, uint256 newSubscribe, uint256 redeem, uint256 newRedeem);
    event OracleSet(address indexed oracle, address indexed newOracle);
    event TreasurySet(address indexed owner, address treasury, address newTreasury);
    event FeeRecipientSet(address indexed feeRecipient, address indexed newFeeRecipient);
    event AfterHourTradingSet(uint256 afterHourTrading, uint256 newAfterHourTrading);
    event LimitsSet(address indexed owner, uint256 subscribe, uint256 newSubscribe, uint256 redeem, uint256 newRedeem);

    /*///////////////////////////////////////////////////////////////
                                Structures
    //////////////////////////////////////////////////////////////*/

    struct FeeSchedule {
        uint64 subscribe;
        uint64 redeem;
    }

    struct Limit {
        uint56 subscribe;
        uint56 redeem;
    }

    /*///////////////////////////////////////////////////////////////
                         State Variables V1
    //////////////////////////////////////////////////////////////*/

    IToken public asset;

    IToken public share;

    IOracle public oracle;

    uint256 private _oracleScale;

    address public feeRecipient;

    /// @notice investor fee schedule
    mapping(address => FeeSchedule) public feeSchedule;

    /// @notice after hour trading
    uint256 public afterHourTrading;

    /// @notice allowance for owners USYC to be redeem/withdraw on their behalf
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice investor specific treasury
    mapping(address => address) private _treasury;

    /// @notice investor specific subscription and redemption limits
    mapping(address => Limit) public limit;

    /// @notice investor subscription amount per day
    mapping(address => mapping(uint256 => uint256)) public subscription;

    /// @notice investor redemption amount per day
    mapping(address => mapping(uint256 => uint256)) public redemption;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[50] private __gap0;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _authority, address _dst) Access(_authority) {
        if (_dst == address(0)) revert BadAddress();

        _disableInitializers();

        dst = DaylightSavingsCalendar(_dst);
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(TellerConfig calldata config) external initializer {
        __Teller_init(config);
    }

    function __Teller_init(TellerConfig calldata config) internal onlyInitializing {
        if (config.owner == address(0)) revert BadAddress();
        if (config.asset == address(0)) revert BadAddress();
        if (config.share == address(0)) revert BadAddress();
        if (config.oracle == address(0)) revert BadAddress();
        if (config.treasury == address(0)) revert BadAddress();
        if (config.feeRecipient == address(0)) revert BadAddress();

        _transferOwnership(config.owner);

        asset = IToken(config.asset);
        share = IToken(config.share);

        if (asset.decimals() != share.decimals()) revert BadDecimals();

        oracle = IOracle(config.oracle);
        _oracleScale = 10 ** oracle.decimals();
        _treasury[address(0)] = config.treasury;
        feeRecipient = config.feeRecipient;
        feeSchedule[address(0)] = FeeSchedule(config.subscribeFee, config.redeemFee);
        afterHourTrading = config.afterHourTrading;
        limit[address(0)] = Limit(config.subscribeLimit, config.redeemLimit);
    }

    /*//////////////////////////////////////////////////////////////
                                VAULT ACTIONS
    //////////////////////////////////////////////////////////////*/

    function _inbound(address account, uint256 assets, uint256 shares, uint256 fee, address receiver) internal virtual {
        uint256 today = todayTimestamp();
        uint256 remaining = subscriptionLimitRemaining(account, today);
        if (remaining < assets) revert LimitExceeded();
        subscription[account][today] += assets;

        address treasury_ = treasury(account);
        asset.safeTransferFrom(account, treasury_, assets - fee);
        if (fee > 0) asset.safeTransferFrom(account, feeRecipient, fee);

        share.mint(receiver, shares);
    }

    function _deposit(uint256 assets, address receiver, address account) internal virtual returns (uint256 shares) {
        uint256 fee;
        int256 price;
        (shares, fee, price) = previewDepositData(account, assets);

        if (shares == 0) revert ZeroShares();

        _assertPermission(account);
        _assertCanReceive(address(share), receiver);

        _inbound(account, assets, shares, fee, receiver);

        emit Deposit(account, receiver, assets, shares);
        emit Subscribe(account, receiver, assets, shares, uint256(price), fee);
    }

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        return _deposit(assets, receiver, msg.sender);
    }

    function depositWithPermit(uint256 assets, address receiver, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        public
        virtual
        returns (uint256 shares)
    {
        return depositWithPermit(assets, receiver, deadline, abi.encodePacked(r, s, v));
    }

    function depositWithPermit(uint256 assets, address receiver, uint256 deadline, bytes memory signature)
        public
        virtual
        returns (uint256 shares)
    {
        asset.permit(receiver, address(this), assets, deadline, signature);
        return _deposit(assets, receiver, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        uint256 fee;
        int256 price;
        (assets, fee, price) = previewMintData(msg.sender, shares);

        if (assets == 0) revert ZeroAssets();

        _assertPermission(msg.sender);
        _assertCanReceive(address(share), receiver);

        _inbound(msg.sender, assets, shares, fee, receiver);

        emit Deposit(msg.sender, receiver, assets, shares);
        emit Subscribe(msg.sender, receiver, assets, shares, uint256(price), fee);
    }

    function _outbound(address account, uint256 assets, uint256 shares, uint256 fee, address receiver) internal virtual {
        uint256 today = todayTimestamp();
        uint256 remaining = redemptionLimitRemaining(account, today);
        if (remaining < assets) revert LimitExceeded();
        redemption[account][today] += assets;

        share.burn(account, shares);

        address treasury_ = treasury(account);
        asset.safeTransferFrom(treasury_, receiver, assets);
        if (fee > 0) asset.safeTransferFrom(treasury_, feeRecipient, fee);
    }

    function withdraw(uint256 assets, address receiver, address account) public virtual returns (uint256 shares) {
        uint256 fee;
        int256 price;
        (shares, fee, price) = previewWithdrawData(account, assets);

        if (shares == 0) revert ZeroShares();

        _spendAllowance(account, shares);
        _assertPermission(msg.sender);
        _assertCanReceive(address(share), account, receiver);

        _outbound(account, assets, shares, fee, receiver);

        emit Withdraw(msg.sender, receiver, account, assets, shares);
        emit Redeem(account, receiver, assets, shares, uint256(price), fee);
    }

    function redeem(uint256 shares, address receiver, address account) public virtual returns (uint256 assets) {
        _spendAllowance(account, shares);

        uint256 fee;
        int256 price;
        (assets, fee, price) = previewRedeemData(account, shares);

        if (assets == 0) revert ZeroAssets();

        _assertPermission(msg.sender);
        _assertCanReceive(address(share), account, receiver);

        _outbound(account, assets, shares, fee, receiver);

        emit Withdraw(msg.sender, receiver, account, assets, shares);
        emit Redeem(account, receiver, assets, shares, uint256(price), fee);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _assertPermission(msg.sender);

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice Returns treasury for an account
     * @dev if no treasury set for account then the public treasury is returned
     *      the public treasury is set at address(0)
     * @param account address of investor
     * @return treasuryAddr address of treasury
     */
    function treasury(address account) public view virtual returns (address treasuryAddr) {
        if ((treasuryAddr = _treasury[account]) == address(0)) treasuryAddr = _treasury[address(0)];
    }

    /*//////////////////////////////////////////////////////////////
                                ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns assets available for redemptions
     * @dev if called offchain this returns public assets available for redemptions
     *      if called onchain this returns the assets available for redemptions by msg.sender
     * @return assets available for redemptions
     */
    function totalAssets() public view virtual returns (uint256) {
        return totalAssets(msg.sender);
    }

    /**
     * @notice Returns assets available for redemptions by account
     * @dev returns which ever is lowest: the balance of the asset in the treasury or the allowance
     *      the public treasury is set at address(0)
     * @param account address of investor
     * @return assets available for redemptions
     */
    function totalAssets(address account) public view virtual returns (uint256) {
        return asset.balanceOf(treasury(account)).min(asset.allowance(treasury(account), address(this)));
    }

    /**
     * @notice Returns the current price for minting USYC
     * @dev The price is in oracle decimals
     * @return price the price from the oracle
     */
    function mintPrice() public view virtual returns (int256 price) {
        // current price in terms of USD
        uint256 updatedAt;
        (, price,, updatedAt,) = oracle.latestRoundData();

        uint256 afterHour = afterHourTrading;
        if (afterHour == AFTER_HOURS_DISABLED) return price;

        uint256 afterHourH = afterHour / 100;
        uint256 afterHourM = afterHour % 100;

        uint256 currentTime = _eT(block.timestamp);
        (uint256 updatedY, uint256 updatedM, uint256 updatedD) = _eT(updatedAt).timestampToDate();
        (uint256 nowY, uint256 nowM, uint256 nowD) = currentTime.timestampToDate();

        // if price was not updated today OR in after hour trading, then use next price
        if (
            updatedY != nowY || updatedM != nowM || updatedD != nowD || currentTime.getHour() > afterHourH
                || (currentTime.getHour() == afterHourH && currentTime.getMinute() >= afterHourM)
        ) {
            price = oracle.nextPrice();
        }
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256 shares) {
        shares = assets.mulDiv(_oracleScale, uint256(mintPrice()));
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256 assets) {
        (, int256 price,,,) = oracle.latestRoundData();
        assets = shares.mulDiv(uint256(price), _oracleScale);
    }

    /**
     * @notice Gets the subscription fee rate
     * @dev If individual account rate is not set (aka 0) then uses default rate
     *      If rate is set to type(uint64).max, then fee rate is 0
     * @return rate the rate to be charged
     */
    function subscriptionFeeRate(address account) public view virtual returns (uint256 rate) {
        if ((rate = feeSchedule[account].subscribe) == 0) rate = feeSchedule[address(0)].subscribe;
        else if (rate == type(uint64).max) return 0;
    }

    /**
     * @notice Gets the redemption fee rate
     * @dev If individual account rate is not set (aka 0) then uses default rate
     *      If rate is set to type(uint64).max, then fee rate is 0
     * @return rate the rate to be charged
     */
    function redemptionFeeRate(address account) public view virtual returns (uint256 rate) {
        if ((rate = feeSchedule[account].redeem) == 0) rate = feeSchedule[address(0)].redeem;
        else if (rate == type(uint64).max) return 0;
    }

    /**
     * @notice Gets the remaining subscription amount
     * @dev If individual limit is not set (aka 0) then uses default rate
     * @return assets the amount of assets that can be subscribed
     */
    function subscriptionLimitRemaining(address account, uint256 date) public view virtual returns (uint256 assets) {
        if ((assets = limit[account].subscribe) == 0) assets = limit[address(0)].subscribe;
        uint256 current = subscription[account][date];
        if (current > assets) return 0; // if subscription limit was reduced during the day to less than current
        else return assets - current;
    }

    /**
     * @notice Gets the remaining redemption amount
     * @dev If individual limit is not set (aka 0) then uses default rate
     * @return assets the amount of assets that can be redeemed
     */
    function redemptionLimitRemaining(address account, uint256 date) public view virtual returns (uint256 assets) {
        if ((assets = limit[account].redeem) == 0) assets = limit[address(0)].redeem;
        uint256 current = redemption[account][date];
        if (current > assets) return 0; // if redemption limit was reduced during the day to less than current
        else return assets - current;
    }

    function previewDepositData(address account, uint256 assets)
        public
        view
        virtual
        returns (uint256 shares, uint256 fee, int256 price)
    {
        fee = subscriptionFeeRate(account);
        uint256 netAssets = fee > 0 ? assets.mulDiv(HUNDRED_PCT, HUNDRED_PCT + fee) : assets;
        fee = assets - netAssets;

        price = mintPrice();
        shares = netAssets.mulDiv(_oracleScale, uint256(price));
    }

    function previewDeposit(uint256 assets) external view virtual returns (uint256 shares) {
        (shares,,) = previewDepositData(msg.sender, assets);
    }

    function previewMintData(address account, uint256 shares)
        public
        view
        virtual
        returns (uint256 assets, uint256 fee, int256 price)
    {
        price = mintPrice();
        assets = shares.mulDiv(uint256(price), _oracleScale, Math.Rounding.Up);
        fee = assets.mulDiv(subscriptionFeeRate(account), HUNDRED_PCT, Math.Rounding.Up);
        assets += fee;
    }

    function previewMint(uint256 shares) external view virtual returns (uint256 assets) {
        (assets,,) = previewMintData(msg.sender, shares);
    }

    function previewWithdrawData(address account, uint256 assets)
        public
        view
        virtual
        returns (uint256 shares, uint256 fee, int256 price)
    {
        fee = assets.mulDiv(redemptionFeeRate(account), HUNDRED_PCT, Math.Rounding.Up);
        assets += fee;
        (, price,,,) = oracle.latestRoundData();
        shares = assets.mulDiv(_oracleScale, uint256(price), Math.Rounding.Up);
    }

    function previewWithdraw(uint256 assets) external view virtual returns (uint256 shares) {
        (shares,,) = previewWithdrawData(msg.sender, assets);
    }

    function previewRedeemData(address account, uint256 shares)
        public
        view
        virtual
        returns (uint256 assets, uint256 fee, int256 price)
    {
        (, price,,,) = oracle.latestRoundData();
        assets = shares.mulDiv(uint256(price), _oracleScale);

        fee = redemptionFeeRate(account);
        uint256 netAssets = fee > 0 ? assets.mulDiv(HUNDRED_PCT, HUNDRED_PCT + fee) : assets;
        fee = assets - netAssets;

        assets -= fee;
    }

    function previewRedeem(uint256 shares) external view virtual returns (uint256 assets) {
        (assets,,) = previewRedeemData(msg.sender, shares);
    }

    /*//////////////////////////////////////////////////////////////
                                MAXIMUMS
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address account) public view virtual returns (uint256 maxAssets) {
        return asset.balanceOf(account).min(subscriptionLimitRemaining(account, todayTimestamp()));
    }

    function maxMint(address account) public view virtual returns (uint256 maxShares) {
        return convertToShares(maxDeposit(account));
    }

    function maxWithdraw(address account) public view virtual returns (uint256 maxAssets) {
        maxAssets = convertToAssets(share.balanceOf(account));
        uint256 totalAssets_ = totalAssets(account).min(redemptionLimitRemaining(account, todayTimestamp()));
        if (maxAssets > totalAssets_) maxAssets = totalAssets_;
    }

    function maxRedeem(address account) public view virtual returns (uint256 maxShares) {
        (, int256 price,,,) = oracle.latestRoundData();
        maxShares =
            totalAssets(account).min(redemptionLimitRemaining(account, todayTimestamp())).mulDiv(_oracleScale, uint256(price));
        uint256 totalShares = share.balanceOf(account);
        if (maxShares > totalShares) maxShares = totalShares;
    }

    /*///////////////////////////////////////////////////////////////
                        LIQUIDITY MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sweep tokens from teller to recipient
     * @param token is the address of the token to transfer
     * @param account is the address of the account tied to a treasury
     * @param amount is the amount of token to transfer
     * @param recipient is the address to send token to
     */
    function sweep(address token, address account, uint256 amount, address recipient) external virtual {
        if (amount == 0) revert BadAmount();

        _assertFundAdmin();

        if (!authority.doesUserHaveRole(recipient, ROLE_RESERVES)) revert NotPermissioned();

        address treasury_ = account == address(this) ? address(this) : treasury(account);

        if (treasury_ == address(this)) IToken(token).safeTransfer(recipient, amount);
        else IToken(token).safeTransferFrom(treasury_, recipient, amount);

        emit Sweep(token, treasury_, amount, recipient);
    }

    /*///////////////////////////////////////////////////////////////
                    DST & Time Conversion Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns timestamp at the start of the day (UTC)
     * @dev Capturing the timestamp at the start of UTC day.
     *      We get the timestamp then get the date from `timestampToDate`,
     *      then we get the timestamp of that date from `timestampFromDate`,
     */
    function todayTimestamp() public view returns (uint256) {
        (uint256 year, uint256 month, uint256 day) = block.timestamp.timestampToDate();
        return DateTimeUtil.timestampFromDate(year, month, day);
    }

    /**
     * @notice Return true if it's Daylight Savings Time in New York
     */
    function isDST() public view virtual returns (bool) {
        // The DST calendar stores exact timestamps for start/end of DST in New York
        uint256 year = block.timestamp.getYear();
        (uint256 start, uint256 end) = dst.getTimestamps(year);
        return block.timestamp >= start && block.timestamp < end;
    }

    /**
     * @notice Return time in New York
     */
    function _eT(uint256 timestamp) internal view virtual returns (uint256) {
        // Adjusts datetime to US Eastern Time
        return timestamp - _etOffset();
    }

    /**
     * @notice Return timezone offset in New York
     * @dev ensure applied to UTC timestamp
     */
    function _etOffset() internal view virtual returns (uint256) {
        return isDST() ? 4 hours : 5 hours;
    }

    /*///////////////////////////////////////////////////////////////
                        Internal Functions
    //////////////////////////////////////////////////////////////*/

    function _spendAllowance(address account, uint256 shares) internal {
        if (msg.sender != account && !_isFundAdmin()) {
            uint256 allowed = allowance[account][msg.sender];

            if (allowed != type(uint256).max) allowance[account][msg.sender] = allowed - shares;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets oracle address
     * @param _oracle address of oracle
     */
    function setOracle(address _oracle) external {
        _assertFundAdmin();

        if (_oracle == address(0)) revert BadAddress();

        emit OracleSet(address(oracle), _oracle);

        oracle = IOracle(_oracle);
        _oracleScale = 10 ** oracle.decimals();
    }

    /**
     * @notice Sets treasury address
     * @param account address of account
     * @param treasuryAddr address of treasury
     */
    function setTreasury(address account, address treasuryAddr) external {
        _assertFundAdmin();

        emit TreasurySet(account, _treasury[account], treasuryAddr);

        _treasury[account] = treasuryAddr;
    }

    /**
     * @notice Sets fee recipient address
     * @param _feeRecipient address of recipient
     */
    function setFeeRecipient(address _feeRecipient) external {
        _assertFundAdmin();

        if (_feeRecipient == address(0)) revert BadAddress();

        emit FeeRecipientSet(feeRecipient, _feeRecipient);

        feeRecipient = _feeRecipient;
    }

    /**
     * @notice Sets fees for subscribing and redeeming
     * @dev fees are in bps, 18 decimals, max fee is 2.5%
     *      to set default fees, use address(0) for _account
     * @param _account address of account
     * @param _subscribe fees for subscribing
     * @param _redeem fees for redeeming
     */
    function setFees(address _account, uint64 _subscribe, uint64 _redeem) external {
        _assertFundAdmin();

        FeeSchedule memory schedule = feeSchedule[_account];

        emit FeesSet(_account, schedule.subscribe, _subscribe, schedule.redeem, _redeem);

        feeSchedule[_account] = FeeSchedule(_subscribe, _redeem);
    }

    /**
     * @notice Sets limits for subscribing and redeeming
     * @dev limits are in terms of asset
     *      to set default limit, use address(0) for _account
     * @param _account address of account
     * @param _subscribe limit for subscribing
     * @param _redeem limit for redeeming
     */
    function setLimits(address _account, uint56 _subscribe, uint56 _redeem) external {
        _assertFundAdmin();

        Limit memory limit_ = limit[_account];

        emit LimitsSet(_account, limit_.subscribe, _subscribe, limit_.redeem, _redeem);

        limit[_account] = Limit(_subscribe, _redeem);
    }

    /**
     * @notice Sets after hours trading
     * @dev value set as hhmm in 24h format, e.g. 1700 for 5pm
     * if value is type(uint256).max, then turns off after hour pricing
     * @param hourMinute hour and minute
     */
    function setAfterHourTrading(uint256 hourMinute) external {
        _assertFundAdmin();

        if (hourMinute != AFTER_HOURS_DISABLED) if (hourMinute / 100 > 23 || hourMinute % 100 > 59) revert BadTime();

        emit AfterHourTradingSet(afterHourTrading, hourMinute);

        afterHourTrading = hourMinute;
    }

    /*///////////////////////////////////////////////////////////////
                        Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(
        address /*newImplementation*/
    )
        internal
        virtual
        override
    {
        _assertOwner();
    }
}
