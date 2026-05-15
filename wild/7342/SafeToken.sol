// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @notice 兼容 ERC20（支持返回 bool 与不返回值两类代币）
library SafeToken {
    function safeTransfer(address token, address to, uint256 amount) internal {
        (bool ok, ) = token.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(ok, "SafeToken: transfer failed");
    }

    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool ok, ) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, amount));
        require(ok, "SafeToken: transferFrom failed");
    }

    function safeApprove(address token, address spender, uint256 amount) internal {
        (bool ok, ) = token.call(abi.encodeWithSelector(0x095ea7b3, spender, amount));
        require(ok, "SafeToken: approve failed");
    }
}
