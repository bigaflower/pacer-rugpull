// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @notice Role Utility
/// @author dsshap (Circle)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
library RolesUtil {
    /**
     * @dev checks if userRole has role
     */
    function doesHaveRole(bytes32 userRoles, uint8 role) internal pure returns (bool) {
        return (uint256(userRoles) >> role) & 1 != 0;
    }

    /**
     * @dev checks if role has capability
     */
    function doesHaveCapability(bytes32 capabilities, uint8 role) internal pure returns (bool) {
        return (uint256(capabilities) >> role) & 1 != 0;
    }
}
