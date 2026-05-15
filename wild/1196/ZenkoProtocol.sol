// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/* ========================== IMPORTS ========================== */
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

/* ========================== INTERFACES ========================== */

interface IZEN is IERC20 {
    function burnFrom(address account, uint256 amount) external;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address);
}

interface IUniswapV2Router {
    function factory() external view returns (address);
    function WETH() external view returns (address);
}

/* ========================== ZENKO PROTOCOL ========================== */

contract ZenkoProtocol is ERC20, Ownable2Step {
    using SafeERC20 for IERC20;

    address public router;
    address public factory;
    address public immutable WETH;
    address public ZEN;

    address public constant DEAD_ADDRESS =
        0x000000000000000000000000000000000000dEaD;

    mapping(address => bool) public isPair;
    mapping(address => bool) public transferWhitelist;
    mapping(address => bool) public liquidityWhitelist;
    mapping(address => bool) public factoryAllowed;
    mapping(address => bool) private factoryListed;
    address[] public factories;

    bool public transferOpen;
    bool public buyOpen;

    uint256 public zenBurnRate = 20;

    uint256 public constant MAX_FACTORIES = 10;

    /* ========================== EVENTS ========================== */

    event BurnRateUpdated(uint256 rate);
    event PairUpdated(address indexed pair, bool enabled);
    event PairCreated(address indexed factory, address indexed pair, address indexed tokenB);
    event FactoryAllowedUpdated(address indexed factory, bool enabled);

    event ZenBurned(address indexed user, uint256 zenAmount);
    event ZenBurnTriggered(
        address indexed seller,
        address indexed pair,
        uint256 zenkoAmount,
        uint256 zenAmount
    );

    event TransferWhitelistUpdated(address indexed account, bool enabled);
    event LiquidityWhitelistUpdated(address indexed account, bool enabled);
    event TransferOpenUpdated(bool enabled);
    event BuyOpenUpdated(bool enabled);

    event RouterSet(address indexed newRouter);
    event RouterPermissionsRemoved(address indexed oldRouter);
    event ZENSet(address indexed newZEN);

    /* ========================== CONSTRUCTOR ========================== */

    constructor(address _router, address _zen)
        ERC20("Zenko Protocol", "ZENKO")
        Ownable(msg.sender)
    {
        require(_router.code.length > 0, "router not contract");
        require(_zen != address(0), "zero ZEN");

        IUniswapV2Router r = IUniswapV2Router(_router);

        address weth = r.WETH();
        address factory_ = r.factory();

        require(weth.code.length > 0, "invalid WETH");
        require(factory_.code.length > 0, "invalid factory");

        router = _router;
        factory = factory_;
        WETH = weth;
        ZEN = _zen;

        factoryAllowed[factory_] = true;
        factoryListed[factory_] = true;
        factories.push(factory_);

        transferWhitelist[_router] = true;
        liquidityWhitelist[_router] = true;

        _mint(msg.sender, 1_000_000_000 ether);
    }

    /* ========================== ADMIN ========================== */

    function setRouter(address _router) external onlyOwner {
        require(_router.code.length > 0, "router not contract");
        require(_router != router, "same router");

        IUniswapV2Router r = IUniswapV2Router(_router);

        require(r.WETH() == WETH, "WETH mismatch");

        address newFactory = r.factory();
        require(newFactory.code.length > 0, "invalid factory");

        // remove old router permissions
        if (router != address(0)) {
            transferWhitelist[router] = false;
            liquidityWhitelist[router] = false;
            emit RouterPermissionsRemoved(router);
        }

        router = _router;
        factory = newFactory;

        // Allow factory
        if (!factoryListed[newFactory]) {
            require(factories.length < MAX_FACTORIES, "factory limit reached");
            factoryListed[newFactory] = true;
            factories.push(newFactory);
        }
        factoryAllowed[newFactory] = true;

        // Create or fetch ZENKO/WETH pair
        address pair = IUniswapV2Factory(newFactory).getPair(address(this), WETH);
        if (pair == address(0)) {
            pair = IUniswapV2Factory(newFactory).createPair(address(this), WETH);
            emit PairCreated(newFactory, pair, WETH);
        }

        isPair[pair] = true;
        emit PairUpdated(pair, true);

        // Whitelist router
        transferWhitelist[_router] = true;
        liquidityWhitelist[_router] = true;

        emit RouterSet(_router);
    }

    function setZEN(address _zen) external onlyOwner {
        require(_zen != address(0), "zero address");
        ZEN = _zen;
        emit ZENSet(_zen);
    }

    function setZenBurnRate(uint256 rate) external onlyOwner {
        require(rate <= 20, "max 20%");
        zenBurnRate = rate;
        emit BurnRateUpdated(rate);
    }

    function setTransferWhitelist(address account, bool enabled) external onlyOwner {
        transferWhitelist[account] = enabled;
        emit TransferWhitelistUpdated(account, enabled);
    }

    function setLiquidityWhitelist(address account, bool enabled) external onlyOwner {
        liquidityWhitelist[account] = enabled;
        emit LiquidityWhitelistUpdated(account, enabled);
    }

    function setTransferOpen(bool enabled) external onlyOwner {
        require(!transferOpen, "already enabled");
        require(enabled, "cannot disable");
        transferOpen = true;
        emit TransferOpenUpdated(true);
    }

    function setBuyOpen(bool enabled) external onlyOwner {
        require(!buyOpen, "already enabled");
        require(enabled, "cannot disable");
        buyOpen = true;
        emit BuyOpenUpdated(true);
    }

    function setFactoryAllowed(address factory_, bool enabled) external onlyOwner {
        require(factory_ != address(0), "zero address");

        if (enabled && !factoryListed[factory_]) {
            require(factories.length < MAX_FACTORIES, "factory limit reached");
            factoryListed[factory_] = true;
            factories.push(factory_);
        }

        factoryAllowed[factory_] = enabled;
        emit FactoryAllowedUpdated(factory_, enabled);
    }

    function removeFactory(address factory_) external onlyOwner {
        require(factoryListed[factory_], "not listed");

        uint256 len = factories.length;
        for (uint256 i = 0; i < len; ++i) {
            if (factories[i] == factory_) {
                factories[i] = factories[len - 1];
                factories.pop();
                break;
            }
        }

        factoryAllowed[factory_] = false;
        factoryListed[factory_] = false;

        emit FactoryAllowedUpdated(factory_, false);
    }

    function setPair(address pair, bool enabled) external onlyOwner {
        require(pair != address(0), "zero address");
        isPair[pair] = enabled;
        emit PairUpdated(pair, enabled);
    }

    /* ========================== INTERNAL HELPERS ========================== */

    function _isContract(address a) internal view returns (bool) {
        return a.code.length > 0;
    }

    function _maybeMarkPair(address pair) internal {
        if (isPair[pair] || !_isContract(pair)) return;

        try IUniswapV2Pair(pair).token0() returns (address t0) {
            try IUniswapV2Pair(pair).token1() returns (address t1) {
                if (t0 == address(this) || t1 == address(this)) {
                    uint256 len = factories.length;
                    for (uint256 i; i < len; ) {
                        address f = factories[i];
                        if (factoryAllowed[f]) {
                            if (IUniswapV2Factory(f).getPair(t0, t1) == pair) {
                                isPair[pair] = true;
                                emit PairUpdated(pair, true);
                                break;
                            }
                        }
                        unchecked { ++i; }
                    }
                }
            } catch {}
        } catch {}
    }

    function _burnZen(address user, uint256 zenkoAmount) internal {
        uint256 zenAmount = (zenkoAmount * zenBurnRate) / 100;
        if (zenAmount == 0) return;

        uint256 allowance = IERC20(ZEN).allowance(user, address(this));
        require(allowance >= zenAmount, "ZEN allowance too low");

        bool burned = false;

        if (_isContract(ZEN)) {
            (bool ok, bytes memory data) = ZEN.call(
                abi.encodeWithSelector(IZEN.burnFrom.selector, user, zenAmount)
            );
            if (ok) {
                burned = data.length == 0 || abi.decode(data, (bool));
            }
        }

        if (!burned) {
            IERC20(ZEN).safeTransferFrom(user, DEAD_ADDRESS, zenAmount);
        }

        emit ZenBurned(user, zenAmount);
        emit ZenBurnTriggered(user, msg.sender, zenkoAmount, zenAmount);
    }

    /* ========================== ERC20 HOOK ========================== */

    function _update(address from, address to, uint256 amount) internal override {
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        _maybeMarkPair(from);
        _maybeMarkPair(to);

        if (!transferOpen) {
            if (
                from != owner() &&
                !transferWhitelist[from] &&
                !transferWhitelist[to]
            ) revert("transfers closed");
        }

        if (!buyOpen && isPair[from]) {
            revert("buys closed");
        }

        super._update(from, to, amount);

        if (isPair[to] && from != router && !liquidityWhitelist[from]) {
            _burnZen(from, amount);
        }
    }

    /* ========================== UTIL ========================== */

    function burn(uint256 amount) external returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

    function syncPair(address tokenB) external onlyOwner returns (address pair) {
        return _syncPair(factory, tokenB);
    }

    function syncPair(address factory_, address tokenB) external onlyOwner returns (address pair) {
        return _syncPair(factory_, tokenB);
    }

    function _syncPair(address factory_, address tokenB) internal returns (address pair) {
        require(factoryAllowed[factory_], "factory not allowed");
        pair = IUniswapV2Factory(factory_).getPair(address(this), tokenB);
        require(pair != address(0), "pair not found");

        if (!isPair[pair]) {
            isPair[pair] = true;
            emit PairUpdated(pair, true);
        }
    }
}
