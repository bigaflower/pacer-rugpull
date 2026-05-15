// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";



//  $$$$$$\                       $$\
// $$  __$$\                      $$ |
// $$ /  \__|$$\   $$\ $$$$$$$\ $$$$$$\    $$$$$$\   $$$$$$\
// \$$$$$$\  $$ |  $$ |$$  __$$\\_$$  _|  $$  __$$\ $$  __$$\
//  \____$$\ $$ |  $$ |$$ |  $$ | $$ |    $$ /  $$ |$$ |  \__|
// $$\   $$ |$$ |  $$ |$$ |  $$ | $$ |$$\ $$ |  $$ |$$ |
// \$$$$$$  |\$$$$$$$ |$$ |  $$ | \$$$$  |\$$$$$$  |$$ |
//  \______/  \____$$ |\__|  \__|  \____/  \______/ \__|
//           $$\   $$ |
//           \$$$$$$  |
//            \______/

address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
address constant UNISWAP_V3_POSITION_MANAGER = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
address constant UNISWAP_V3_FACTORY = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
address constant UNISWAP_V3_SWAP_ROUTER = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
uint24 constant FEE_TIER_10000 = 10000;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IUniswapV3PoolState {
    function liquidity() external view returns (uint128);
}

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address);
}

interface IUniswapV3Pool {
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint32 feeProtocol,
            bool unlocked
        );

    function feeGrowthGlobal0X128() external view returns (uint256);

    function feeGrowthGlobal1X128() external view returns (uint256);
}

interface IUniswapV3PoolTokens {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface ISwapRouter02 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable returns (uint256 amountOut);
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function factory() external view returns (address);

    function WETH9() external view returns (address);

    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external returns (address pool);

    function mint(
        MintParams calldata params
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);
}

interface IFactoryPoolView {
    function tokenToPool(address token) external view returns (address);
}

interface IIndexer {
    function emitERC20TokenCreated(
        address tokenAddress,
        address deployer
    ) external;

    function emitSaltBruteforced(
        bytes32 usedSalt,
        address predictedToken
    ) external;

    function emitFeesCollected(
        uint256 tokenId,
        address token,
        uint256 tokenAmount,
        uint256 ethAmount
    ) external;

    function emitTokenPurchased(
        address buyer,
        address tokenOut,
        uint256 ethSpent,
        uint256 tokensReceived
    ) external;

    function emitBuy(
        address buyer,
        address pool,
        address token,
        uint256 amountTokens,
        uint160 sqrtPriceX96,
        uint256 priceX96,
        uint256 ethAmount,
        uint256 totalFeesETH,
        uint256 totalFeesToken
    ) external;

    function emitSell(
        address seller,
        address pool,
        address token,
        uint256 amountTokens,
        uint160 sqrtPriceX96,
        uint256 priceX96,
        uint256 ethAmount,
        uint256 totalFeesETH,
        uint256 totalFeesToken
    ) external;

    function authorizeAddress(address _contract) external;
}

error NotController();
error DeploymentDisabled();
error InvalidConfigId();
error SaltSearchFailed();
error TokenMustBeToken0();
error MustBeWETH();
error NoWETHToWithdraw();
error NoETHToWithdraw();
error BatchRange();
error ItemsPerPageRange();
error PenaltyMultiplierRange();
error NoTokensDeployed();
error PageOutOfRange();
error InternalOnly();
error NoPosition();
error NotAuthorized();

