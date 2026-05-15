//SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract ESRV1 is Initializable, UUPSUpgradeable, Ownable2StepUpgradeable {
    /* Type declarations */
    mapping(uint256 timestamp => int256 esr) private _esrFromDate;

    /* State variables */
    uint256 public immutable ESR_PUBLISH_FREQUENCY = 1 days;
    string private constant _name = "Treehouse Ethereum Staking Rate - Spot";
    string private constant _symbol = "TESR";
    uint8 private immutable _decimals = 9;
    int256 private _latestESR = 0;
    uint256 private _latestESRDate = 0;
    uint256 private _esrStartDay = 0;

    /* Events */
    event ESRUpdate(uint256 indexed observationDate, address publisher, int256 esr);

    /* Functions */
    /**
     * @custom:oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __UUPSUpgradeable_init();
    }

    /**
     * @dev Returns the name of the DOR
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the DOR, usually a shorter version of the name
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of _decimals used to get its user representation.
     * For example, if `_decimals` equals `2`, an amount of `505` should be
     * displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @notice Publish latest ESR value
     * @param timestamp the timestamp of the day; will be rounded down to SOD timestamp
     * @param esr the ESR spot value of the day
     * @dev performs data valiation checks, updates state variables, and emits event
     */
    function publishDayESR(uint256 timestamp, int256 esr) public onlyOwner {
        // data validation
        // get SOD timestamp
        timestamp = _getStartOfDayTimestamp(timestamp);
        _latestESR = esr;
        _latestESRDate = timestamp;

        // update mapping
        _esrFromDate[timestamp] = esr;

        // check and update _esrStartDay
        _checkAndUpdateEarliestESRDate(timestamp);

        // emit event
        emit ESRUpdate(timestamp, msg.sender, esr);
    }

    /**
     * @notice Get the latest published ESR
     * @return esr latest published ESR
     */
    function getLatestESR() public view returns (int256 esr) {
        return _latestESR;
    }

    /**
     * @notice Get the latest published ESR date
     * @return latestESRDate latest published ESR date
     */
    function getLatestESRDate() public view returns (uint256 latestESRDate) {
        return _latestESRDate;
    }

    /**
     * @notice Get the earliest published ESR date
     * @return earliestESRDate earliest published ESR date
     */
    function getEarliestESRDate() public view returns (uint256 earliestESRDate) {
        return _esrStartDay;
    }

    /**
     * @notice Get the published ESR for a given date
     * @param timestamp timestamp of the date
     * @return date timestamp of date rounded down to start of day
     * @return esr published ESR for the given date
     */
    function getESRForDate(uint256 timestamp) public view returns (uint256 date, int256 esr) {
        // check if timestamp is SOD time
        timestamp = _getStartOfDayTimestamp(timestamp); // get SOD timestamp
        return (timestamp, _esrFromDate[timestamp]);
    }

    /**
     * @dev Returns the version of the contract
     */
    function version() public pure returns (uint256) {
        return 1;
    }

    /**
     * @dev Convert any timestamp to SOD timestamp as date representation
     */
    function _getStartOfDayTimestamp(uint256 timestamp) internal pure returns (uint256 sodTimestamp) {
        return (timestamp / ESR_PUBLISH_FREQUENCY) * ESR_PUBLISH_FREQUENCY;
    }

    /**
     * @dev Check and update the earliest ESR date state variable
     */
    function _checkAndUpdateEarliestESRDate(uint256 timestamp) internal {
        if (_esrStartDay == 0 || timestamp < _esrStartDay) {
            _esrStartDay = timestamp;
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
