// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

library SafeTransfer {
    function safeTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        bytes memory data = abi.encodeWithSelector(token.transferFrom.selector, from, to, amount);
        (bool success, bytes memory ret) = address(token).call(data);
        require(success && (ret.length == 0 || abi.decode(ret, (bool))), "safeTransferFrom failed");
    }

    function safeNativeTransfer(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}("");
        require(success, "safeNativeTransfer failed");
    }
}

contract AggregatedTransfers is ReentrancyGuard, Ownable {
    using SafeTransfer for IERC20;
    using SafeTransfer for address;

    struct ERC20Transfer {
        address token;
        address from;
        address to;
        uint256 amount;
    }

    struct NativeTransfer {
        address to;
        uint256 amount;
    }

    mapping(address => bool) public allowedSenders;

    event ERC20TransferExecuted(address indexed token, address indexed from, address indexed to, uint256 amount);
    event NativeTransferExecuted(address indexed to, uint256 amount);

    modifier onlyAllowedSender() {
        require(allowedSenders[msg.sender], "not allowed");
        _;
    }

    function setAllowedSender(address sender, bool allowed) external onlyOwner {
        allowedSenders[sender] = allowed;
    }

    function aggregate(
        ERC20Transfer[] calldata erc20Transfers,
        NativeTransfer[] calldata nativeTransfers
    ) external payable nonReentrant onlyAllowedSender {
        for (uint256 i = 0; i < erc20Transfers.length; i++) {
            ERC20Transfer calldata t = erc20Transfers[i];
            require(t.amount > 0, "zero amount");
            IERC20(t.token).safeTransferFrom(t.from, t.to, t.amount);
            emit ERC20TransferExecuted(t.token, t.from, t.to, t.amount);
        }

        uint256 totalNative = 0;
        for (uint256 i = 0; i < nativeTransfers.length; i++) {
            totalNative += nativeTransfers[i].amount;
        }
        require(totalNative == msg.value, "msg.value mismatch");

        for (uint256 i = 0; i < nativeTransfers.length; i++) {
            NativeTransfer calldata n = nativeTransfers[i];
            require(n.amount > 0, "zero amount");
            n.to.safeNativeTransfer(n.amount);
            emit NativeTransferExecuted(n.to, n.amount);
        }
    }

    receive() external payable {}
}