contract AgentToken is ERC20, ERC20Burnable {
    using Math for uint256;

    address public platform;
    IIndexer public indexer;
    uint256 private launchBlock;
    uint256 private maxTxAmount;
    uint256 private constant LAUNCH_PERIOD = 5;
    uint256 private constant MAX_WALLET_PERCENTAGE = 2;

    address public constant POSITION_MANAGER = UNISWAP_V3_POSITION_MANAGER;
    address public constant WETH = WETH_ADDRESS;

    mapping(address => uint256) private tokensFromPoolPerOrigin;

    constructor(
        string memory _name,
        string memory _symbol,
        address _platform,
        address _indexer
    ) ERC20(_name, _symbol) {
        platform = _platform;
        indexer = IIndexer(_indexer);
        launchBlock = block.number;

        uint256 totalTokens = 1_000_000 * 10 ** decimals();
        maxTxAmount = (totalTokens * MAX_WALLET_PERCENTAGE) / 100;

        _mint(_platform, totalTokens);
    }

    function owner() public pure returns (address) {
        return address(0);
    }

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override {
        if (
            block.number > launchBlock &&
            block.number <= launchBlock + LAUNCH_PERIOD
        ) {
            address factory = INonfungiblePositionManager(POSITION_MANAGER)
                .factory();
            address pool = IUniswapV3Factory(factory).getPool(
                address(this),
                WETH,
                FEE_TIER_10000
            );

            if (from == pool && to != platform) {
                tokensFromPoolPerOrigin[tx.origin] += value;
                require(
                    tokensFromPoolPerOrigin[tx.origin] <=
                        (maxTxAmount * 110) / 100,
                    "Keeping 2% pool Limits In Kontrol"
                );
            }

            if (to != platform && to != pool && from != address(0)) {
                require(
                    balanceOf(to) + value <= maxTxAmount,
                    "Max wallet limit exceeded during launch period"
                );
            }
        }

        if (
            block.number == launchBlock &&
            from != address(0) &&
            to != platform &&
            from != platform
        ) {
            revert("No buys allowed during launch block!");
        }

        super._update(from, to, value);

        address factoryPool = IFactoryPoolView(platform).tokenToPool(
            address(this)
        );
        if (
            factoryPool != address(0) &&
            (from == factoryPool || to == factoryPool)
        ) {
            (uint160 sqrtPriceX96, , , , , , ) = IUniswapV3Pool(factoryPool)
                .slot0();
            uint256 priceX96 = Math.mulDiv(
                uint256(sqrtPriceX96),
                uint256(sqrtPriceX96),
                1 << 96
            );

            uint256 feeGrowthETH = IUniswapV3Pool(factoryPool)
                .feeGrowthGlobal1X128();
            uint256 feeGrowthToken = IUniswapV3Pool(factoryPool)
                .feeGrowthGlobal0X128();

             bool tokenIsToken0 = address(this) < WETH;
        uint256 ethAmount;
        
        if (tokenIsToken0) {
            uint256 priceX192 = Math.mulDiv(uint256(sqrtPriceX96), uint256(sqrtPriceX96), 1);
            ethAmount = Math.mulDiv(value, priceX192, 1 << 192);
        } else {
            uint256 priceX192 = Math.mulDiv(uint256(sqrtPriceX96), uint256(sqrtPriceX96), 1);
            ethAmount = Math.mulDiv(value, 1 << 192, priceX192);
        }


            if (from == factoryPool && to != address(0)) {
                try
                    indexer.emitBuy(
                        to,
                        factoryPool,
                        address(this),
                        value,
                        sqrtPriceX96,
                        priceX96,
                        ethAmount,
                        feeGrowthETH,
                        feeGrowthToken
                    )
                {} catch {}
            } else if (to == factoryPool && from != address(0)) {
                try
                    indexer.emitSell(
                        from,
                        factoryPool,
                        address(this),
                        value,
                        sqrtPriceX96,
                        priceX96,
                        ethAmount,
                        feeGrowthETH,
                        feeGrowthToken
                    )
                {} catch {}
            }
        }
    }

    function getTokenPair() public view returns (address, address, address) {
        address find_factory = INonfungiblePositionManager(POSITION_MANAGER)
            .factory();
        address find_pool = IUniswapV3Factory(find_factory).getPool(
            address(this),
            WETH,
            FEE_TIER_10000
        );
        return (find_pool, address(this), find_factory);
    }

    function isLaunchPeriodActive() public view returns (bool) {
        return block.number <= launchBlock + LAUNCH_PERIOD;
    }
}


