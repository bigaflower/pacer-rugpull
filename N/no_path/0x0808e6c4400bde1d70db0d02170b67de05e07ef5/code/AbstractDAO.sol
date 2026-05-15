// SPDX-License-Identifier: MIT
pragma solidity =0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

abstract contract AbstractDAO is Ownable {
    address public _operator;
    uint256 public _threshold;
    uint256 public _queueOrder;
    uint256 public _votingInProgress;
    uint256 public _votesSent;
    uint256 public _requiredVoteThreshold;
    uint256 public _authorizedAddressesCount;
    uint256 internal _bps;
    mapping(uint256 => address) public _authorizedAddresses;

    mapping(address => address) internal _submittedVotesTable;
    mapping(address => uint256) internal _revokeVotesTable;
    mapping(address => uint256) internal _addVotesCountTable;
    mapping(uint256 => uint256) internal _revokeVotesCountTable;

    address[] internal _addVotingProposals;
    uint256[] internal _revokeVotingProposals;

    mapping(uint256 => bool) internal _nonces;
    uint256 internal _burnNonce;
    uint256 internal _thresholdLevel;

    function initAuthorizedAddresses(address authorized1, address authorized2, address operator)
    external
    onlyOwner
    {
        require(
            _authorizedAddresses[1] == address(0) &&
            _authorizedAddresses[2] == address(0),
            "Authorized addresses already set"
        );
        _authorizedAddresses[1] = authorized1;
        _authorizedAddresses[2] = authorized2;
        _submittedVotesTable[authorized1] = authorized1;
        _submittedVotesTable[authorized2] = authorized2;
        _operator = operator;
    }

    function voteAdd(uint256 authorizedIndex, address votingAddress) external {
        address winningAddress = address(0);
        require(
            msg.sender == _authorizedAddresses[authorizedIndex],
            "Must be sent from authorized sender"
        );
        require(
            _votingInProgress == 0 || _votingInProgress == 1,
            "Another voting is ongoing"
        );
        require(
            _submittedVotesTable[msg.sender] == msg.sender,
            "One vote per authorized address only"
        );
        for (uint256 i = 0; i < _authorizedAddressesCount; i++) {
            require(_authorizedAddresses[i] != votingAddress, 'voting address already authorized');
        }
        if (_votingInProgress == 0) {
            _votingInProgress = 1;
        }
        _submittedVotesTable[msg.sender] = votingAddress;
        _votesSent += 1;
        winningAddress = _addVotingProcess();

        //  False threshold, consensus will be never reached
        if (msg.sender == winningAddress) {
            _addVotingCleanup();

            return;
        }

        if (_operator == winningAddress) {
            _addVotingCleanup();
            return;
        }

        if (address(0) != winningAddress) {
            _addAuthorized(winningAddress);
            _addVotingCleanup();

            return;
        }

        // This is a fallback and a riddle at the same time
        // Using early false threshold this situation should never happen in 66% consensus scenario
        // If you go above 66% you shall be safe though
        if (address(0) == winningAddress && _votesSent == _authorizedAddressesCount) {
            _addVotingCleanup();

            return;
        }
    }

    function setOperator(uint256 authorizedIndex, address newOperator) external {
        require(
            msg.sender == _authorizedAddresses[authorizedIndex],
            "Must be sent from authorized sender"
        );
        require(_operator != newOperator, "operator already set");
        _operator = newOperator;
    }

    function voteRevoke(uint256 authorizedIndex, uint256 revokeAddressIndex)
    external
    {
        uint256 winningAddressIndex = 0;
        require(
            msg.sender == _authorizedAddresses[authorizedIndex],
            "Must be sent from authorized sender"
        );
        require(
            _votingInProgress == 0 || _votingInProgress == 2,
            "Another voting is ongoing"
        );
        require(
            _submittedVotesTable[msg.sender] == msg.sender,
            "One vote per authorized address only"
        );
        require(
            _authorizedAddressesCount > 2,
            "you mad?"
        );

        for (uint256 i = 0; i < _authorizedAddressesCount; i++) {
            require(_authorizedAddresses[revokeAddressIndex] != address(0), 'invalid revoke index');
        }

        if (_votingInProgress == 0) {
            _votingInProgress = 2;
        }
        _revokeVotesTable[msg.sender] = revokeAddressIndex;
        _submittedVotesTable[msg.sender] = address(0);
        _votesSent += 1;
        winningAddressIndex = _revokeVotingProcess();

        if (winningAddressIndex > 0) {
            _revokeAuthorized(winningAddressIndex);
            _revokeVotingCleanup();
        }
    }

    function isNonceRealised(uint256 _nonce) external view returns (bool) {
        return _nonces[_nonce];
    }

    function getThreshold() public view returns (uint256) {
        return _threshold;
    }

    function approveThreshold() external {
        require(
            msg.sender == _authorizedAddresses[_queueOrder],
            "Must be sent from authorized sender in the correct order"
        );
        _threshold += _thresholdLevel;
        _queueOrder += 1;
        if (_authorizedAddressesCount < _queueOrder) {
            _queueOrder = 1;
        }
    }

    function _addAuthorized(address _toAdd) internal {
        _authorizedAddresses[_authorizedAddressesCount + 1] = _toAdd;
        _authorizedAddressesCount += 1;
        _requiredVoteThreshold = _authorizedAddressesCount * _bps;
    }

    function _revokeAuthorized(uint256 _toRemove) internal {
        delete _authorizedAddresses[_toRemove];

        for (uint256 i = _toRemove; i <= _authorizedAddressesCount; i++) {
            _authorizedAddresses[i] = _authorizedAddresses[i + 1];
        }

        _authorizedAddressesCount -= 1;
        _requiredVoteThreshold = _authorizedAddressesCount * _bps;
        _queueOrder = 1;
    }

    function _addVotingCleanup() internal {
        for (uint256 i = 0; i < _addVotingProposals.length; i++) {
            delete _addVotesCountTable[_addVotingProposals[i]];
        }

        for (uint256 i = 1; i <= _authorizedAddressesCount; i++) {
            _submittedVotesTable[_authorizedAddresses[i]] = _authorizedAddresses[i];
        }

        delete _addVotingProposals;

        _votesSent = 0;
        _votingInProgress = 0;
    }

    function _revokeVotingCleanup() internal {
        for (uint256 i = 0; i <= _authorizedAddressesCount; i++) {
            delete _revokeVotesCountTable[i];
        }

        for (uint256 i = 1; i <= _authorizedAddressesCount; i++) {
            delete _revokeVotesTable[_authorizedAddresses[i]];
            _submittedVotesTable[_authorizedAddresses[i]] = _authorizedAddresses[i];
        }

        delete _revokeVotingProposals;

        _votesSent = 0;
        _votingInProgress = 0;
    }

    function _addVotingProcess() internal returns (address) {
        address votedAddress = address(0);
        address winningAddress = address(0);
        uint256 highestScore = 0;

        for (uint256 i = 1; i <= _authorizedAddressesCount; i++) {
            votedAddress = _submittedVotesTable[_authorizedAddresses[i]];

            if (votedAddress == _authorizedAddresses[i] || address(0) == votedAddress) {
                continue;
            }

            _addVotesCountTable[votedAddress] += 1;
            _addVotingProposals.push(votedAddress);
            delete _submittedVotesTable[_authorizedAddresses[i]];
        }
        for (uint256 j = 0; j < _addVotingProposals.length; j++) {
            if (highestScore < _addVotesCountTable[_addVotingProposals[j]]) {
                highestScore = _addVotesCountTable[_addVotingProposals[j]];
                winningAddress = _addVotingProposals[j];
            }
        }

        if (highestScore * 10_000 >= _requiredVoteThreshold) {
            return winningAddress;
        }

        uint256 finalityCheck = (((_authorizedAddressesCount - _votesSent) * 10_000) + (highestScore * 10_000));

        if (finalityCheck < _requiredVoteThreshold) {
            return msg.sender;
        }

        return address(0);
    }

    function _revokeVotingProcess() internal returns (uint256) {
        uint256 highestScore = 0;
        uint256 votedAddressIndex = 0;
        uint256 winningAddressIndex = 0;

        for (uint256 i = 1; i <= _authorizedAddressesCount; i++) {
            votedAddressIndex = _revokeVotesTable[_authorizedAddresses[i]];

            if (_authorizedAddresses[votedAddressIndex] == address(0)) {
                continue;
            }

            _revokeVotesCountTable[votedAddressIndex] += 1;
            _revokeVotingProposals.push(votedAddressIndex);
            delete _revokeVotesTable[_authorizedAddresses[i]];
        }
        for (uint256 j = 0; j < _revokeVotingProposals.length; j++) {
            if (highestScore < _revokeVotesCountTable[_revokeVotingProposals[j]]) {
                highestScore = _revokeVotesCountTable[_revokeVotingProposals[j]];
                winningAddressIndex = _revokeVotingProposals[j];
            }
        }

        if (highestScore * 10_000 >= _requiredVoteThreshold) {
            return winningAddressIndex;
        }

        uint256 finalityCheck = (((_authorizedAddressesCount - _votesSent) * 10_000) + (highestScore * 10_000));

        if (finalityCheck <= _requiredVoteThreshold || _votesSent == _authorizedAddressesCount) {
            _revokeVotingCleanup();
        }

        return 0;
    }
}