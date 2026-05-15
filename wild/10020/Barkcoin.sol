// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ERC20.sol";
import "./Ownable.sol";

contract Barkcoin is ERC20, Ownable {

    uint256 private constant TOTAL_SUPPLY = 1e26;
    uint256 public constant LOCK_DURATION = 302400;// 42 days

    address public barkcoinContorl;
    uint8 private _burnRate;
    mapping(address => bool) private _whitelist;
    mapping(address => uint256) private _lockUntilBlock;

    struct LockInfo {
        uint256 amount;
        uint256 unlockBlock;
    }

    mapping(address => LockInfo[]) private _exchangeLocks;
    mapping(address => uint256) private _exchangeTotal;
    mapping(address => uint256) private _exchangeIndex;

    event ControlChanged(address newControl);
    event BurnRateChanged(uint256 newBurnRate);
    event AddressWhitelisted(address indexed account, bool state);
    event AddressLocked(address indexed account, uint256 unlockBlock);
    event AddressUnlocked(address indexed account);

    modifier checkExchange() {
        require(msg.sender == barkcoinContorl, "Invalid caller");
        _;
    }

    constructor(address initialOwner, string memory _name, string memory _symbol) ERC20(_name, _symbol) Ownable(initialOwner) {
        _mint(initialOwner, TOTAL_SUPPLY);
    }

    function burnCompute(address from, uint256 amount) internal view returns (uint256) {
        if (!_whitelist[from] && _burnRate > 0) {
            return (amount * _burnRate) / 10000;
        }
        return 0;
    }

    function exchangeCompute(address from, uint256 amount) internal {
        uint256 unlockAmount = 0;
        uint256 remainingAmount = amount;
        uint256 index = _exchangeIndex[from];

        for (uint256 i = index; i < _exchangeLocks[from].length; i++) {
            LockInfo storage lockInfo = _exchangeLocks[from][i];

            if (lockInfo.unlockBlock <= block.number) {
                if (remainingAmount <= lockInfo.amount) {
                    lockInfo.amount -= remainingAmount;
                    unlockAmount += remainingAmount;
                    remainingAmount = 0;
                    index = i;
                    break;
                } else {
                    unlockAmount += lockInfo.amount;
                    remainingAmount -= lockInfo.amount;
                    lockInfo.amount = 0;
                }
            }
        }

        if (unlockAmount < amount) {
            uint256 availableBalance = balanceOf(from) - (_exchangeTotal[from] - unlockAmount);
            require(availableBalance >= amount, "Insufficient available balance");
        }

        _exchangeIndex[from] = index;
        _exchangeTotal[from] -= unlockAmount;
    }

    function setControl(address control) external onlyOwner {
        require(control != address(0), "Invalid address");
        barkcoinContorl = control;
        emit ControlChanged(control);
    }

    function setBurnRate(uint8 burnRate) external onlyOwner {
        require(burnRate <= 100, "Burn rate cannot exceed 1%");
        _burnRate = burnRate;
        emit BurnRateChanged(burnRate);
    }

    function whitelistAddress(address account, bool state) external onlyOwner {
        _whitelist[account] = state;
        emit AddressWhitelisted(account, state);
    }

    function lockAddresses(address[] calldata accounts, uint256 unlockBlock) external onlyOwner {
        require(unlockBlock > block.number, "Unlock block must be in the future");
        for (uint256 i = 0; i < accounts.length; i++) {
            _lockUntilBlock[accounts[i]] = unlockBlock;
            emit AddressLocked(accounts[i], unlockBlock);
        }
    }

    function unlockAddresses(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _lockUntilBlock[accounts[i]] = 0;
            emit AddressUnlocked(accounts[i]);
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(_lockUntilBlock[msg.sender] < block.number, "Address is locked");
        if (_exchangeTotal[msg.sender] > 0) {
            exchangeCompute(msg.sender, amount);
        }

        uint256 burnAmount = burnCompute(msg.sender, amount);
        if (burnAmount > 0) {
            _burn(msg.sender, burnAmount);
        }

        return super.transfer(recipient, amount - burnAmount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_lockUntilBlock[sender] < block.number, "Address is locked");
        if (_exchangeTotal[sender] > 0) {
            exchangeCompute(sender, amount);
        }

        uint256 burnAmount = burnCompute(sender, amount);
        if (burnAmount > 0) {
            _burn(sender, burnAmount);
        }
        return super.transferFrom(sender, recipient, amount - burnAmount);
    }

    function exchangeTransfer(address recipient, uint256 amount) public checkExchange {
        _exchangeLocks[recipient].push(LockInfo({
            amount: amount,
            unlockBlock: block.number + LOCK_DURATION
        }));
        _exchangeTotal[recipient] += amount;
        transfer(recipient, amount);
    }

    function getBurnRate() external view returns (uint8) {
        return _burnRate;
    }

    function isWhitelisted(address account) external view returns (bool) {
        return _whitelist[account];
    }

    function getLockUntilBlock(address account) external view returns (uint256) {
        return _lockUntilBlock[account];
    }

    function totalSupply() public pure override returns (uint256) {
        return TOTAL_SUPPLY;
    }

    function getExchangeLockLength(address from) external view returns (uint256) {
        return _exchangeLocks[from].length;
    }

    function getExchangeIndex(address from) external view returns (uint256) {
        return _exchangeIndex[from];
    }

    function getExchangeLock(address from, uint256 index) external view returns (LockInfo memory) {
        return _exchangeLocks[from][index];
    }

    function getExchangeBalance(address from) public view returns (uint256) {
        return _exchangeTotal[from];
    }

    function getAvailableBalance(address from) public view returns (uint256) {
        uint256 lockedAmount = 0;
        LockInfo[] memory locks = _exchangeLocks[from];
        for (uint256 i = _exchangeIndex[from]; i < locks.length; i++) {
            if (locks[i].unlockBlock <= block.number) {
                lockedAmount += locks[i].amount;
            }
        }
        return balanceOf(from) - _exchangeTotal[from] + lockedAmount;
    }
}
