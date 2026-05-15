// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @title BubbleCrossChainRouterETH
 * @notice Cross-chain router for Ethereum → Shido bridging with optional swaps
 * @dev Integrates with Uniswap V3 for swaps and Shido bridges for cross-chain transfers
 *      Optimized for stack depth: bridge params packed into struct
 */

interface ISwapRouter {
    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params)
        external
        returns (uint256 amountOut);
}

interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface IShidoNativeBridge {
    function crossBack(
        address token,
        uint256 toChainId,
        address recipent,
        uint256 amount,
        uint256 destinationGasLimit,
        uint256 fee,
        uint256 deadline,
        bytes calldata signature
    ) external;
}

interface IGateway {
    function crossTo(
        address token,
        uint256 toChainId,
        address recipent,
        uint256 amount,
        uint256 destinationGasLimit,
        uint256 fee,
        uint256 deadline,
        bytes calldata signature
    ) external payable;
}

contract BubbleCrossChainRouterETH is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // ═══════════════════════════════════════════════════════════════════════════════
    // STRUCTS (Stack-depth optimization)
    // ═══════════════════════════════════════════════════════════════════════════════

    /// @notice Packed bridge parameters to avoid stack-too-deep
    struct BridgeParams {
        address recipient;
        uint256 destinationGasLimit;
        uint256 bridgeFee;
        uint256 bridgeDeadline;
        bytes bridgeSignature;
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // STATE VARIABLES
    // ═══════════════════════════════════════════════════════════════════════════════

    address public swapRouter;
    address public weth;
    address public shidoToken;
    address public usdc;
    address public shidoNativeBridge;
    address public gateway;
    address public treasury;
    uint256 public protocolBps;
    
    uint256 public constant SHIDO_CHAIN_ID = 1073741856;
    
    mapping(address => bool) public whitelist;

    // ═══════════════════════════════════════════════════════════════════════════════
    // EVENTS
    // ═══════════════════════════════════════════════════════════════════════════════

    event SwapRouterUpdated(address newSwapRouter);
    event WethUpdated(address newWeth);
    event ShidoTokenUpdated(address newShidoToken);
    event UsdcUpdated(address newUsdc);
    event ShidoNativeBridgeUpdated(address newBridge);
    event GatewayUpdated(address newGateway);
    event TreasuryUpdated(address newTreasury);
    event ProtocolBpsUpdated(uint256 newProtocolBps);
    event WhitelistUpdated(address indexed account, bool status);

    event SwapAndBridgeExecuted(
        address indexed user,
        address indexed tokenIn,
        uint256 amountIn,
        uint256 bridgeAmount,
        uint256 protocolFee,
        address recipient
    );

    event BridgeShidoExecuted(
        address indexed user,
        uint256 amount,
        uint256 protocolFee,
        address recipient
    );

    event BridgeUSDCExecuted(
        address indexed user,
        uint256 amount,
        uint256 protocolFee,
        address recipient
    );

    event TokenWithdrawn(address indexed token, address indexed recipient, uint256 amount);
    event NativeWithdrawn(address indexed recipient, uint256 amount);

    // ═══════════════════════════════════════════════════════════════════════════════
    // CONSTRUCTOR
    // ═══════════════════════════════════════════════════════════════════════════════

    constructor(
        address _swapRouter,
        address _weth,
        address _shidoToken,
        address _usdc,
        address _shidoNativeBridge,
        address _gateway,
        address _treasury,
        uint256 _protocolBps
    ) Ownable(msg.sender) {
        require(_swapRouter != address(0), "Invalid swap router");
        require(_weth != address(0), "Invalid WETH");
        require(_shidoToken != address(0), "Invalid SHIDO token");
        require(_usdc != address(0), "Invalid USDC");
        require(_shidoNativeBridge != address(0), "Invalid bridge");
        require(_gateway != address(0), "Invalid gateway");
        require(_treasury != address(0), "Invalid treasury");
        require(_protocolBps <= 100, "Fee cannot exceed 1%");

        swapRouter = _swapRouter;
        weth = _weth;
        shidoToken = _shidoToken;
        usdc = _usdc;
        shidoNativeBridge = _shidoNativeBridge;
        gateway = _gateway;
        treasury = _treasury;
        protocolBps = _protocolBps;
    }

    receive() external payable {}

    function routerVersion() external pure returns (string memory) {
        return "BubbleCrossChainRouterETH-v1";
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // ADMIN FUNCTIONS
    // ═══════════════════════════════════════════════════════════════════════════════

    function setSwapRouter(address _swapRouter) external onlyOwner {
        require(_swapRouter != address(0), "Invalid address");
        swapRouter = _swapRouter;
        emit SwapRouterUpdated(_swapRouter);
    }

    function setWeth(address _weth) external onlyOwner {
        require(_weth != address(0), "Invalid address");
        weth = _weth;
        emit WethUpdated(_weth);
    }

    function setShidoToken(address _shidoToken) external onlyOwner {
        require(_shidoToken != address(0), "Invalid address");
        shidoToken = _shidoToken;
        emit ShidoTokenUpdated(_shidoToken);
    }

    function setUsdc(address _usdc) external onlyOwner {
        require(_usdc != address(0), "Invalid address");
        usdc = _usdc;
        emit UsdcUpdated(_usdc);
    }

    function setShidoNativeBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Invalid address");
        shidoNativeBridge = _bridge;
        emit ShidoNativeBridgeUpdated(_bridge);
    }

    function setGateway(address _gateway) external onlyOwner {
        require(_gateway != address(0), "Invalid address");
        gateway = _gateway;
        emit GatewayUpdated(_gateway);
    }

    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Invalid address");
        treasury = _treasury;
        emit TreasuryUpdated(_treasury);
    }

    function setProtocolBps(uint256 _protocolBps) external onlyOwner {
        require(_protocolBps <= 100, "Fee cannot exceed 1%");
        protocolBps = _protocolBps;
        emit ProtocolBpsUpdated(_protocolBps);
    }

    function addToWhitelist(address account) external onlyOwner {
        require(account != address(0), "Invalid address");
        whitelist[account] = true;
        emit WhitelistUpdated(account, true);
    }

    function removeFromWhitelist(address account) external onlyOwner {
        whitelist[account] = false;
        emit WhitelistUpdated(account, false);
    }

    function batchAddToWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "Invalid address");
            whitelist[accounts[i]] = true;
            emit WhitelistUpdated(accounts[i], true);
        }
    }

    function batchRemoveFromWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
            emit WhitelistUpdated(accounts[i], false);
        }
    }

    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }

    function withdrawToken(address token, address recipient, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
        emit TokenWithdrawn(token, recipient, amount);
    }

    function withdrawNative(address payable recipient, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed");
        emit NativeWithdrawn(recipient, amount);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // INTERNAL HELPERS
    // ═══════════════════════════════════════════════════════════════════════════════

    function _approveToken(IERC20 token, address spender, uint256 amount) internal {
        token.forceApprove(spender, amount);
    }

    function _calculateFee(uint256 amount) internal view returns (uint256) {
        return (amount * protocolBps) / 10000;
    }

    function _shouldChargeFee(address user) internal view returns (bool) {
        return !whitelist[user] && protocolBps > 0;
    }

    function _validatePath(bytes calldata path) internal pure {
        require(path.length >= 43, "Path too short");
        require((path.length - 20) % 23 == 0, "Invalid path structure");
    }

    function _getFirstToken(bytes calldata path) internal pure returns (address token) {
        require(path.length >= 20, "Invalid path length");
        assembly {
            token := shr(96, calldataload(path.offset))
        }
    }

    function _getLastToken(bytes calldata path) internal pure returns (address token) {
        require(path.length >= 20, "Invalid path length");
        assembly {
            token := shr(96, calldataload(add(path.offset, sub(path.length, 20))))
        }
    }

    /// @dev Collects protocol fee from ERC20 amount, returns (feeAmount, netAmount)
    function _collectERC20Fee(address token, uint256 amount) internal returns (uint256 feeAmount, uint256 netAmount) {
        if (_shouldChargeFee(msg.sender)) {
            feeAmount = _calculateFee(amount);
            netAmount = amount - feeAmount;
            IERC20(token).safeTransfer(treasury, feeAmount);
        } else {
            netAmount = amount;
        }
    }

    /// @dev Executes swap via router and returns amount out
    function _executeSwap(
        bytes calldata path,
        address tokenIn,
        uint256 swapAmount,
        uint256 minAmountOut
    ) internal returns (uint256 amountOut) {
        _approveToken(IERC20(tokenIn), swapRouter, swapAmount);
        amountOut = ISwapRouter(swapRouter).exactInput(
            ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                amountIn: swapAmount,
                amountOutMinimum: minAmountOut
            })
        );
    }

    /// @dev Bridges SHIDO (ERC20) to Shido Network via ShidoNativeBridge.crossBack
    function _bridgeShidoViaNativeBridge(uint256 amount, BridgeParams calldata bp) internal {
        _approveToken(IERC20(shidoToken), shidoNativeBridge, amount);
        IShidoNativeBridge(shidoNativeBridge).crossBack(
            shidoToken,
            SHIDO_CHAIN_ID,
            bp.recipient,
            amount,
            bp.destinationGasLimit,
            bp.bridgeFee,
            bp.bridgeDeadline,
            bp.bridgeSignature
        );
    }

    /// @dev Bridges USDC to Shido Network via Gateway.crossTo
    function _bridgeUSDCViaGateway(uint256 amount, BridgeParams calldata bp) internal {
        _approveToken(IERC20(usdc), gateway, amount);
        IGateway(gateway).crossTo(
            usdc,
            SHIDO_CHAIN_ID,
            bp.recipient,
            amount,
            bp.destinationGasLimit,
            bp.bridgeFee,
            bp.bridgeDeadline,
            bp.bridgeSignature
        );
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // SWAP AND BRIDGE: Token → SHIDO (ETH) → SHIDO (Shido Network)
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Swap any ERC20 token to SHIDO on Ethereum, then bridge to Shido Network
     * @param path Uniswap V3 encoded path (must end with SHIDO token)
     * @param amountIn Amount of input token
     * @param minShidoOut Minimum SHIDO amount after swap
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     * @param swapDeadline Deadline for the swap
     */
    function swapAndBridge(
        bytes calldata path,
        uint256 amountIn,
        uint256 minShidoOut,
        BridgeParams calldata bp,
        uint256 swapDeadline
    ) external nonReentrant whenNotPaused {
        require(swapDeadline >= block.timestamp, "Swap deadline expired");
        require(amountIn > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");
        _validatePath(path);
        require(_getLastToken(path) == shidoToken, "Path must end with SHIDO");

        address tokenIn = _getFirstToken(path);
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        (uint256 protocolFee, uint256 swapAmount) = _collectERC20Fee(tokenIn, amountIn);

        uint256 shidoAmount = _executeSwap(path, tokenIn, swapAmount, minShidoOut);

        _bridgeShidoViaNativeBridge(shidoAmount, bp);

        emit SwapAndBridgeExecuted(msg.sender, tokenIn, amountIn, shidoAmount, protocolFee, bp.recipient);
    }

    /**
     * @notice Swap ETH to SHIDO on Ethereum, then bridge to Shido Network
     * @param path Uniswap V3 encoded path (must start with WETH, end with SHIDO)
     * @param minShidoOut Minimum SHIDO amount after swap
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     * @param swapDeadline Deadline for the swap
     */
    function swapAndBridgeFromNative(
        bytes calldata path,
        uint256 minShidoOut,
        BridgeParams calldata bp,
        uint256 swapDeadline
    ) external payable nonReentrant whenNotPaused {
        require(swapDeadline >= block.timestamp, "Swap deadline expired");
        require(msg.value > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");
        _validatePath(path);
        require(_getFirstToken(path) == weth, "Path must start with WETH");
        require(_getLastToken(path) == shidoToken, "Path must end with SHIDO");

        IWETH9(weth).deposit{value: msg.value}();

        (uint256 protocolFee, uint256 swapAmount) = _collectERC20Fee(weth, msg.value);

        uint256 shidoAmount = _executeSwap(path, weth, swapAmount, minShidoOut);

        _bridgeShidoViaNativeBridge(shidoAmount, bp);

        emit SwapAndBridgeExecuted(msg.sender, address(0), msg.value, shidoAmount, protocolFee, bp.recipient);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // BRIDGE SHIDO ONLY: SHIDO (ETH) → SHIDO (Shido Network)
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Bridge SHIDO from Ethereum to Shido Network with protocol fee
     * @param amount Amount of SHIDO to bridge
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     */
    function bridgeShido(
        uint256 amount,
        BridgeParams calldata bp
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");

        IERC20(shidoToken).safeTransferFrom(msg.sender, address(this), amount);

        (uint256 protocolFee, uint256 bridgeAmount) = _collectERC20Fee(shidoToken, amount);

        _bridgeShidoViaNativeBridge(bridgeAmount, bp);

        emit BridgeShidoExecuted(msg.sender, bridgeAmount, protocolFee, bp.recipient);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // BRIDGE USDC ONLY: USDC (ETH) → USDC (Shido Network)
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Bridge USDC from Ethereum to Shido Network with protocol fee
     * @param amount Amount of USDC to bridge
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     */
    function bridgeUSDC(
        uint256 amount,
        BridgeParams calldata bp
    ) external nonReentrant whenNotPaused {
        require(amount > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");

        IERC20(usdc).safeTransferFrom(msg.sender, address(this), amount);

        (uint256 protocolFee, uint256 bridgeAmount) = _collectERC20Fee(usdc, amount);

        _bridgeUSDCViaGateway(bridgeAmount, bp);

        emit BridgeUSDCExecuted(msg.sender, bridgeAmount, protocolFee, bp.recipient);
    }

    // ═══════════════════════════════════════════════════════════════════════════════
    // SWAP AND BRIDGE USDC: Token → USDC (ETH) → USDC (Shido Network)
    // ═══════════════════════════════════════════════════════════════════════════════

    /**
     * @notice Swap any ERC20 token to USDC on Ethereum, then bridge to Shido Network
     * @param path Uniswap V3 encoded path (must end with USDC)
     * @param amountIn Amount of input token
     * @param minUsdcOut Minimum USDC amount after swap
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     * @param swapDeadline Deadline for the swap
     */
    function swapAndBridgeUSDC(
        bytes calldata path,
        uint256 amountIn,
        uint256 minUsdcOut,
        BridgeParams calldata bp,
        uint256 swapDeadline
    ) external nonReentrant whenNotPaused {
        require(swapDeadline >= block.timestamp, "Swap deadline expired");
        require(amountIn > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");
        _validatePath(path);
        require(_getLastToken(path) == usdc, "Path must end with USDC");

        address tokenIn = _getFirstToken(path);
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        (uint256 protocolFee, uint256 swapAmount) = _collectERC20Fee(tokenIn, amountIn);

        uint256 usdcAmount = _executeSwap(path, tokenIn, swapAmount, minUsdcOut);

        _bridgeUSDCViaGateway(usdcAmount, bp);

        emit BridgeUSDCExecuted(msg.sender, usdcAmount, protocolFee, bp.recipient);
    }

    /**
     * @notice Swap ETH to USDC on Ethereum, then bridge to Shido Network
     * @param path Uniswap V3 encoded path (must start with WETH, end with USDC)
     * @param minUsdcOut Minimum USDC amount after swap
     * @param bp Bridge parameters (recipient, gasLimit, fee, deadline, signature)
     * @param swapDeadline Deadline for the swap
     */
    function swapAndBridgeUSDCFromNative(
        bytes calldata path,
        uint256 minUsdcOut,
        BridgeParams calldata bp,
        uint256 swapDeadline
    ) external payable nonReentrant whenNotPaused {
        require(swapDeadline >= block.timestamp, "Swap deadline expired");
        require(msg.value > 0, "Amount must be > 0");
        require(bp.recipient != address(0), "Invalid recipient");
        _validatePath(path);
        require(_getFirstToken(path) == weth, "Path must start with WETH");
        require(_getLastToken(path) == usdc, "Path must end with USDC");

        IWETH9(weth).deposit{value: msg.value}();

        (uint256 protocolFee, uint256 swapAmount) = _collectERC20Fee(weth, msg.value);

        uint256 usdcAmount = _executeSwap(path, weth, swapAmount, minUsdcOut);

        _bridgeUSDCViaGateway(usdcAmount, bp);

        emit BridgeUSDCExecuted(msg.sender, usdcAmount, protocolFee, bp.recipient);
    }
}
