// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 */
contract TransparentUpgradeableProxy {
    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`.
     */
    constructor(address _logic, address _admin, bytes memory _data) payable {
        _setAdmin(_admin);
        _upgradeTo(_logic);
        if (_data.length > 0) {
            (bool success, bytes memory returndata) = _logic.delegatecall(_data);
            if (!success) {
                if (returndata.length > 0) {
                    // Bubble up the revert reason
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("TransparentUpgradeableProxy: initialization failed");
                }
            }
        }
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     */
    function admin() external ifAdmin returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     */
    function implementation() external ifAdmin returns (address) {
        return _getImplementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     */
    function changeAdmin(address newAdmin) external ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeTo(newImplementation);
        (bool success, ) = newImplementation.delegatecall(data);
        require(success, "TransparentUpgradeableProxy: upgrade call failed");
    }

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() private view returns (address) {
        return _getAddressSlot(_ADMIN_SLOT);
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        _setAddressSlot(_ADMIN_SLOT, newAdmin);
    }

    /**
     * @dev Returns the current implementation.
     */
    function _getImplementation() private view returns (address) {
        return _getAddressSlot(_IMPLEMENTATION_SLOT);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(_isContract(newImplementation), "TransparentUpgradeableProxy: new implementation is not a contract");
        _setAddressSlot(_IMPLEMENTATION_SLOT, newImplementation);
    }

    /**
     * @dev Perform implementation upgrade
     */
    function _upgradeTo(address newImplementation) private {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Delegates the current call to `implementation`.
     */
    function _delegate(address impl) private {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev Fallback function that delegates calls to the implementation.
     */
    function _fallback() private {
        _delegate(_getImplementation());
    }

    /**
     * @dev Fallback function that delegates calls to the implementation. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the implementation. Will run if call data
     * is empty.
     */
    receive() external payable {
        _fallback();
    }

    function _getAddressSlot(bytes32 slot) private view returns (address addr) {
        assembly {
            addr := sload(slot)
        }
    }

    function _setAddressSlot(bytes32 slot, address value) private {
        assembly {
            sstore(slot, value)
        }
    }

    function _isContract(address account) private view returns (bool) {
        return account.code.length > 0;
    }
}
