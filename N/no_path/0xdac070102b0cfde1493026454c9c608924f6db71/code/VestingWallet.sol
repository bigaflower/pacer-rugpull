// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Author: @DuckJHN
contract VestingWallet is Context, Ownable {
    using SafeERC20 for IERC20;
    uint256 public constant MILESTONE_1_DATE = 1714521600;
    uint256 public constant MILESTONE_2_DATE = 1730419200;
    uint256 public constant MILESTONE_3_DATE = 1746057600;
    uint256 public constant MILESTONE_4_DATE = 1761955200;

    uint8 private constant NUM_MILESTONES = 4;
    uint256 private constant DURATION_TIME =  1 * 5 minutes;

    address public businessMarketing;
    address public presale;
    address public reserve;
    address public advisor;

    address[] internal _recipients;

    struct InforDistribute {
        address benificiary;
        uint8 percentage;
        uint8 phase;
    }

    struct Milestone {
        uint256 dateRelease;
        uint256 percentage;
        bool released;
    }

    mapping(uint256 => Milestone) public milestones;
    mapping(uint8 => InforDistribute[]) internal inforDistributes;
    mapping(address => uint256) public _erc20Released;

    event ERC20Released(address indexed token, uint256 amount);
    event ChangeAddressRecipient(
        uint8 indexed index,
        address indexed oldAddress,
        address newAddress
    );

    constructor(address _defaultBenificiary) Ownable(msg.sender) {
        businessMarketing = _defaultBenificiary;
        presale = _defaultBenificiary;
        reserve = _defaultBenificiary;
        advisor = _defaultBenificiary;

        _recipients = [businessMarketing, presale, reserve, advisor];

        milestones[0] = Milestone(MILESTONE_1_DATE, 20, false);
        milestones[1] = Milestone(MILESTONE_2_DATE, 10, false);
        milestones[2] = Milestone(MILESTONE_3_DATE, 10, false);
        milestones[3] = Milestone(MILESTONE_4_DATE, 10, false);

        // Phase 1
        inforDistributes[0].push(InforDistribute(businessMarketing, 35, 1));
        inforDistributes[1].push(InforDistribute(presale, 30, 1));
        inforDistributes[2].push(InforDistribute(reserve, 25, 1));
        inforDistributes[3].push(InforDistribute(advisor, 10, 1));

        // Phase 2
        inforDistributes[0].push(InforDistribute(businessMarketing, 35, 2));
        inforDistributes[2].push(InforDistribute(presale, 55, 2));
        inforDistributes[3].push(InforDistribute(advisor, 10, 2));

        // Phase 3
        inforDistributes[0].push(InforDistribute(businessMarketing, 35, 3));
        inforDistributes[2].push(InforDistribute(presale, 55, 3));
        inforDistributes[3].push(InforDistribute(advisor, 10, 3));

        // Phase 4
        inforDistributes[0].push(InforDistribute(businessMarketing, 35, 4));
        inforDistributes[2].push(InforDistribute(presale, 55, 4));
        inforDistributes[3].push(InforDistribute(advisor, 10, 4));
    }

    function getAvailableAmount(address token) public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    function getDistributionData(uint8 _index)
        external
        view
        returns (uint8[] memory, uint8[] memory)
    {
        require(_recipients.length > _index, "Index invalid");
        require(inforDistributes[_index].length > 0, "Address does not exist");
        uint256 count = inforDistributes[_index].length;
        uint8[] memory percentages = new uint8[](count);
        uint8[] memory phases = new uint8[](count);

        for (uint256 i =0; i< count; i++ ) {
            percentages[i] = inforDistributes[_index][i].percentage;
            phases[i] = inforDistributes[_index][i].phase;
        }
        return (percentages, phases);
    }


    // The date start of milestone
    function start() public view virtual returns (uint256) {
        return milestones[0].dateRelease;
    }

    // The date final of milestone
    function end() public view virtual returns (uint256) {
        return milestones[NUM_MILESTONES - 1].dateRelease;
    }

    function released(address token) public view virtual returns (uint256) {
        return _erc20Released[token];
    }

    function getBenificiary(uint8 index) external view returns (address) {
        require(_recipients.length > index, "Index invalid");
        return _recipients[index];
    }

    function changeAddressBenificiary(uint8 _index, address _benificiary)
        external
        onlyOwner
        returns (bool)
    {
        require(_recipients.length >= _index, "Index invalid");
        require(_benificiary != address(0), "Address invalid");
        address oldRecipient =  inforDistributes[_index][0].benificiary;
        _recipients[_index] = _benificiary;

        if (_index == 0) {
            businessMarketing = _benificiary;
        } else if (_index == 1) {
            presale = _benificiary;
        } else if (_index == 2) {
            reserve = _benificiary;
        } else if (_index == 3) {
            advisor = _benificiary;
        }
        inforDistributes[_index][0].benificiary = _benificiary;

        emit ChangeAddressRecipient(_index, oldRecipient, _recipients[_index]);
        return true;
    }

    // Releasable token (Amount can distribute to recipient)
    function releasable(address token) public view virtual returns (uint256) {
        if (getAvailableAmount(token) == 0) {
            return 0;
        }
        return vestedAmount(token, uint64(block.timestamp));
    }

    function getPhaseAtTime(uint256 time) public view returns (uint256) {
        if (time < start()) {
            return 0;
        } else if (time >= end()) {
            return NUM_MILESTONES - 1;
        }
        return (time - start()) / DURATION_TIME;
    }

    function vestedAmount(address token, uint256 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        return
            _vestingSchedule(
                getAvailableAmount(token) + released(token),
                timestamp
            );
    }

    function _vestingSchedule(uint256 totalAllocation, uint256 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        if (timestamp < start()) {
            return 0;
        } else {
            uint256 amountDistribute = getTotalDistributedAmount(
                totalAllocation,
                timestamp
            );
            return amountDistribute;
        }
    }

    function getTotalDistributedAmount(
        uint256 totalAllocation,
        uint256 timestamp
    ) internal view returns (uint256) {
        uint256 currentPhase = getPhaseAtTime(timestamp);

        if (milestones[currentPhase].released) 
        {
            return 0;
        }
        return (totalAllocation * milestones[currentPhase].percentage) / 100;
    }

    function getCurrentPercentageBenificiary(uint8 _index)
        internal
        view
        returns (uint8)
    {
        uint256 currentPhase = getPhaseAtTime(block.timestamp);

        if (inforDistributes[_index].length <= currentPhase) {
            return 0;
        }
        return inforDistributes[_index][currentPhase].percentage;
    }

    /**
     * @dev Description of the function.
     * @return Description of the return value.
     */
    function distributeRecipient(address token, uint256 amount)
        internal
        returns (bool)
    {
        for (uint8 i = 0; i < _recipients.length; i++) {
            uint256 currentPercent = getCurrentPercentageBenificiary(i);
            if (currentPercent == 0) {
                continue;
            }
            uint256 amountReceived = (currentPercent * amount) / 100;

            IERC20(token).transfer(address(_recipients[i]), amountReceived);
        }

        return true;
    }

    /**
     * @dev Releases the vested tokens to recipients based on the allocation percentages.
     * @param token The address of the token to release.
     * @return A boolean value indicating whether the operation succeeded.
     */
    function release(address token) external returns (bool) {
        uint256 currentPhase = getPhaseAtTime(block.timestamp);
        require(
            !milestones[currentPhase].released,
            "There is no release at this time."
        );
        
        uint256 amount = releasable(token);

        require(amount > 0, "Pool to release not be zero");
        emit ERC20Released(token, amount);

        distributeRecipient(token, amount);
        _erc20Released[token] += amount;
        milestones[getPhaseAtTime(block.timestamp)].released = true;
        return true;
    }

    function unlockRestAmount(address token) external onlyOwner returns (bool) {
        require(
            milestones[getPhaseAtTime(end())].released,
            "The final phase has not been released yet."
        );
        uint256 amount = getAvailableAmount(token);
        IERC20(token).transfer(msg.sender, amount);
        return true;
    }
}
