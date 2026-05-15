// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @title KibaSwapAggregator
/// @notice Thin proxy that forwards swaps to whitelisted DEX aggregator routers.
contract KibaSwapAggregator {
    address public immutable owner;
    address private constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    mapping(address => bool) public allowedRouters;

    event RouterUpdated(address indexed router, bool allowed);
    event SwapExecuted(
        address indexed user,
        address indexed router,
        address tokenIn,
        uint256 amountIn
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address[] memory _routers) {
        owner = msg.sender;
        for (uint256 i = 0; i < _routers.length; i++) {
            allowedRouters[_routers[i]] = true;
            emit RouterUpdated(_routers[i], true);
        }
    }

    /// @notice Execute a swap through a whitelisted router.
    /// @param router     The underlying DEX router to call.
    /// @param data       The calldata for the router (built with this contract as sender).
    /// @param tokenIn    The input token address. Use address(0) or NATIVE sentinel for ETH.
    /// @param amountIn   The amount of input tokens (ignored for native ETH, use msg.value).
    function swap(
        address router,
        bytes calldata data,
        address tokenIn,
        uint256 amountIn
    ) external payable {
        require(allowedRouters[router], "Router not allowed");

        bool isNativeIn = tokenIn == address(0) || tokenIn == NATIVE;

        if (!isNativeIn) {
            require(
                IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn),
                "TransferFrom failed"
            );
            IERC20(tokenIn).approve(router, amountIn);
        }

        (bool success, bytes memory result) = router.call{value: msg.value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }

        emit SwapExecuted(msg.sender, router, tokenIn, amountIn);
    }

    receive() external payable {}

    // ── Admin ───────────────────────────────────────────────────────────────

    function setRouter(address router, bool allowed) external onlyOwner {
        allowedRouters[router] = allowed;
        emit RouterUpdated(router, allowed);
    }

    function rescueTokens(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }

    function rescueETH(address payable to) external onlyOwner {
        (bool sent, ) = to.call{value: address(this).balance}("");
        require(sent, "ETH transfer failed");
    }
}