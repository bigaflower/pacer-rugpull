// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IOndoOwner, IInspector, IMessenger, IOndoOFT, IRateLimiter, RateLimitConfig } from "./interfaces/IOndoOwner.sol";

/**
 * @title OndoOwner
 * @notice Central administrative contract that manages access control and ownership
 * for the Ondo bridge system components.
 * @dev Implements role-based access control using OpenZeppelin's AccessControlEnumerable
 */
contract Test_OndoOwner is IOndoOwner, AccessControlEnumerable {
    /**
     * @notice Role identifier for Inspector administrators
     * @dev Keccak256 hash of "INSPECTOR_ADMIN"
     */
    bytes32 public constant INSPECTOR_ADMIN = keccak256("INSPECTOR_ADMIN");

    /**
     * @notice Role identifier for Messenger administrators
     * @dev Keccak256 hash of "MESSENGER_ADMIN"
     */
    bytes32 public constant MESSENGER_ADMIN = keccak256("MESSENGER_ADMIN");

    /**
     * @notice Role identifier for Rate Limiter administrators
     * @dev Keccak256 hash of "RATE_LIMITER_ADMIN"
     */
    bytes32 public constant RATE_LIMITER_ADMIN = keccak256("RATE_LIMITER_ADMIN");

    /**
     * @notice Mapping of target contracts to their pending owners
     * @dev Used for the two-step ownership transfer pattern
     */
    mapping(address targetContract => address pendingOwner) public pendingOwners;

    // @dev Contracts owned by this wrapper, for configs to be pushed to.
    IInspector public inspector;
    IMessenger public immutable messenger;
    IRateLimiter public rateLimiter;

    /**
     * @notice Modifier that restricts function access to accounts with the specified role
     * @param role The role identifier required to access the function
     * @dev Also allows accounts with the DEFAULT_ADMIN_ROLE to access the function
     */
    modifier only(bytes32 role) {
        if (!hasRole(role, msg.sender) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert AccessControlUnauthorizedAccount(msg.sender, role);
        }
        _;
    }

    /**
     * @notice Constructs the OndoOwner contract with initial administrators
     * @param _inspector Address of the Inspector contract
     * @param _messenger Address of the Messenger contract
     * @param _rateLimiter Address of the RateLimiter contract
     * @param _inspectorAdmin Address to be granted the INSPECTOR_ADMIN role
     * @param _messengerAdmin Address to be granted the MESSENGER_ADMIN role
     * @param _rateLimiterAdmin Address to be granted the RATE_LIMITER_ADMIN role
     * @param _owner Address to be set as the owner and granted the DEFAULT_ADMIN_ROLE
     */
    constructor(
        address _inspector,
        address _messenger,
        address _rateLimiter,
        address _inspectorAdmin,
        address _messengerAdmin,
        address _rateLimiterAdmin,
        address _owner
    ) {
        if (_inspector == address(0) || _messenger == address(0) || _rateLimiter == address(0)) {
            revert ConstructorAddressesZero(_inspector, _messenger, _rateLimiter);
        }

        inspector = IInspector(_inspector);
        messenger = IMessenger(_messenger);
        rateLimiter = IRateLimiter(_rateLimiter);

        _grantRole(INSPECTOR_ADMIN, _inspectorAdmin);
        _grantRole(MESSENGER_ADMIN, _messengerAdmin);
        _grantRole(RATE_LIMITER_ADMIN, _rateLimiterAdmin);
        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    }

    // ------------------- Admin -------------------

    /**
     * @notice Allows the admin to execute arbitrary calls to target contracts
     * @param _targetContract The address of the contract to call
     * @param _data The calldata to pass to the target contract
     * @return success Boolean indicating if the call was successful
     * @return result The return data from the call
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function superCall(
        address _targetContract,
        bytes calldata _data
    ) external only(DEFAULT_ADMIN_ROLE) returns (bool success, bytes memory result) {
        (success, result) = _targetContract.call(_data);
        if (!success) revert CallFailed();

        return (success, result);
    }

    /**
     * @notice Initiates the transfer of ownership for a target contract
     * @param _targetContract The address of the contract whose ownership is being transferred
     * @param _newOwner The address of the new owner
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     * @dev This is the first step in the two-step ownership transfer pattern
     */
    function transferContractOwnership(address _targetContract, address _newOwner) external only(DEFAULT_ADMIN_ROLE) {
        pendingOwners[_targetContract] = _newOwner;
        emit ContractOwnershipTransferStarted(_targetContract, _newOwner);
    }

    /**
     * @notice Claims ownership of a target contract by the pending owner
     * @param _targetContract The address of the contract whose ownership is being claimed
     * @dev This function can only be called by the pending owner of the target contract
     * @dev This is the second step in the two-step ownership transfer pattern
     */
    function claimContractOwnership(address _targetContract) external {
        address pendingOwner = pendingOwners[_targetContract];
        if (msg.sender != pendingOwner) revert OnlyPendingOwner(_targetContract, msg.sender);
        delete pendingOwners[_targetContract];
        Ownable(_targetContract).transferOwnership(pendingOwner);
        emit ContractOwnershipTransferClaimed(_targetContract, pendingOwner);
    }

    // ------------------- Inspector -------------------

    /**
     * @notice Sets the global paused state on the Inspector contract
     * @param _paused The state of the global pause
     * @dev This function can only be called by accounts with the INSPECTOR_ADMIN role or DEFAULT_ADMIN_ROLE
     */
    function setGlobalPaused(bool _paused) external only(INSPECTOR_ADMIN) {
        // @dev Only the Admin can 'unpause'
        if (!_paused && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAdminCanUnPause();

        inspector.setGlobalPaused(_paused);
    }

    /**
     * @notice Sets the paused state for a specific ID on the Inspector contract
     * @param _id The identifier to set the pause state for
     * @param _paused The state of the pause
     * @dev This function can only be called by accounts with the INSPECTOR_ADMIN role or DEFAULT_ADMIN_ROLE
     */
    function setIdPaused(bytes32 _id, bool _paused) external only(INSPECTOR_ADMIN) {
        // @dev Only the Admin can 'unpause'
        if (!_paused && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) revert OnlyAdminCanUnPause();

        inspector.setIdPaused(_id, _paused);
    }

    // ------------------- Messenger -------------------

    /**
     * @notice Sets the Inspector for a Messenger contract
     * @param _inspector The Inspector contract instance to set
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function setInspector(IInspector _inspector) external only(DEFAULT_ADMIN_ROLE) {
        inspector = _inspector;
        messenger.setInspector(address(_inspector));
    }

    /**
     * @notice Sets the RateLimiter for a Messenger contract
     * @param _rateLimiter The RateLimiter contract instance to set
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function setRateLimiter(IRateLimiter _rateLimiter) external only(DEFAULT_ADMIN_ROLE) {
        rateLimiter = _rateLimiter;
        messenger.setRateLimiter(address(_rateLimiter));
    }

    /**
     * @notice Registers a new token with the Messenger
     * @param _tokenId The unique identifier for the token
     * @param _tokenAddress The address of the token contract
     * @return oftAddress The address of the newly created OndoOFT contract
     * @dev This function can only be called by accounts with the MESSENGER_ADMIN role or DEFAULT_ADMIN_ROLE
     */
    function registerToken(
        bytes32 _tokenId,
        address _tokenAddress
    ) external only(MESSENGER_ADMIN) returns (address oftAddress) {
        oftAddress = messenger.registerToken(_tokenId, _tokenAddress);
    }

    /**
     * @notice Deregisters an existing token from the Messenger
     * @param _tokenId The unique identifier for the token to be deregistered
     *
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function deregisterToken(bytes32 _tokenId) external only(DEFAULT_ADMIN_ROLE) {
        messenger.deregisterToken(_tokenId);
    }

    /**
     * @notice Registers a token with an existing OFT contract in the Messenger
     * @param _tokenId The unique identifier for the token
     * @param _tokenAddress The address of the token contract
     * @param _oftAddress The address of the existing OFT contract
     *
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function registerTokenWithOFT(
        bytes32 _tokenId,
        address _tokenAddress,
        address _oftAddress
    ) external only(DEFAULT_ADMIN_ROLE) {
        messenger.registerTokenWithOFT(_tokenId, _tokenAddress, _oftAddress);
    }

    // ------------------- OFT -------------------

    /**
     * @notice Sets the Messenger address for an OndoOFT contract
     * @param _oft The OndoOFT contract instance
     * @param _messenger The address of the Messenger contract
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function setMessengerOFT(IOndoOFT _oft, address _messenger) external only(DEFAULT_ADMIN_ROLE) {
        _oft.setMessenger(_messenger);
    }

    // ------------------- Rate Limiter -------------------

    /**
     * @notice Sets the Messenger address for a RateLimiter contract
     * @param _rateLimiter The RateLimiter contract instance
     * @param _messenger The address of the Messenger contract
     * @dev This function can only be called by accounts with the DEFAULT_ADMIN_ROLE
     */
    function setMessengerRateLimiter(IRateLimiter _rateLimiter, address _messenger) external only(DEFAULT_ADMIN_ROLE) {
        _rateLimiter.setMessenger(_messenger);
    }

    /**
     * @notice Configures rate limits for the RateLimiter contract
     * @param _configs An array of RateLimitConfig structs representing the rate limit configurations
     * @dev This function can only be called by accounts with the RATE_LIMITER_ADMIN role or DEFAULT_ADMIN_ROLE
     */
    function configureRateLimits(RateLimitConfig[] calldata _configs) external only(RATE_LIMITER_ADMIN) {
        rateLimiter.configureRateLimits(_configs);
    }
}
