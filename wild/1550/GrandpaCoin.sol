// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract GrandpaCoin is IERC20 {
    string public constant name = "Grandpa Coin";
    string public constant symbol = "GRANDPA";
    uint8  public constant decimals = 18;

    uint256 public constant BUY_TAX_BPS = 600; // 6%
    uint256 internal constant BPS = 10_000;

    uint256 private _totalSupply;
    address public immutable strategyVault;
    address public owner;

    bool public taxEnabled = true;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    mapping(address => bool) public isPool;

    /// Routers, LP managers, etc
    mapping(address => bool) public isLPExempt;

    event OwnershipTransferred(address indexed from, address indexed to);
    event PoolSet(address indexed pool, bool enabled);
    event LPExemptSet(address indexed addr, bool enabled);
    event TaxToggled(bool enabled);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(address _strategyVault) {
        require(_strategyVault != address(0), "VAULT_0");

        owner = msg.sender;
        strategyVault = _strategyVault;

        _totalSupply = 100_000_000 * 1e18;
        balances[msg.sender] = _totalSupply;

        emit Transfer(address(0), msg.sender, _totalSupply);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /*//////////////////////////////////////////////////////////////
                                ADMIN
    //////////////////////////////////////////////////////////////*/

    function setPool(address pool, bool enabled) external onlyOwner {
        isPool[pool] = enabled;
        emit PoolSet(pool, enabled);
    }

    function setLPExempt(address addr, bool enabled) external onlyOwner {
        isLPExempt[addr] = enabled;
        emit LPExemptSet(addr, enabled);
    }

    function setTaxEnabled(bool enabled) external onlyOwner {
        taxEnabled = enabled;
        emit TaxToggled(enabled);
    }

    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    /*//////////////////////////////////////////////////////////////
                                ERC20
    //////////////////////////////////////////////////////////////*/

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address a) external view override returns (uint256) {
        return balances[a];
    }

    function allowance(address o, address s) external view override returns (uint256) {
        return allowances[o][s];
    }

    function approve(address s, uint256 a) external override returns (bool) {
        allowances[msg.sender][s] = a;
        emit Approval(msg.sender, s, a);
        return true;
    }

    function transfer(address to, uint256 amt) external override returns (bool) {
        _transfer(msg.sender, to, amt);
        return true;
    }

    function transferFrom(address from, address to, uint256 amt) external override returns (bool) {
        uint256 allowed = allowances[from][msg.sender];
        require(allowed >= amt, "ALLOWANCE");
        allowances[from][msg.sender] = allowed - amt;
        _transfer(from, to, amt);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                            BUY-ONLY TAX
    //////////////////////////////////////////////////////////////*/

    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "BALANCE");

        balances[from] -= amount;

        uint256 tax = 0;

        bool fromPool = isPool[from];
        bool toPool   = isPool[to];
        bool exempt   = isLPExempt[from] || isLPExempt[to];

        if (
            taxEnabled &&
            !exempt &&
            fromPool &&       // pool → user
            !toPool
        ) {
            tax = amount * BUY_TAX_BPS / BPS;
            balances[strategyVault] += tax;
            emit Transfer(from, strategyVault, tax);
        }

        uint256 received = amount - tax;
        balances[to] += received;
        emit Transfer(from, to, received);
    }
}
