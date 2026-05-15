// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
import {ERC4626, SafeERC20, OwnableDelayModuleV2} from "./OwnableDelayModuleV2.sol";
import {Pausable} from "./Pausable.sol";
import "./ERC20.sol";
import {Math} from "./Math.sol";
import "./ArrayUtils.sol";

interface IAFi {
    function deposit(uint amount, address iToken) external;
    function getInputToken() external view returns (address[] memory, address[] memory);
    function withdraw(
        uint _shares,
        address oToken,
        uint deadline,
        uint[] memory minimumReturnAmount,
        uint swapMethod,
        uint minAmountOut
    ) external;
    function getUTokens() external view returns (address[] memory uTokensArray);
    function pauseUnpauseDeposit(bool status) external;
    function totalSupply() external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function getcSwapCounter() external view returns(uint256);
    function aFiStorage() external view returns (address);
    function exchangeToken() external;
    function PARENT_VAULT() external view returns (address);
}

interface IAFiStorage{
    function calculatePoolInUsd(address afiContract) external view returns (uint);
}

interface IAFiOracle {
    function getPriceInUSD(address tok) external view returns (uint256, uint256);
}

contract AtvWrappedBoosterTL is ERC4626, OwnableDelayModuleV2, Pausable{
    using SafeERC20 for IERC20;
    using ArrayUtils for address[];
    using Math for uint256;

    uint256 public platformFee;
    uint256 maxChkpts = 100000;
    uint256 public currentEpochId;

    uint256 public constant MAX_PLATFORM_FEE = 200;
    uint256 private constant UNIT_NAV = 1e27;
    uint256 private constant FEE_DIV = 10000;
   
    address public platformWallet;
    address public controller;
    address public atvStorage;
    address public atvOracle;
    address private immutable UNDERLYING;

    uint256 public deadlineDelay = 1 hours;
    bool public pauseDeposit;

    mapping(address => uint256) public latestEpoch;
    
    struct TWABCheckpoint {
        uint256 timestamp;
        uint256 balance;
        uint256 accBal;
    }
    
    struct UserTWAB {
        TWABCheckpoint[] checkpoints;
        uint256 lastUpdateTime;
    }
        
    struct Epoch {
        uint256 startTime;
        uint256 endTime;
        uint256 startNAV;
        uint256 endNAV;
        bool finalized;
    }

    Epoch[] public epochs;
    IAFi public ATV_VAULT;
    uint256 public totalVaultTokenRec; // Indicates total ATV_VAULT tokens through the flow

    mapping(address => uint256[]) public userEpochIDs;
    mapping(address => mapping( uint256 => bool)) public presentInEpoch;
    mapping(address => mapping(uint256 => UserTWAB)) public userTWAB;

    event MigrateVault(address _oldVault, address _newVault);
    event CalledExchange(address _oldVault, address _newVault, uint256 exchangedBalance);
    event WithdrawStrayToken(address token, uint256 amount);
    event PauseUnpauseDeposit(bool _pauseDeposit);
    event UpdatePlatformWallet(address _platformWallet);
    event UpdatePlatformFee(uint256 _platformFee);
    event AdjustExtraAsset(address to, uint256 extra);
    event EpochStarted(uint256 indexed epochId, uint256 startTime, uint256 startNAV);
    event EpochFinalized(uint256 indexed epochId, uint256 endTime, uint256 endNAV);
    event TWABUpdated(address indexed user, uint256 indexed epochId, uint256 newBalance, uint256 timestamp, uint256 checkpointCount);
    event ThresholdExceeded(address indexed user, uint256 indexed epochId, uint256 checkpointCount);
    event SetController(address _controller);
    event MaxCheckpointsSet(uint256 newLimit);

    // Custom errors
    error E01(); // Zero address
    error E02(); // Zero value
    error E03(); // Invalid epoch
    error E04(); // Not controller
    error E05(); // Deposit paused
    error E06(); // Fee exceeds max
    error E07(); // Invalid range
    error E08(); // Not parent vault
    error E09(); // Transfer to self
    error E10(); // Cannot withdraw asset
    error E11(); // Insufficient extra asset
    error E12(); // Invalid withdraw
    error E13(); // Insufficient received
    error E14(); // Disabled function
    error E15(); // Already finalized
    error E16(); // No active epoch
    error E17(); // Not finalized
    error E18(); // Invalid condition

    constructor(ERC20 _underlyingToken, address _atvVault, address _atvStorage, address _atvOracle)
        ERC20("aarna atv USDC", "atvUSDC")
        ERC4626(_underlyingToken)
    {
        _chkAddr(address(_underlyingToken));
        _chkAddr(_atvOracle);
        UNDERLYING = address(_underlyingToken);
        atvStorage = _atvStorage;
        atvOracle = _atvOracle;
        ATV_VAULT = IAFi(_atvVault); 
        _startNewEpoch();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // Validation functions
    function _chkAddr(address a) private pure {
        if(a == address(0)) revert E01();
    }

    function _chkGt0(uint256 v) private pure {
        if(v == 0) revert E02();
    }

    function _chkCond(bool cond) private pure {
        if(!cond) revert E18();
    }

    function _chkLte(uint256 a, uint256 b) private pure {
        if(a > b) revert E06();
    }

    function _chkRange(uint256 v, uint256 min, uint256 max) private pure {
        if(v < min || v > max) revert E07();
    }

    function _chkEq(address a, address b) private pure {
        if(a != b) revert E04();
    }

    function _chkNeq(address a, address b) private pure {
        if(a == b) revert E09();
    }

    function pauseUnpauseDeposit(bool status) external onlyOwner {
        pauseDeposit = status;
        emit PauseUnpauseDeposit(pauseDeposit);
    }

    function updatePlatformWalletAndFee(address _platformWallet, uint256 _fee) external onlyOwner{
        platformWallet = _platformWallet;
        _chkLte(_fee, MAX_PLATFORM_FEE);
        platformFee = _fee;
        emit UpdatePlatformWallet(platformWallet);
    }
    
    function updateMaxCheckpoints(uint256 newLimit) external onlyOwner {
        _chkRange(newLimit, 10, 100000);
        maxChkpts = newLimit;
        emit MaxCheckpointsSet(newLimit);
    }

    function migrateVault(address _vault) external onlyOwner whenPaused {
        address vault = address(ATV_VAULT);
        if(IAFi(_vault).PARENT_VAULT() != vault) revert E08();
        address oldVault = vault;
        ATV_VAULT = IAFi(_vault);
        emit MigrateVault(oldVault, address(ATV_VAULT));
    }

    function callExchange() external onlyOwner whenPaused{
        address oldVault = ATV_VAULT.PARENT_VAULT();
        address vault = address(ATV_VAULT);
        uint256 bal = _sBal(oldVault);
        IERC20(oldVault).approve(vault, bal);
        ATV_VAULT.exchangeToken();
        emit CalledExchange(oldVault, vault, bal);
    }

    function updateatvStorageAndOracle(address _atvStorage, address _atvOracle) external onlyOwner {
        _chkAddr(_atvStorage);
        atvStorage = _atvStorage; 
        atvOracle = _atvOracle;
    }

    function setController(address _controller) external onlyOwner {
        _chkAddr(_controller);
        controller = _controller;
        emit SetController(_controller);
    }

    function calculateNAV() public view returns(uint256 assetNAV) {
        address vault = address(ATV_VAULT);
        uint256 supply = IERC20(vault).totalSupply();
        _chkGt0(supply);
        assetNAV = (IAFiStorage(atvStorage).calculatePoolInUsd(vault) * UNIT_NAV) / supply;
    }

    // Helper functions
    function _sBal(address token) private view returns(uint256){
        return IERC20(token).balanceOf(address(this));
    }

    function _getBalDiff(address token, uint256 before) private view returns (uint256) {
        uint256 diff = _sBal(token) - before;
        _chkGt0(diff);
        return diff;
    }

    function _getPrice() private view returns (uint256, uint256) {
        return IAFiOracle(atvOracle).getPriceInUSD(UNDERLYING);
    }

    function _navMath(uint256 amount, uint256 nav, bool toShares) private pure returns (uint256) {
        if (toShares) {
            // For converting assets to shares, amount is in USD with 6 decimal precision
            // We need to return 18 decimal shares
            return (amount * UNIT_NAV * (10**12)) / nav;
        }
        // For converting shares to assets, amount is in 18 decimals
        // We need to return USD with 6 decimal precision
        return (amount * nav) / (UNIT_NAV * (10**12));
    }   

    function _processDeposit(uint256 atvShares, uint256 assets, address receiver) private {
        totalVaultTokenRec += atvShares;
        _mint(receiver, atvShares);
        _addCheckpoint(receiver, balanceOf(receiver));
        emit Deposit(_msgSender(), receiver, assets, atvShares);
    }
    
    function _addCheckpoint(address user, uint256 newBalance) internal {
        UserTWAB storage twab = userTWAB[user][currentEpochId];
        uint256 currentTime = block.timestamp;
        uint256 timeDelta;

        if (twab.checkpoints.length > 0) {
            TWABCheckpoint storage lastCheckpoint = _lastCheckpoint(twab);
            timeDelta = currentTime - lastCheckpoint.timestamp;

            if(timeDelta > 0) {
                twab.checkpoints.push(TWABCheckpoint({
                    timestamp: currentTime,
                    balance: newBalance,
                    accBal: (lastCheckpoint.accBal + (lastCheckpoint.balance * timeDelta))
                }));
            }else {
                lastCheckpoint.balance = newBalance;
            }
        } else {
            if(latestEpoch[user] > 0){
                UserTWAB storage lastTwab = userTWAB[user][latestEpoch[user]];
                TWABCheckpoint storage lastCheckpoint = lastTwab.checkpoints[lastTwab.checkpoints.length - 1];
                Epoch memory epoch = epochs[currentEpochId - 1];
                timeDelta = currentTime - epoch.startTime;
                
                twab.checkpoints.push(TWABCheckpoint({
                    timestamp: currentTime,
                    balance: newBalance,
                    accBal: (lastCheckpoint.balance * timeDelta)
                }));
            } else {
                twab.checkpoints.push(TWABCheckpoint({
                    timestamp: currentTime,
                    balance: newBalance,
                    accBal: 0
                }));
            }
        }
        
        twab.lastUpdateTime = currentTime;
        latestEpoch[user] = currentEpochId;
        
        if(!presentInEpoch[user][currentEpochId]){
            presentInEpoch[user][currentEpochId] = true;
            userEpochIDs[user].push(currentEpochId);
        }
        
        if (twab.checkpoints.length >= maxChkpts) {
            emit ThresholdExceeded(user, currentEpochId, twab.checkpoints.length);
        }
        
        emit TWABUpdated(user, currentEpochId, newBalance, currentTime, twab.checkpoints.length);
    }

    function _getTWABBetween(address user, uint256 epochId) internal view returns (uint256) {
        UserTWAB memory twab = userTWAB[user][epochId];
        if (twab.checkpoints.length == 0) return 0;

        Epoch memory epoch = epochs[epochId - 1];
        TWABCheckpoint memory lastCheckpoint = twab.checkpoints[twab.checkpoints.length - 1];
        
        uint256 totalWeighted = lastCheckpoint.accBal;
        uint256 extraTime = epoch.endTime - lastCheckpoint.timestamp;
        totalWeighted += lastCheckpoint.balance * extraTime;
        
        uint256 timeDelta = epoch.endTime - epoch.startTime;
        if (timeDelta == 0) return 0;
        
        return totalWeighted / timeDelta;
    }

    function _startNewEpoch() internal {
        uint256 currentNAV = calculateNAV();
        
        epochs.push(Epoch({
            startTime: block.timestamp,
            endTime: 0,
            startNAV: currentNAV,
            endNAV: 0,
            finalized: false
        }));
        
        currentEpochId = epochs.length;
        emit EpochStarted(currentEpochId, block.timestamp, currentNAV);
    }
    
    function finalizeEpoch() external {
        _chkEq(msg.sender, controller);
        Epoch storage epoch = _ensureActiveEpoch();
        if(epoch.finalized) revert E15();
        
        epoch.endTime = block.timestamp;
        epoch.endNAV = calculateNAV();
        epoch.finalized = true;
        
        emit EpochFinalized(currentEpochId, epoch.endTime, epoch.endNAV);
        _startNewEpoch();
    }

    function _ensureActiveEpoch() internal view returns (Epoch storage epoch) {
        if(currentEpochId >= epochs.length + 1) revert E16();
        return epochs[currentEpochId - 1];
    }
    
    function calculateEpochReward(address user, uint256 epochId) public view returns (uint256) {
        if(epochId == 0 || epochId > epochs.length) revert E03();
        Epoch memory epoch = epochs[epochId - 1];
        if(!epoch.finalized) revert E17();
        
        if (epoch.endNAV <= epoch.startNAV) return 0;

        uint256 uTWAB = _getTWABBetween(user, epochId);
        if (uTWAB == 0) {
            uTWAB = calculateLastCheckpointBalance(user, epochId);
            if(uTWAB == 0) return 0;
        } 
      
        uint256 navIncrease = epoch.endNAV - epoch.startNAV;
        return (uTWAB * navIncrease) / UNIT_NAV;
    }

    function getLastEpochBeforeCurrent(address user, uint256 currentEpoch) public view returns (uint256) {
        uint256[] memory epochsForUser = userEpochIDs[user];
        uint256 len = epochsForUser.length;

        if (len == 0) return 0;

        uint256 left = 0;
        uint256 right = len;

        while (left < right) {
            uint256 mid = (left + right) / 2;
            if (epochsForUser[mid] < currentEpoch) {
                left = mid + 1;
            } else {
                right = mid;
            }
        }

        if (left == 0) return 0;
        return epochsForUser[left - 1];
    }

    function calculateLastCheckpointBalance(address user, uint256 currentEpoch) internal view returns (uint256) {
        uint256 lastEpochId = getLastEpochBeforeCurrent(user, currentEpoch);
        if (lastEpochId == 0) return 0;

        UserTWAB storage twab = userTWAB[user][lastEpochId];
        uint256 length = twab.checkpoints.length;
        if (length == 0) return 0;
        return _lastCheckpoint(twab).balance;
    }

    function _lastCheckpoint(UserTWAB storage twab) internal view returns (TWABCheckpoint storage) {
        return twab.checkpoints[twab.checkpoints.length - 1];
    }

    function totalAssets() public view virtual override returns (uint256) {
        return _convertToAssets(_sBal(address(ATV_VAULT)), Math.Rounding.Floor);
    }

    function decimals() public view virtual override returns (uint8) {
        return 18 + _decimalsOffset();
    }

    function transfer(address to, uint256 shares) public override(ERC20, IERC20) returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, shares);
        _tHelper(msg.sender, to);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public virtual override(ERC20, IERC20) returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        _tHelper(from, to);
        return true;
    }

    function _tHelper(address from, address to) internal whenNotPaused {
        _chkNeq(from, to);
        _addCheckpoint(from, balanceOf(from));
        _addCheckpoint(to, balanceOf(to));
    }

    function withdrawStrayToken(address token) external onlyOwner{
        if(token == address(ATV_VAULT)) revert E10();
        uint256 bal = _sBal(token);
        IERC20(token).safeTransfer(msg.sender, bal);
        emit WithdrawStrayToken(token, bal);
    }

    function redeem(uint256, address, address) public pure virtual override returns (uint256) {
        revert E14();
    }
   
    function mint(uint256, address) public pure override returns (uint256) {
        revert E14();
    }
    
    function getUserCheckpoints(address user, uint256 epochId) external view returns (TWABCheckpoint[] memory) {
        return userTWAB[user][epochId].checkpoints;
    }
    
    function getCurrentEpoch() external view returns (Epoch memory) {
        return _ensureActiveEpoch();
    }

    function adjustExtraVaultTokens(address to) external onlyOwner{
        uint256 totalBal = _sBal(address(ATV_VAULT));
        if(totalBal <= totalVaultTokenRec) revert E11();
        uint256 extra = totalBal - totalVaultTokenRec;
        IERC20(address(ATV_VAULT)).safeTransfer(to, extra);
        emit AdjustExtraAsset(to, extra);
    }

    function exchange(uint256 shares, address receiver) public virtual whenNotPaused returns (uint256) {
        _chkGt0(shares);
        if(pauseDeposit) revert E05();
        address vault = address(ATV_VAULT);
        uint256 before = _sBal(vault);
        SafeERC20.safeTransferFrom(IERC20(vault), msg.sender, address(this), shares); // Always take from msg.sender
        uint256 atvShares = _getBalDiff(vault, before);
        (uint256 price, uint256 dec) = _getPrice();
        atvShares = (atvShares * (10**dec))/ price;
        uint256 assets = _navMath(atvShares, calculateNAV(), false);
        _processDeposit(atvShares, assets, receiver);
        return atvShares;
    }

    function deposit(uint256 assets, address receiver) public virtual override whenNotPaused returns (uint256) {
        _chkGt0(assets);
        if(pauseDeposit) revert E05();
        address vault = address(ATV_VAULT);
        IERC20 token = IERC20(UNDERLYING);
        uint256 before = _sBal(vault);
        SafeERC20.safeTransferFrom(token, msg.sender, address(this), assets);
        token.approve(vault, assets);
        ATV_VAULT.deposit(assets, UNDERLYING);
        
        uint256 atvShares = _getBalDiff(vault, before);
        _processDeposit(atvShares, assets, receiver);
        return atvShares;
    }

    function _getMinReturnAmounts() internal view returns (uint256[] memory) {
        uint256 ulen = ATV_VAULT.getUTokens().length;
        return new uint256[](ulen);
    }

    function withdraw(uint256 shares, address receiver, address owner) public virtual override whenNotPaused returns (uint256) {
        _chkGt0(shares);

        if (_msgSender() != owner) {
            _spendAllowance(owner, _msgSender(), shares);
        }     
           
        uint256 assets = convertToAssets(shares);
        uint256 maxAssets = maxWithdraw(owner);
        if (assets > maxAssets) revert ERC4626ExceededMaxWithdraw(owner, assets, maxAssets);
        
        _burn(owner, shares);
        totalVaultTokenRec -= shares;

        emit Withdraw(_msgSender(), receiver, owner, assets, shares);
        _addCheckpoint(owner, balanceOf(owner));

        uint256 before = _sBal(UNDERLYING);
        uint deadline = block.timestamp + deadlineDelay;
        uint[] memory minimumReturnAmount = _getMinReturnAmounts();
        
        ATV_VAULT.withdraw(
            shares, 
            UNDERLYING,
            deadline,
            minimumReturnAmount,
            3,
            assets
        );        

        uint256 vaultTokensReceived = _getBalDiff(UNDERLYING, before);
        _chkCond(vaultTokensReceived >= assets);
        
        uint256 pF = (vaultTokensReceived * platformFee) / FEE_DIV;

        if(pF > 0 && platformWallet != address(0)){
            vaultTokensReceived -= pF;
            IERC20(UNDERLYING).safeTransfer(platformWallet, pF);
        }

        IERC20(UNDERLYING).safeTransfer(receiver, vaultTokensReceived);      
        return vaultTokensReceived;
    }

   function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual override returns (uint256) {
        (uint256 price, uint256 dec) = _getPrice();
        assets = assets - (assets / 100); // 1% fee
        uint256 assetInUSD = (assets * price) / (10 ** dec);
        return _navMath(assetInUSD, calculateNAV(), true);
    }


    function _convertToSharesForWithdraw(uint256 assets) internal view virtual returns (uint256) {
        (uint256 price, uint256 dec) = _getPrice();
        uint256 assetInUSD = (assets * price ) / (10 ** dec);
        return _navMath(assetInUSD, calculateNAV(), true);
    }

    function previewWithdraw(uint256 assets) public view virtual override returns (uint256) {
        assets = (assets * 10000) / (10000 - platformFee); 
        return _convertToSharesForWithdraw(assets);
    }
   
    function previewRedeem(uint256 shares) public view virtual override returns (uint256) {
        shares = (shares * (10000 - platformFee)) / 10000; 
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    function convertToShares(uint256 assets) public view virtual override returns (uint256) {
        return _convertToSharesForWithdraw(assets);
    }

    function convertToAssets(uint256 shares) public view virtual override returns (uint256) {
        return _convertToAssets(shares, Math.Rounding.Floor);
    }

    function previewMint(uint256 shares) public view virtual override returns (uint256) {
        return (_convertToAssets(shares, Math.Rounding.Ceil) * 100 / 99);
    }

    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual override returns (uint256) {
        (uint256 price, uint256 dec) = _getPrice();
        uint256 sharesInUSD = _navMath(shares, calculateNAV(), false);
        return (sharesInUSD * (10 ** dec)) / price;
    }
}