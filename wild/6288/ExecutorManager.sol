// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IExecutorManager {
    error NotAuthorized();
    error TransactionFailed();
    error ExecutorAlreadyExists(address executor);
    error ExecutorNotExists(address executor);

    event ExecutorAdded(address indexed executor);
    event ExecutorRemoved(address indexed executor);
}

contract A7A5ExecutorManager is IExecutorManager, Ownable, ReentrancyGuard, Pausable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20;

    EnumerableSet.AddressSet private _executors;
    IERC20 public immutable TOKEN;

    modifier onlyExecutor() {
        if (!_executors.contains(tx.origin)) revert NotAuthorized();
        _;
    }

    constructor(
        address owner_, 
        address token_
    ) Ownable(owner_) {
        TOKEN = IERC20(token_);
    }

    receive() external payable {}

    function addExecutors(address[] calldata executors) external onlyOwner {
        for (uint256 i = 0; i < executors.length; ) {
            if (!_executors.add(executors[i])) {
                revert ExecutorAlreadyExists(executors[i]);
            }

            emit ExecutorAdded(executors[i]);

            unchecked {
                ++i;
            }            
        }
    }

    function removeExecutors(address[] calldata executors) external onlyOwner {
        for (uint256 i = 0; i < executors.length; ) {
            if (!_executors.remove(executors[i])) {
                revert ExecutorNotExists(executors[i]);
            }

            emit ExecutorRemoved(executors[i]);

            unchecked {
                ++i;
            }            
        }
    }

    function transferTokensWithNative(
        address to,
        uint256 amount,
        uint256 nativeAmount
    ) external onlyExecutor nonReentrant whenNotPaused {
        if (nativeAmount != 0) {
            (bool success, ) = to.call{value: nativeAmount}("");
            if (!success) {
                revert TransactionFailed();
            }
        }

        TOKEN.safeTransfer(to, amount);
    }

    function withdrawTokens(address to, uint256 amount) external onlyOwner {
        TOKEN.safeTransfer(to, amount);
    }

    function withdrawNative(address to, uint256 nativeAmount) external onlyOwner {
        (bool success, ) = to.call{value: nativeAmount}("");
        if (!success) {
            revert TransactionFailed();
        }
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();        
    }

    function getExecutorList() external view returns (address[] memory) {
        return _executors.values();
    }

    function isExecutor(address account) external view returns (bool) {
        return _executors.contains(account);
    }
}
