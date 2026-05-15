// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title ERC20 Utility Library
library ERC20UtilsLib {
    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the permit execution fails
    error PermitFailed();

    /*//////////////////////////////////////////////////////////////
                           CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @dev An address used to represent the native token
    address internal constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /*//////////////////////////////////////////////////////////////
                               PERMIT
    //////////////////////////////////////////////////////////////*/

    /// @dev Executes the EIP2612 permit function on the provided token
    /// @param token The address of the token
    /// @param data The permit data
    function permit(address token, bytes calldata data) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly ("memory-safe") {
            // check the permit length
            switch data.length
            // 0x00 = no permit
            // solhint-disable-next-line no-empty-blocks
            case 0x00 {
                // do nothing
            }
            // 32 * 7 = 224 EIP2612 Permit
            case 0xe0 {
                let x := mload(0x40) // get the free memory pointer
                mstore(x, 0xd505accf00000000000000000000000000000000000000000000000000000000) // store the selector
                calldatacopy(add(x, 0x04), data.offset, 0xe0) // store the args
                pop(call(gas(), token, 0x00, x, 0xe4, 0x00, 0x20)) // call ERC20 permit, skip checking return data
            }
            // Otherwise revert
            default {
                mstore(0x00, 0xb78cb0dd00000000000000000000000000000000000000000000000000000000) // store the selector
                revert(0x00, 0x04) // Revert with PermitFailed error
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            BALANCE
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns the balance of address(this), works for both ETH and ERC20 tokens
    function getBalance(address token) internal view returns (uint256 balanceOf) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch eq(token, ETH_ADDRESS)
            // ETH
            case 0x01 {
                balanceOf := selfbalance()
            }
            // ERC20
            default {
                let x := mload(0x40) // get the free memory pointer
                mstore(x, 0x70a0823100000000000000000000000000000000000000000000000000000000) // store the selector
                mstore(add(x, 0x04), address()) // store the account
                let success := staticcall(gas(), token, x, 0x24, x, 0x20) // call balanceOf
                if success {
                    balanceOf := mload(x)
                } // load the balance
            }
        }
    }
}
