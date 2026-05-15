// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title USDCRewardVault
 * @notice Custodial reward vault for USDC payouts.
 * Amounts are in USDC smallest unit (6 decimals).
 *
 * Flow:
 * 1) Owner deposits USDC into this contract.
 * 2) Operator credits claimable balances for users.
 * 3) Users claim their own USDC on-chain.
 */
contract USDCRewardVault {
  IERC20 public immutable usdc;
  address public owner;
  bool public paused;

  mapping(address => bool) public operators;
  mapping(address => uint256) public claimable;
  mapping(bytes32 => bool) public processedCreditIds;
  uint256 public totalOutstanding;

  uint256 private _locked = 1;

  event OwnerUpdated(address indexed previousOwner, address indexed newOwner);
  event OperatorUpdated(address indexed operator, bool enabled);
  event Paused(bool paused);
  event Deposited(address indexed from, uint256 amount);
  event Credited(address indexed account, uint256 amount, uint256 newClaimable);
  event CreditIdProcessed(bytes32 indexed creditId, address indexed account, uint256 amount);
  event Claimed(address indexed account, uint256 amount);
  event SurplusWithdrawn(address indexed to, uint256 amount);

  modifier onlyOwner() {
    require(msg.sender == owner, "not owner");
    _;
  }

  modifier onlyOperator() {
    require(operators[msg.sender], "not operator");
    _;
  }

  modifier whenNotPaused() {
    require(!paused, "paused");
    _;
  }

  modifier nonReentrant() {
    require(_locked == 1, "reentrancy");
    _locked = 2;
    _;
    _locked = 1;
  }

  constructor(address usdcToken, address initialOwner) {
    require(usdcToken != address(0), "usdc=0");
    require(initialOwner != address(0), "owner=0");
    usdc = IERC20(usdcToken);
    owner = initialOwner;
    emit OwnerUpdated(address(0), initialOwner);
  }

  function setOwner(address newOwner) external onlyOwner {
    require(newOwner != address(0), "owner=0");
    address prev = owner;
    owner = newOwner;
    emit OwnerUpdated(prev, newOwner);
  }

  function setOperator(address operator, bool enabled) external onlyOwner {
    require(operator != address(0), "operator=0");
    operators[operator] = enabled;
    emit OperatorUpdated(operator, enabled);
  }

  function setPaused(bool value) external onlyOwner {
    paused = value;
    emit Paused(value);
  }

  function deposit(uint256 amount) external onlyOwner nonReentrant {
    require(amount > 0, "amount=0");
    bool ok = usdc.transferFrom(msg.sender, address(this), amount);
    require(ok, "transferFrom failed");
    emit Deposited(msg.sender, amount);
  }

  function credit(address account, uint256 amount) external onlyOperator whenNotPaused {
    _credit(account, amount);
  }

  function creditBatch(address[] calldata accounts, uint256[] calldata amounts) external onlyOperator whenNotPaused {
    uint256 len = accounts.length;
    require(len == amounts.length, "length mismatch");
    require(len > 0, "empty");

    uint256 totalToCredit = 0;
    for (uint256 i = 0; i < len; i++) {
      require(accounts[i] != address(0), "account=0");
      require(amounts[i] > 0, "amount=0");
      totalToCredit += amounts[i];
    }
    require(_surplus() >= totalToCredit, "insufficient surplus");

    for (uint256 i = 0; i < len; i++) {
      _credit(accounts[i], amounts[i]);
    }
  }

  /**
   * @notice Idempotent credit with a unique creditId from backend.
   * Reusing the same creditId will revert, preventing double-credit on retries.
   */
  function creditWithId(address account, uint256 amount, bytes32 creditId) external onlyOperator whenNotPaused {
    require(creditId != bytes32(0), "creditId=0");
    require(!processedCreditIds[creditId], "credit already processed");
    processedCreditIds[creditId] = true;
    _credit(account, amount);
    emit CreditIdProcessed(creditId, account, amount);
  }

  function creditBatchWithIds(
    address[] calldata accounts,
    uint256[] calldata amounts,
    bytes32[] calldata creditIds
  ) external onlyOperator whenNotPaused {
    uint256 len = accounts.length;
    require(len == amounts.length && len == creditIds.length, "length mismatch");
    require(len > 0, "empty");

    uint256 totalToCredit = 0;
    for (uint256 i = 0; i < len; i++) {
      require(accounts[i] != address(0), "account=0");
      require(amounts[i] > 0, "amount=0");
      require(creditIds[i] != bytes32(0), "creditId=0");
      require(!processedCreditIds[creditIds[i]], "credit already processed");
      // Mark immediately so duplicate IDs within the same batch are rejected.
      processedCreditIds[creditIds[i]] = true;
      totalToCredit += amounts[i];
    }
    require(_surplus() >= totalToCredit, "insufficient surplus");

    for (uint256 i = 0; i < len; i++) {
      _credit(accounts[i], amounts[i]);
      emit CreditIdProcessed(creditIds[i], accounts[i], amounts[i]);
    }
  }

  function claim() external nonReentrant whenNotPaused {
    uint256 amount = claimable[msg.sender];
    require(amount > 0, "nothing to claim");

    claimable[msg.sender] = 0;
    totalOutstanding -= amount;

    bool ok = usdc.transfer(msg.sender, amount);
    require(ok, "transfer failed");
    emit Claimed(msg.sender, amount);
  }

  function withdrawSurplus(address to, uint256 amount) external onlyOwner nonReentrant {
    require(to != address(0), "to=0");
    require(amount > 0, "amount=0");
    require(_surplus() >= amount, "insufficient surplus");
    bool ok = usdc.transfer(to, amount);
    require(ok, "transfer failed");
    emit SurplusWithdrawn(to, amount);
  }

  function contractBalance() external view returns (uint256) {
    return usdc.balanceOf(address(this));
  }

  function surplus() external view returns (uint256) {
    return _surplus();
  }

  function _surplus() internal view returns (uint256) {
    uint256 bal = usdc.balanceOf(address(this));
    if (bal <= totalOutstanding) return 0;
    return bal - totalOutstanding;
  }

  function _credit(address account, uint256 amount) internal {
    require(account != address(0), "account=0");
    require(amount > 0, "amount=0");
    require(_surplus() >= amount, "insufficient surplus");

    claimable[account] += amount;
    totalOutstanding += amount;
    emit Credited(account, amount, claimable[account]);
  }
}
