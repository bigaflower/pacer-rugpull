/*
    MiladyStrategy - NFT Flywheel Token

    X: https://x.com/miladystrg
    Website: https://miladystrg.com

    Accumulates trading fees to buy Miladys, relists at markup,
    uses sale proceeds to buy back and burn tokens.
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable}         from "solady/src/auth/Ownable.sol";
import {ERC20}           from "solady/src/tokens/ERC20.sol";
import {ReentrancyGuard} from "solady/src/utils/ReentrancyGuard.sol";
import {SafeTransferLib} from "solady/src/utils/SafeTransferLib.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {Actions}          from "@uniswap/v4-periphery/src/libraries/Actions.sol";
import {IAllowanceTransfer} from "permit2/src/interfaces/IAllowanceTransfer.sol";
import {IHooks}     from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Currency}   from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey}    from "@uniswap/v4-core/src/types/PoolKey.sol";
import {TickMath}   from "@uniswap/v4-core/src/libraries/TickMath.sol";

interface IUniswapV4Router {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        bool zeroForOne,
        PoolKey calldata poolKey,
        bytes calldata hookData,
        address recipient,
        uint256 deadline
    ) external payable returns (uint256 amountOut);
}
/// @notice Minimal ERC721 interface
interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}



/// @title MiladyStrategy - NFT Flywheel Token with V4 Hooks
/// @notice Uses Uniswap v4 trading fees to buy Miladys, relist at markup, buyback & burn
contract MiladyStrategy is ERC20, Ownable, ReentrancyGuard {
    using SafeTransferLib for address;

    // Constants
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18; // 1 billion tokens
    uint256 public constant BASIS_POINTS = 1000; // For priceMultiplier (1200 = 1.2x)

    // Immutable addresses
    address public immutable posm;
    address public immutable permit2;
    address public immutable poolManager;
    address payable public immutable router;
    IERC721 public immutable collection; // Milady NFT

    // State variables
    address public hookAddress;
    uint256 public currentFees;           // Accumulated fees for NFT purchases
    uint256 public ethToTwap;             // ETH from NFT sales, for buyback & burn
    uint256 public priceMultiplier = 1200; // 1.2x relist price
    uint256 public lastBuyBlock;          // Last block an NFT was bought
    uint256 public buyIncrement = 0.1 ether; // Max price increase per block
    uint256 public transferAllowance;     // For hook transfer management
    uint256 public totalBurned;

    // TWAP buyback settings
    uint256 public twapIncrement = 0.1 ether;  // Amount of ETH per TWAP execution
    uint256 public twapDelayInBlocks = 1;      // Blocks between TWAP executions
    uint256 public lastTwapBlock;              // Last block TWAP was executed

    bool public loadingLiquidity;
    bool public midSwap;

    // NFT listings: tokenId => sale price (0 = not for sale)
    mapping(uint256 => uint256) public nftForSale;

    // NFT tracking
    uint256[] public ownedNFTs;
    mapping(uint256 => uint256) private ownedNFTsIndex; // tokenId => index in ownedNFTs

    // Sold NFT history
    struct SoldNFT {
        uint256 tokenId;
        uint256 price;
    }
    SoldNFT[] public soldNFTs;

    // Events
    event FeesDeposited(uint256 amount);
    event NFTBoughtByProtocol(uint256 indexed tokenId, uint256 purchasePrice, uint256 listPrice);
    event NFTSoldByProtocol(uint256 indexed tokenId, uint256 price, address buyer);
    event TokensBurned(uint256 amount);

    // Errors
    error OnlyHook();
    error WrongEthAmount();
    error NotEnoughEth();
    error PriceTooHigh();
    error NFTNotForSale();
    error NFTPriceTooLow();
    error NeedToBuyNFT();
    error AlreadyNFTOwner();
    error NotNFTOwner();
    error InvalidTarget();
    error ExternalCallFailed(bytes reason);
    error NoETHToTwap();
    error TwapDelayNotMet();

    constructor(
        address _owner,
        address _posm,
        address _permit2,
        address _poolManager,
        address payable _router,
        address _collection
    ) {
        posm = _posm;
        permit2 = _permit2;
        poolManager = _poolManager;
        router = _router;
        collection = IERC721(_collection);

        _initializeOwner(_owner);
        _mint(address(this), MAX_SUPPLY);
    }

    /// @notice Allows the hook (or the Owner) to deposit trading fees into the contract
    /// @dev Only callable by the hook contract or owner
    /// @dev All fees go to the NFT purchase fund
    function addFees() external payable {
        if (msg.sender != hookAddress && msg.sender != owner()) revert OnlyHook();

        uint256 amount = msg.value;
        currentFees += amount;

        emit FeesDeposited(amount);
    }

    /// @notice Loads initial liquidity into the pool
    /// @param _hook Address of the TaxHook contract
    /// @dev Must send exactly 2 wei. Can only be called once by owner.
    function loadLiquidity(address _hook) external payable onlyOwner {
        if (msg.value != 2 wei) revert WrongEthAmount();
        hookAddress = _hook;
        _loadLiquidity(_hook);
    }

    /// @notice Sets midSwap state - only callable by hook during swaps
    function setMidSwap(bool value) external {
        if (msg.sender != hookAddress) revert OnlyHook();
        midSwap = value;
    }

    /// @notice Hook sets transfer allowance for token movements
    function increaseTransferAllowance(uint256 amount) external {
        if (msg.sender != hookAddress) revert OnlyHook();
        transferAllowance += amount;
    }

    /// @notice Returns the name of the token
    function name() public pure override returns (string memory) {
        return "MiladyStrategy";
    }

    /// @notice Returns the symbol of the token
    function symbol() public pure override returns (string memory) {
        return "MLDSTR";
    }

    // ============ NFT STRATEGY FUNCTIONS ============

    /// @notice Buy an NFT from any marketplace using accumulated fees
    /// @param value Amount of ETH to spend
    /// @param data Calldata for the marketplace (e.g., OpenSea Seaport fulfillOrder)
    /// @param expectedId The NFT token ID we expect to receive
    /// @param target The marketplace contract address (e.g., Seaport)
    function buyTargetNFT(
        uint256 value,
        bytes calldata data,
        uint256 expectedId,
        address target
    ) external nonReentrant {
        uint256 ethBalanceBefore = address(this).balance;
        uint256 nftBalanceBefore = collection.balanceOf(address(this));

        // Validate we don't already own it
        if (collection.ownerOf(expectedId) == address(this)) {
            revert AlreadyNFTOwner();
        }

        // Validate we have enough fees
        if (value > currentFees) {
            revert NotEnoughEth();
        }

        // Validate price doesn't exceed time-based max
        if (value > getMaxPriceForBuy()) {
            revert PriceTooHigh();
        }

        // Can't call the collection directly or self
        if (target == address(collection) || target == address(this)) revert InvalidTarget();

        // Execute marketplace call (works with OpenSea, Blur, etc.)
        (bool success, bytes memory reason) = target.call{value: value}(data);
        if (!success) {
            revert ExternalCallFailed(reason);
        }

        // Verify we received exactly one NFT
        uint256 nftBalanceAfter = collection.balanceOf(address(this));
        if (nftBalanceAfter != nftBalanceBefore + 1) {
            revert NeedToBuyNFT();
        }

        // Verify we own the expected NFT
        if (collection.ownerOf(expectedId) != address(this)) {
            revert NotNFTOwner();
        }

        // Calculate actual cost
        uint256 cost = ethBalanceBefore - address(this).balance;
        currentFees -= cost;

        // List at priceMultiplier (e.g., 1.2x)
        uint256 salePrice = (cost * priceMultiplier) / BASIS_POINTS;
        nftForSale[expectedId] = salePrice;

        // Track owned NFT
        ownedNFTsIndex[expectedId] = ownedNFTs.length;
        ownedNFTs.push(expectedId);

        // Reset max price calculation
        lastBuyBlock = block.number;

        emit NFTBoughtByProtocol(expectedId, cost, salePrice);
    }

    /// @notice Buy an NFT from this contract at the listed price
    /// @param tokenId The NFT to purchase
    /// @dev Anyone can call - pays ETH, receives NFT. Proceeds go to buyback pool.
    function sellTargetNFT(uint256 tokenId) external payable nonReentrant {
        uint256 salePrice = nftForSale[tokenId];

        if (salePrice == 0) revert NFTNotForSale();
        if (msg.value != salePrice) revert NFTPriceTooLow();
        if (collection.ownerOf(tokenId) != address(this)) revert NotNFTOwner();

        // Transfer NFT to buyer
        collection.transferFrom(address(this), msg.sender, tokenId);

        // Remove listing
        delete nftForSale[tokenId];

        // Remove from ownedNFTs array
        _removeFromOwnedNFTs(tokenId);

        // Add to sold history
        soldNFTs.push(SoldNFT(tokenId, salePrice));

        // Add proceeds to TWAP buyback pool
        ethToTwap += salePrice;

        emit NFTSoldByProtocol(tokenId, salePrice, msg.sender);
    }

    /// @notice Get maximum price allowed for NFT purchase (increases over time)
    function getMaxPriceForBuy() public view returns (uint256) {
        uint256 blocksPassed = block.number - lastBuyBlock;
        return blocksPassed * buyIncrement;
    }

    // ============ BUYBACK & BURN FUNCTIONS ============

    /// @notice Execute TWAP buyback - buys tokens with ETH from NFT sales and burns them
    /// @dev Anyone can call. Rate limited by twapDelayInBlocks.
    function processTokenTwap() external nonReentrant {
        if (ethToTwap == 0) revert NoETHToTwap();
        if (block.number < lastTwapBlock + twapDelayInBlocks) revert TwapDelayNotMet();

        uint256 amountToSwap = ethToTwap > twapIncrement ? twapIncrement : ethToTwap;
        ethToTwap -= amountToSwap;
        lastTwapBlock = block.number;

        _buyAndBurnTokens(amountToSwap);
    }

    /// @notice Internal function to buy tokens with ETH and send to dead address
    /// @param amountIn Amount of ETH to spend
    function _buyAndBurnTokens(uint256 amountIn) internal {
        // Build pool key for ETH/TAX pool
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)), // ETH
            currency1: Currency.wrap(address(this)), // TAX
            fee: 0,
            tickSpacing: 200,
            hooks: IHooks(hookAddress)
        });

        // Swap ETH for TAX and send directly to dead address
        IUniswapV4Router(router).swapExactTokensForTokens{value: amountIn}(
            amountIn,
            0,
            true, // zeroForOne: ETH -> TAX
            key,
            "",
            address(0x000000000000000000000000000000000000dEaD),
            block.timestamp
        );
    }

    // ============ ADMIN FUNCTIONS ============

    /// @notice Set price multiplier for NFT relisting (1200 = 1.2x)
    function setPriceMultiplier(uint256 _multiplier) external onlyOwner {
        require(_multiplier >= 1100 && _multiplier <= 5000, "Invalid multiplier");
        priceMultiplier = _multiplier;
    }

    /// @notice Set buy increment per block
    function setBuyIncrement(uint256 _increment) external onlyOwner {
        buyIncrement = _increment;
    }

    /// @notice Set TWAP increment (ETH per execution)
    function setTwapIncrement(uint256 _increment) external onlyOwner {
        twapIncrement = _increment;
    }

    /// @notice Set TWAP delay in blocks
    function setTwapDelay(uint256 _blocks) external onlyOwner {
        twapDelayInBlocks = _blocks;
    }

    /// @notice Emergency withdraw stuck ETH
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        SafeTransferLib.safeTransferETH(owner(), amount);
    }

    ///
    function manualRepriceNFT(uint256 tokenId) external onlyOwner {
        delete nftForSale[tokenId];
    }

    /// @notice Allows owner to deposit an NFT and list it for sale
    function depositNFTForSale(uint256 tokenId, uint256 price) external onlyOwner {
        // Transfer NFT from owner to contract
        collection.transferFrom(msg.sender, address(this), tokenId);

        // List it
        nftForSale[tokenId] = price;

        // Track it
        ownedNFTsIndex[tokenId] = ownedNFTs.length;
        ownedNFTs.push(tokenId);

        emit NFTBoughtByProtocol(tokenId, 0, price); // Event used for indexing listings
    }

    /// @notice
    function processNFTTransfer(uint256 tokenId) external onlyOwner {
        delete nftForSale[tokenId];
        _removeFromOwnedNFTs(tokenId);
        collection.transferFrom(address(this), owner(), tokenId);
    }

    // ============ NFT TRACKING FUNCTIONS ============

    /// @notice Returns all currently held NFT token IDs
    function currentlyHoldingNFTs() external view returns (uint256[] memory) {
        return ownedNFTs;
    }

    /// @notice Returns all previously sold NFTs with tokenId and price
    function previouslySoldNFTs() external view returns (SoldNFT[] memory) {
        return soldNFTs;
    }

    /// @notice Internal function to remove an NFT from the ownedNFTs array
    function _removeFromOwnedNFTs(uint256 tokenId) internal {
        uint256 lastIndex = ownedNFTs.length - 1;
        uint256 tokenIndex = ownedNFTsIndex[tokenId];

        if (tokenIndex != lastIndex) {
            uint256 lastTokenId = ownedNFTs[lastIndex];
            ownedNFTs[tokenIndex] = lastTokenId;
            ownedNFTsIndex[lastTokenId] = tokenIndex;
        }

        ownedNFTs.pop();
        delete ownedNFTsIndex[tokenId];
    }

    // ============ ERC721 RECEIVER ============

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @notice Internal function to load liquidity into the Uniswap V4 pool
    /// @param _hook Address of the TaxHook
    function _loadLiquidity(address _hook) internal {
        loadingLiquidity = true;
        
        // Create the pool with ETH (currency0) and TAX (currency1)
        Currency currency0 = Currency.wrap(address(0)); // ETH
        Currency currency1 = Currency.wrap(address(this)); // TAX
        
        uint24 lpFee = 0;
        int24 tickSpacing = 200;
        uint256 token0Amount = 1; // 1 wei
        uint256 token1Amount = 1_000_000_000 * 1e18; // 1B TAX
        
        // 10 ETH = 1B TAX (10 ETH market cap)
        uint160 startingPrice = 792280926924313289846529216293289;
        int24 tickLower = int24(-887200);
        int24 tickUpper = int24(184200);
        
        PoolKey memory key = PoolKey(currency0, currency1, lpFee, tickSpacing, IHooks(_hook));
        bytes memory hookData = new bytes(0);
        
        // Hardcoded from LiquidityAmounts.getLiquidityForAmounts
        uint128 liquidity = 39900000000000000000000;
        
        uint256 amount0Max = token0Amount + 1 wei;
        uint256 amount1Max = token1Amount + 1 wei;
        
        (bytes memory actions, bytes[] memory mintParams) = _mintLiquidityParams(
            key, 
            tickLower, 
            tickUpper, 
            liquidity, 
            amount0Max, 
            amount1Max, 
            address(0x000000000000000000000000000000000000dEaD), 
            hookData
        );
        
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encodeWithSelector(
            IPositionManager(posm).initializePool.selector, 
            key, 
            startingPrice, 
            hookData
        );
        params[1] = abi.encodeWithSelector(
            IPositionManager(posm).modifyLiquidities.selector,
            abi.encode(actions, mintParams),
            block.timestamp + 60
        );
        
        uint256 valueToPass = amount0Max;
        
        IAllowanceTransfer(permit2).approve(
            address(this), 
            address(posm), 
            type(uint160).max, 
            type(uint48).max
        );
        IPositionManager(posm).multicall{value: valueToPass}(params);
        
        loadingLiquidity = false;    

        uint256 remainingTokens = balanceOf(address(this));
        if (remainingTokens > 0) {
            _transfer(address(this), owner(), remainingTokens);
        }
        uint256 remainingETH = address(this).balance;
        if (remainingETH > 0) {
            SafeTransferLib.safeTransferETH(owner(), remainingETH);
        }
    }

    /// @notice Creates parameters for minting liquidity in Uniswap V4
    function _mintLiquidityParams(
        PoolKey memory poolKey,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 liquidity,
        uint256 amount0Max,
        uint256 amount1Max,
        address recipient,
        bytes memory hookData
    ) internal pure returns (bytes memory, bytes[] memory) {
        bytes memory actions = abi.encodePacked(
            uint8(Actions.MINT_POSITION),
            uint8(Actions.SETTLE_PAIR)
        );
        
        bytes[] memory params = new bytes[](2);
        params[0] = abi.encode(
            poolKey,
            _tickLower,
            _tickUpper,
            liquidity,
            amount0Max,
            amount1Max,
            recipient,
            hookData
        );
        params[1] = abi.encode(poolKey.currency0, poolKey.currency1);
        
        return (actions, params);
    }

    /// @notice Allows the contract to receive ETH
    receive() external payable {
        // Allow receiving ETH for fees
    }
}