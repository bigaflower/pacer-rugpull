// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// ============================================================
//  Context
// ============================================================

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// ============================================================
//  Pausable
// ============================================================

abstract contract Pausable is Context {
    event Paused(address account);
    event Unpaused(address account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    bool private _paused;
    mapping(address => bool) private _pausers;
    address[] private _pauserList;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    modifier onlyPauser() {
        require(_pausers[_msgSender()], "Pausable: caller is not the pauser");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers[account];
    }

    function _addPauser(address account) internal {
        if (!_pausers[account]) {
            _pauserList.push(account);
        }
        _pausers[account] = true;
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        if (_pausers[account]) {
            for (uint256 i = 0; i < _pauserList.length; i++) {
                if (_pauserList[i] == account) {
                    _pauserList[i] = _pauserList[_pauserList.length - 1];
                    _pauserList.pop();
                    break;
                }
            }
        }
        _pausers[account] = false;
        emit PauserRemoved(account);
    }

    function _getPausers() internal view returns (address[] memory) {
        return _pauserList;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// ============================================================
//  IERC20 / IERC20Metadata
// ============================================================

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// ============================================================
//  ERC20
// ============================================================

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// ============================================================
//  Ownable
// ============================================================

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// ============================================================
//  Lockable
// ============================================================

abstract contract Lockable is Context {
    mapping(address => bool) private _lockers;
    mapping(address => bool) private _locks;
    address[] private _lockerList;

    // --- Lock Disable ---
    mapping(address => bool) private _lockDisabled;
    bool private _lockAllDisabled;

    event LockerAdded(address indexed account);
    event LockerRemoved(address indexed account);
    event Locked(address indexed account);
    event Unlocked(address indexed account);
    event LockDisabled(address indexed account);
    event LockAllDisabled();

    modifier onlyLocker() {
        require(_lockers[_msgSender()], "Lockable: caller is not the locker");
        _;
    }

    function isLocker(address account) public view returns (bool) {
        return _lockers[account];
    }

    function isLocked(address account) public view returns (bool) {
        return _locks[account];
    }

    function isLockDisabled(address account) public view returns (bool) {
        return _lockDisabled[account];
    }

    function isLockDisabledBatch(address[] calldata accounts) public view returns (bool[] memory) {
        bool[] memory results = new bool[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            results[i] = _lockDisabled[accounts[i]];
        }
        return results;
    }

    function isLockAllDisabled() public view returns (bool) {
        return _lockAllDisabled;
    }

    function _addLocker(address account) internal {
        if (!_lockers[account]) {
            _lockerList.push(account);
        }
        _lockers[account] = true;
        emit LockerAdded(account);
    }

    function _removeLocker(address account) internal {
        if (_lockers[account]) {
            for (uint256 i = 0; i < _lockerList.length; i++) {
                if (_lockerList[i] == account) {
                    _lockerList[i] = _lockerList[_lockerList.length - 1];
                    _lockerList.pop();
                    break;
                }
            }
        }
        _lockers[account] = false;
        emit LockerRemoved(account);
    }

    function _getLockers() internal view returns (address[] memory) {
        return _lockerList;
    }

    function _lock(address account) internal {
        require(!_lockAllDisabled, "Lockable: lock is globally disabled");
        require(!_lockDisabled[account], "Lockable: lock is disabled for this account");
        _locks[account] = true;
        emit Locked(account);
    }

    function _unlock(address account) internal {
        _locks[account] = false;
        emit Unlocked(account);
    }

    function _disableLockFor(address account) internal {
        require(!_lockDisabled[account], "Lockable: already disabled for this account");
        _lockDisabled[account] = true;
        emit LockDisabled(account);
    }

    function _disableLockAll() internal {
        require(!_lockAllDisabled, "Lockable: already globally disabled");
        _lockAllDisabled = true;
        emit LockAllDisabled();
    }
}

// ============================================================
//  Mintable
// ============================================================

abstract contract Mintable is Context {
    mapping(address => bool) private _minters;
    address[] private _minterList;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    modifier onlyMinter() {
        require(_minters[_msgSender()], "Mintable: caller is not the minter");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters[account];
    }

    function _addMinter(address account) internal {
        if (!_minters[account]) {
            _minterList.push(account);
        }
        _minters[account] = true;
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        if (_minters[account]) {
            for (uint256 i = 0; i < _minterList.length; i++) {
                if (_minterList[i] == account) {
                    _minterList[i] = _minterList[_minterList.length - 1];
                    _minterList.pop();
                    break;
                }
            }
        }
        _minters[account] = false;
        emit MinterRemoved(account);
    }

    function _getMinters() internal view returns (address[] memory) {
        return _minterList;
    }
}

// ============================================================
//  PlasticHeroes (최종 컨트랙트 — V2)
// ============================================================

contract PlasticHeroes is Pausable, Ownable, Lockable, Mintable, ERC20 {

    uint8 private _tokenDecimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) {
        _tokenDecimals = decimals_;
    }

    function decimals() public view override returns (uint8) {
        return _tokenDecimals;
    }

    // ============================================================
    //  복합 modifier (Owner는 역할 부여 없이 직접 실행 가능)
    // ============================================================

    modifier onlyMinterOrOwner() {
        require(
            isMinter(_msgSender()) || _msgSender() == owner(),
            "PlasticHeroes: caller is not the minter or owner"
        );
        _;
    }

    modifier onlyLockerOrOwner() {
        require(
            isLocker(_msgSender()) || _msgSender() == owner(),
            "PlasticHeroes: caller is not the locker or owner"
        );
        _;
    }

    modifier onlyPauserOrOwner() {
        require(
            isPauser(_msgSender()) || _msgSender() == owner(),
            "PlasticHeroes: caller is not the pauser or owner"
        );
        _;
    }

    // ============================================================
    //  Role 열거 (뷰 함수)
    // ============================================================

    function getPausers() external view returns (address[] memory) {
        return _getPausers();
    }

    function getMinters() external view returns (address[] memory) {
        return _getMinters();
    }

    function getLockers() external view returns (address[] memory) {
        return _getLockers();
    }

    // ============================================================
    //  _beforeTokenTransfer (전송/민팅/소각 공통 가드)
    // ============================================================

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);

        // burn (to == address(0)) 일 때는 caller lock만 체크
        if (to == address(0)) {
            require(!isLocked(_msgSender()), "PlasticHeroes: transfer called from locked account");
            return;
        }

        // 일시정지 체크 (burn 제외)
        require(!paused(), "PlasticHeroes: token transfer while paused");

        // Lock 체크 (운영용 임시 동결 — 출금만 차단, 입금/민팅은 허용)
        require(!isLocked(from), "PlasticHeroes: transfer from locked account");
        require(!isLocked(_msgSender()), "PlasticHeroes: transfer called from locked account");
    }

    // ============================================================
    //  소유권 관리
    // ============================================================

    function transferOwnership(address newOwner) public onlyOwner whenNotPaused {
        _transferOwnership(newOwner);
    }

    // ============================================================
    //  일시정지 / 재개
    // ============================================================

    function pause() public onlyPauserOrOwner whenNotPaused {
        _pause();
    }

    function unpause() public onlyPauserOrOwner whenPaused {
        _unpause();
    }

    // ============================================================
    //  Pauser 관리
    // ============================================================

    function addPauser(address account) public onlyOwner whenNotPaused {
        _addPauser(account);
    }

    function removePauser(address account) public onlyOwner {
        _removePauser(account);
    }

    // ============================================================
    //  소각 (OZ 표준: 누구나 자기 토큰 소각 / allowance 기반 위임 소각)
    // ============================================================

    function burn(uint256 amount) external whenNotPaused {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) external whenNotPaused {
        require(!isLocked(account), "PlasticHeroes: burn from locked account");
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        _approve(account, _msgSender(), currentAllowance - amount);
        _burn(account, amount);
    }

    // ============================================================
    //  Minter 관리
    // ============================================================

    function addMinter(address account) public onlyOwner whenNotPaused {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
    }

    function mint(address recipient, uint256 amount) external onlyMinterOrOwner whenNotPaused {
        _mint(recipient, amount);
    }

    function mintBatch(address[] calldata recipients, uint256[] calldata amounts) external onlyMinterOrOwner whenNotPaused {
        require(recipients.length == amounts.length, "PlasticHeroes: recipients and amounts length mismatch");
        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], amounts[i]);
        }
    }

    // ============================================================
    //  Locker 관리
    // ============================================================

    function addLocker(address account) public onlyOwner whenNotPaused {
        _addLocker(account);
    }

    function removeLocker(address account) public onlyOwner {
        _removeLocker(account);
    }

    function lock(address account) public onlyLockerOrOwner whenNotPaused {
        require(account != address(0), "PlasticHeroes: cannot lock zero address");
        _lock(account);
    }

    function unlock(address account) public onlyLockerOrOwner whenNotPaused {
        _unlock(account);
    }

    function lockBatch(address[] calldata accounts) public onlyLockerOrOwner whenNotPaused {
        for (uint256 i = 0; i < accounts.length; i++) {
            require(accounts[i] != address(0), "PlasticHeroes: cannot lock zero address");
            _lock(accounts[i]);
        }
    }

    function unlockBatch(address[] calldata accounts) public onlyLockerOrOwner whenNotPaused {
        for (uint256 i = 0; i < accounts.length; i++) {
            _unlock(accounts[i]);
        }
    }

    // ============================================================
    //  Lock Disable (비가역적 락 비활성화)
    // ============================================================

    function disableLockFor(address account) public onlyOwner {
        _disableLockFor(account);
    }

    function disableLockForBatch(address[] calldata accounts) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _disableLockFor(accounts[i]);
        }
    }

    function disableLockAll() public onlyOwner {
        _disableLockAll();
    }
}
