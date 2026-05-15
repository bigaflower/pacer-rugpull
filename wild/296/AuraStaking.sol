// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title AuraStaking V10 - Evolution Edition
 * @author AURA Security
 * @notice Staking com ciclo de 3 dias, multa de 20%, reserva de 5M e Router editável.
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

interface IDexRouter {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function WETH() external pure returns (address);
}

contract AuraStaking is Ownable, ReentrancyGuard {
    
    IERC20 public immutable auraToken;
    IDexRouter public dexRouter; 
    
    // --- ENDEREÇOS FIXOS INICIAIS ---
    address public constant AURA_ADDRESS = 0xcb324428b1b6cda7b1936bd13BC4fe722c66aB6A;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Uniswap V2

    // --- VARIÁVEIS DE SEGURANÇA E ESCASSEZ ---
    uint256 public totalStakedPrincipal; 
    uint256 public uniqueStakers;        
    uint256 public constant MAX_EARLY_BIRDS = 200; 
    uint256 public targetReserve = 5_000_000 * 10**18; 

    struct PoolInfo {
        string name;
        uint256 lockDuration; 
        uint256 rateEarly;    
        uint256 rateStandard; 
        uint256 maxStakePerWallet; 
        bool isActive;
    }

    struct UserStake {
        uint256 amount;
        uint256 depositTime;
        uint256 lastHarvestTime;
        uint256 poolId;
        uint256 lockedRate;
    }
    
    mapping(address => mapping(uint256 => uint256)) public userPoolBalance;
    mapping(address => bool) public isEarlyAdopter;

    PoolInfo[] public pools;
    mapping(address => UserStake[]) public userStakes;

    event Staked(address indexed user, uint256 amount, uint256 poolId, uint256 rateApplied);
    event Harvested(address indexed user, uint256 rewardAmount);
    event EmergencyWithdrawn(address indexed user, uint256 amountRecovered, uint256 amountBurned);
    event BuybackExecuted(uint256 ethSpent, uint256 auraBought, string typeOfBuy);
    event RouterUpdated(address indexed oldRouter, address indexed newRouter);

    constructor() Ownable(msg.sender) {
        auraToken = IERC20(AURA_ADDRESS);
        dexRouter = IDexRouter(currentRouter);

        // --- CONFIGURAÇÃO DE POOLS (TAXAS VIP DO PDF) ---
        // Flexible: 0.05% dia | Guard: 0.20% dia | Kairos: 0.33% dia | [cite_start]Eternity: 0.50% dia [cite: 8, 9, 10, 11]
        pools.push(PoolInfo("FLEXIBLE", 0, 5, 2, 10000000 * 10**18, true));        
        pools.push(PoolInfo("GUARD", 30 days, 20, 10, 10000000 * 10**18, true));    
        pools.push(PoolInfo("KAIROS", 90 days, 33, 16, 1000000 * 10**18, true));   
        pools.push(PoolInfo("ETERNITY", 365 days, 50, 25, 1000000 * 10**18, true));
    }

    receive() external payable {}

    // ==========================================
    // FUNÇÕES DE USUÁRIO (STAKING)
    // ==========================================

    function deposit(uint256 _poolId, uint256 _amount) external nonReentrant {
        require(_poolId < pools.length && pools[_poolId].isActive, "Pool invalida");
        
        if (pools[_poolId].maxStakePerWallet > 0) {
            require(userPoolBalance[msg.sender][_poolId] + _amount <= pools[_poolId].maxStakePerWallet, "Limite Anti-Whale");
        }

        if (!isEarlyAdopter[msg.sender] && uniqueStakers < MAX_EARLY_BIRDS) {
            isEarlyAdopter[msg.sender] = true;
            uniqueStakers++;
        }

        uint256 rateToUse = isEarlyAdopter[msg.sender] ? pools[_poolId].rateEarly : pools[_poolId].rateStandard;

        uint256 balanceBefore = auraToken.balanceOf(address(this));
        require(auraToken.transferFrom(msg.sender, address(this), _amount), "Erro transferencia");
        uint256 realAmount = auraToken.balanceOf(address(this)) - balanceBefore;

        totalStakedPrincipal += realAmount; 
        userPoolBalance[msg.sender][_poolId] += realAmount;

        userStakes[msg.sender].push(UserStake({
            amount: realAmount,
            depositTime: block.timestamp,
            lastHarvestTime: block.timestamp,
            poolId: _poolId,
            lockedRate: rateToUse
        }));

        emit Staked(msg.sender, realAmount, _poolId, rateToUse);
    }

    function harvest(uint256 _stakeIndex) external nonReentrant {
        UserStake storage stakeInfo = userStakes[msg.sender][_stakeIndex];
        
        // --- CICLO DE 3 DIAS ---
        require(block.timestamp >= stakeInfo.lastHarvestTime + 3 days, "Aguarde 3 dias");

        uint256 reward = _calculatePendingReward(stakeInfo);
        require(reward > 0, "Sem recompensas");
        
        require(auraToken.balanceOf(address(this)) >= totalStakedPrincipal + reward, "Refill necessario");

        stakeInfo.lastHarvestTime = block.timestamp;
        auraToken.transfer(msg.sender, reward); 
        emit Harvested(msg.sender, reward);
    }

    function emergencyWithdraw(uint256 _stakeIndex) external nonReentrant {
        UserStake storage stakeInfo = userStakes[msg.sender][_stakeIndex];
        uint256 amountToTransfer = stakeInfo.amount;
        uint256 penalty = 0;

        // --- MULTA DE 20% PARA QUEIMA ---
        if (block.timestamp < stakeInfo.depositTime + pools[stakeInfo.poolId].lockDuration) {
            penalty = (stakeInfo.amount * 20) / 100; 
            amountToTransfer -= penalty;
            auraToken.transfer(DEAD_ADDRESS, penalty);
        }

        totalStakedPrincipal -= stakeInfo.amount;
        userPoolBalance[msg.sender][stakeInfo.poolId] -= stakeInfo.amount;

        auraToken.transfer(msg.sender, amountToTransfer);
        
        uint256 lastIndex = userStakes[msg.sender].length - 1;
        userStakes[msg.sender][_stakeIndex] = userStakes[msg.sender][lastIndex];
        userStakes[msg.sender].pop();

        emit EmergencyWithdrawn(msg.sender, amountToTransfer, penalty);
    }

    // ==========================================
    // FUNÇÕES DE ADMIN E MIGRAÇÃO
    // ==========================================

    function updateRouter(address _newRouter) external onlyOwner {
        require(_newRouter != address(0), "Endereco invalido");
        address oldRouter = address(dexRouter);
        dexRouter = IDexRouter(_newRouter);
        currentRouter = _newRouter;
        emit RouterUpdated(oldRouter, _newRouter);
    }

    function autoFillReserve() external payable onlyOwner {
        uint256 totalNeeded = totalStakedPrincipal + targetReserve;
        uint256 currentBalance = auraToken.balanceOf(address(this));
        if (currentBalance >= totalNeeded) return;

        uint256 amountMissing = totalNeeded - currentBalance;
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = AURA_ADDRESS;

        uint[] memory amountsIn = dexRouter.getAmountsIn(amountMissing, path);
        uint256 ethRequired = amountsIn[0];

        require(msg.value >= ethRequired, "ETH insuficiente");

        dexRouter.swapETHForExactTokens{value: ethRequired}(
            amountMissing, 
            path, 
            address(this), 
            block.timestamp + 300
        );

        if (msg.value > ethRequired) {
            payable(msg.sender).transfer(msg.value - ethRequired);
        }

        emit BuybackExecuted(ethRequired, amountMissing, "AUTO FILL");
    }

    function manualPump() external payable onlyOwner {
        require(msg.value > 0, "Envie ETH");
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = AURA_ADDRESS;
        
        uint256 balanceBefore = auraToken.balanceOf(address(this));
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0, path, address(this), block.timestamp + 300
        );
        uint256 bought = auraToken.balanceOf(address(this)) - balanceBefore;
        
        emit BuybackExecuted(msg.value, bought, "MANUAL PUMP");
    }

    function rescueExcessTokens(uint256 _amount) external onlyOwner {
        uint256 contractBalance = auraToken.balanceOf(address(this));
        require(contractBalance - totalStakedPrincipal >= _amount, "Dinheiro de usuario protegido");
        auraToken.transfer(msg.sender, _amount);
    }

    function setTargetReserve(uint256 _newTarget) external onlyOwner {
        targetReserve = _newTarget;
    }

    function _calculatePendingReward(UserStake memory _stake) internal view returns (uint256) {
        uint256 daysPassed = (block.timestamp - _stake.lastHarvestTime) / 1 days;
        return (_stake.amount * _stake.lockedRate * daysPassed) / 10000;
    }
}