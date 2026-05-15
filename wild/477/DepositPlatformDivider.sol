// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IERC20, SafeERC20 } from './SafeERC20.sol';
import { IDepositHelper } from './IDepositHelper.sol';

interface VestingContract {
    function claim() external;
}

contract DepositPlatformDivider {
    using SafeERC20 for IERC20;

    VestingContract public immutable VESTING;
    address public owner;

    uint16 public constant MAX_HELPER_WEIGHT = 10000;

    uint256 public lastClaimed;
    address public manager;
    address public rewardToken;

    mapping(address => bool) public isApprovedHelper; // helper => isApproved

    struct CurrentWeights {
        address[] helpers;
        uint16[] weights;
    }

    CurrentWeights private currentWeights; // cannot publicly return struct arrays
    
    constructor(address _rewardToken, address _vesting, address _owner) {
        VESTING = VestingContract(_vesting);
        owner = _owner;
        manager = msg.sender;
        rewardToken = _rewardToken;
    }

    modifier onlyManager() {
        require(msg.sender == manager || msg.sender == owner, "!auth");
        _;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "!auth");
        _;
    }

    // --- View functions ---
    function getCurrentWeights() external view returns (address[] memory, uint16[] memory) {
        return (currentWeights.helpers, currentWeights.weights);
    }
    function currentWeightOfHelper(address _helper) public view returns (uint16) {
        for(uint256 i = 0; i < currentWeights.helpers.length; i++) {
            if(currentWeights.helpers[i] == _helper) {
                return currentWeights.weights[i];
            }
        }
        return 0;
    }

    // --- Main function ---
    
    // Claim from vest, split, and notify each helper
    function claim() external {
        uint256 currentEpoch = (block.timestamp / 1209600) * 1209600;
        require(currentEpoch > lastClaimed, "!wait");
        require(currentWeights.helpers.length > 0, "!weights");
        lastClaimed = currentEpoch;
        VESTING.claim();
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));
        require(balance > 0, "!balance");
        emit Claimed(balance);
        uint256 assignedAmount = 0;
        uint256[] memory amounts = new uint256[](currentWeights.weights.length);
        for(uint256 i = 0; i < currentWeights.weights.length; i++) {
            if(i == currentWeights.weights.length - 1) {
                amounts[i] = balance - assignedAmount; // assign remainder to last helper to prevent dust
                break;
            }
            amounts[i] = (balance * currentWeights.weights[i]) / MAX_HELPER_WEIGHT;
            assignedAmount += amounts[i];
        }
        for(uint256 i = 0; i < currentWeights.helpers.length; i++) {
            IDepositHelper(currentWeights.helpers[i]).notifyReward(amounts[i]);
            emit AddedRewards(rewardToken, currentWeights.helpers[i], amounts[i]);
        }
    }

    // --- Manager functions ---

    function setWeights(address[] memory _helpers, uint16[] memory _weights) external onlyManager {
        require(_helpers.length == _weights.length, "!length");
        uint256 totalWeight = 0;
        uint256 addressHeight;
        for(uint256 i = 0; i < _helpers.length; i++) {
            require(_weights[i] > 0, "!zero");
            require(isApprovedHelper[_helpers[i]], "!approved");
            require(uint160(_helpers[i]) > addressHeight, "!sorted");
            addressHeight = uint160(_helpers[i]);
            totalWeight += _weights[i];
        }
        require(totalWeight == MAX_HELPER_WEIGHT, "!10000");
        currentWeights.helpers = _helpers;
        currentWeights.weights = _weights;
        emit UpdatedWeights(_helpers, _weights);
    }

    // --- Owner functions ---

    function setManager(address _manager) external onlyOwner {
        manager = _manager;
        emit NewManager(_manager);
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit NewOwner(_owner);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = _rewardToken;
        emit NewRewardToken(_rewardToken);
    }

    function addDepositHelper(address _depositHelper) external onlyOwner {
        isApprovedHelper[_depositHelper] = true;
        IERC20(rewardToken).approve(_depositHelper, type(uint256).max);
        emit AddedHelper(_depositHelper);
    }

    function removeDepositHelper(address _depositHelper) external onlyOwner {
        require(currentWeightOfHelper(_depositHelper) == 0, "!weight");
        isApprovedHelper[_depositHelper] = false;
        IERC20(rewardToken).approve(_depositHelper, 0);
        emit RemovedHelper(_depositHelper);
    }

    function execute(address to, uint256 value, bytes calldata data) external onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = to.call{value: value}(data);
        require(success, "Call failed");
        return result;
    }

    // --- Events ---
    event Claimed(uint256 amount);
    event AddedRewards(address token, address indexed helper, uint256 amount);
    event AddedHelper(address indexed helper);
    event RemovedHelper(address indexed helper);
    event UpdatedWeights(address[] helpers, uint16[] weights);
    event NewManager(address manager);
    event NewOwner(address owner);
    event NewRewardToken(address rewardToken);

}