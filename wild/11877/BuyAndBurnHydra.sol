// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../interfaces/IUniswapV3Factory.sol";
import "../interfaces/IUniswapV3Pool.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import "./openzeppelin/security/ReentrancyGuard.sol";

import "../libs/Constant.sol";
import "../libs/PoolAddress.sol";
import "../libs/CallbackValidation.sol";
import "../libs/TransferHelper.sol";
import "../libs/FullMath.sol";
import "../libs/OracleLibrary.sol";

import "../interfaces/ITITANX.sol";
import "../interfaces/IHydra.sol";
import "../interfaces/IDragonX.sol";

contract BuyAndBurnHydra is ReentrancyGuard {
    /** @dev genesis timestamp */
    uint256 private immutable i_genesisTs;

    /** @dev Hydra contract address */
    address private s_HydraAddress;
    /** @dev owner address */
    address private s_ownerAddress;
    /** @dev Hydra DragonX uniswapv3 pool address */
    address private s_poolAddress;
    /** @dev is initial LP created */
    bool private s_initialLiquidityCreated;

    //TitanX to DragonX
    /** @dev tracks total buy from TitanX to DragonX */
    uint256 private s_totalTitanXBuy;

    /** @dev tracks total DragonX bought using TitanX*/
    uint256 private s_totalDragonXBought;

    //DragonX to Hydra
    /** @dev tracks collect fees (DragonX) for buyandburn */
    uint256 private s_feesDragonXFunds;

    /** @dev tracks total buy from DragonX to Hydra */
    uint256 private s_totalDragonXBuy;

    /** @dev tracks total buyandburn from fees (DragonX) */
    uint256 private s_totalDragonXFeesBuy;

    //burn stats
    /** @dev tracks Hydra burned through buyandburn */
    uint256 private s_totalHydraBurn;

    /** @dev tracks total Hydra burned from fees (Hydra) */
    uint256 private s_totalHydraFeesBurn;

    /** @dev total DragonX burned */
    uint256 private s_totalDragonXBurn;

    //config variables
    /** @dev tracks current per swap cap DragonX */
    uint256 private s_capPerSwapDragonX;

    /** @dev tracks current per swap cap TitanX */
    uint256 private s_capPerSwapTitanX;

    /** @dev tracks timestamp of the last TitanX buy DragonX was called */
    uint256 private s_lastCallTsBuyDragonX;

    /** @dev tracks timestamp of the last DragonX buy Hydra and burn was called */
    uint256 private s_lastCallTsBuynBurn;

    /** @dev buy DragonX slippage amount between 5 - 15 */
    uint256 private s_slippageBuyDragonX;

    /** @dev buy and burn slippage amount between 5 - 15 */
    uint256 private s_slippageBuynBurn;

    /** @dev buy DragonX interval in seconds */
    uint256 private s_intervalBuyDragonX;

    /** @dev buynburn interval in seconds */
    uint256 private s_intervalBuynBurn;

    /** @dev store position token info, only one full range position */
    TokenInfo private s_tokenInfo;

    /** @dev DragonX incentive fee dividend amount */
    uint256 private s_DragonXIncentiveDividend;

    /** @dev TitanX incentive fee dividend amount */
    uint256 private s_TitanXIncentiveDividend;

    /** @dev uniswapv3 oracle price seconds ago */
    uint32 private s_twapSecondsAgo;

    //structs
    struct TokenInfo {
        uint80 tokenId;
        uint128 liquidity;
        int24 tickLower;
        int24 tickUpper;
    }

    event BoughtDragonX(uint256 indexed titanx, uint256 indexed dragonx, address indexed caller);
    event BoughtAndBurned(uint256 indexed dragonx, uint256 indexed hydra, address indexed caller);
    event CollectedFees(uint256 indexed dragonx, uint256 indexed hydra, address indexed caller);

    constructor() {
        i_genesisTs = block.timestamp;
        s_ownerAddress = msg.sender;
        s_capPerSwapDragonX = 5e4 ether;
        s_capPerSwapTitanX = 1e7 ether;
        s_slippageBuyDragonX = MIN_SLIPPAGE;
        s_slippageBuynBurn = MIN_SLIPPAGE;
        s_intervalBuyDragonX = MIN_INTERVAL_SECONDS;
        s_intervalBuynBurn = MIN_INTERVAL_SECONDS;
        s_DragonXIncentiveDividend = 5000;
        s_TitanXIncentiveDividend = 5000;
        s_twapSecondsAgo = 300;
        TransferHelper.safeApprove(TITANX, address(this), type(uint256).max);
        TransferHelper.safeApprove(DRAGONX, address(this), type(uint256).max);
    }

    /** @notice remove owner */
    function renounceOwnership() public {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_ownerAddress = address(0);
    }

    /** @notice set new owner address. Only callable by owner address.
     * @param ownerAddress new owner address
     */
    function setOwnerAddress(address ownerAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(ownerAddress != address(0), "InvalidAddress");
        s_ownerAddress = ownerAddress;
    }

    /** @notice set Hydra address. One-time setter. Only callable by owner address.
     * @param hydraAddress Hydra contract address
     */
    function setHydraContractAddress(address hydraAddress) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(s_HydraAddress == address(0), "CannotResetAddress");
        require(hydraAddress != address(0), "InvalidAddress");
        s_HydraAddress = hydraAddress;
        TransferHelper.safeApprove(TITANX, hydraAddress, type(uint256).max);
        TransferHelper.safeApprove(DRAGONX, hydraAddress, type(uint256).max);
    }

    /**
     * @notice set DragonX cap amount per buynburn call. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setCapPerSwapDragonX(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_capPerSwapDragonX = amount;
    }

    /**
     * @notice set TitanX cap amount per call. Only callable by owner address.
     * @param amount amount in 18 decimals
     */
    function setCapPerSwapTitanX(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        s_capPerSwapTitanX = amount;
    }

    /**
     * @notice set buy DragonX slippage % minimum received amount. Only callable by owner address.
     * @param amount amount from 5 - 15
     */
    function setSlippageBuyDragonX(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount >= MIN_SLIPPAGE && amount <= MAX_SLIPPAGE, "5-15_Only");
        s_slippageBuyDragonX = amount;
    }

    /**
     * @notice set buy and burn slippage % minimum received amount. Only callable by owner address.
     * @param amount amount from 5 - 15
     */
    function setSlippageBuynBurn(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount >= MIN_SLIPPAGE && amount <= MAX_SLIPPAGE, "5-15_Only");
        s_slippageBuynBurn = amount;
    }

    /**
     * @notice set buy DragonX call interval in seconds. Only callable by owner address.
     * @param secs amount in seconds
     */
    function setBuyDragonXInterval(uint256 secs) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(secs >= MIN_INTERVAL_SECONDS && secs <= MAX_INTERVAL_SECONDS, "1m-12h_Only");
        s_intervalBuyDragonX = secs;
    }

    /**
     * @notice set buynburn call interval in seconds. Only callable by owner address.
     * @param secs amount in seconds
     */
    function setBuynBurnInterval(uint256 secs) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(secs >= MIN_INTERVAL_SECONDS && secs <= MAX_INTERVAL_SECONDS, "1m-12h_Only");
        s_intervalBuynBurn = secs;
    }

    /** @notice set DragonX incentive fee percentage callable by owner only
     * amount is in 10000 scaling factor, which means 0.33 is 0.33 * 10000 = 3300
     * @param amount amount between 1 - 10000
     */
    function setDragonXIncentiveFeeDividend(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount != 0 && amount <= 10000, "InvalidAmount");
        s_DragonXIncentiveDividend = amount;
    }

    /** @notice set TitanX incentive fee percentage callable by owner only
     * amount is in 10000 scaling factor, which means 0.33 is 0.33 * 10000 = 3300
     * @param amount amount between 1 - 10000
     */
    function setTitanXIncentiveFeeDividend(uint256 amount) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(amount != 0 && amount <= 10000, "InvalidAmount");
        s_TitanXIncentiveDividend = amount;
    }

    /**
     * @notice set twap seconds ago. Only callable by owner address.
     * @param secs amount in seconds
     */
    function setTwapSecondsAgo(uint32 secs) external {
        require(msg.sender == s_ownerAddress, "InvalidCaller");
        require(secs >= MIN_TWAP_SECONDS && secs <= MAX_TWAP_SECONDS, "2h-12h_Only");
        s_twapSecondsAgo = secs;
    }

    /** @notice burn all Hydra in BuyAndBurn address */
    function burnHydra() public {
        IHydra(s_HydraAddress).burnCAHydra(address(this));
    }

    /** @notice TitanX buy DragonX from uniswap pool */
    function buyDragonX() public nonReentrant {
        //prevent contract accounts (bots) from calling this function
        require(msg.sender == tx.origin, "InvalidCaller");
        //a minium gap of 1 min between each call
        require(block.timestamp - s_lastCallTsBuyDragonX > s_intervalBuyDragonX, "IntervalWait");
        s_lastCallTsBuyDragonX = block.timestamp;

        _titanXBuyDragonX();
    }

    /** @notice DragonX buy and burn Hydra from uniswap pool */
    function buynBurn() public nonReentrant {
        require(s_initialLiquidityCreated, "NeedInitialLP");
        //prevent contract accounts (bots) from calling this function
        require(msg.sender == tx.origin, "InvalidCaller");
        //a minium gap of 1 min between each call
        require(block.timestamp - s_lastCallTsBuynBurn > s_intervalBuynBurn, "IntervalWait");
        s_lastCallTsBuynBurn = block.timestamp;

        _dragonXBuyHydra();
    }

    /** @notice Used by uniswapV3. Modified from uniswapV3 swap callback function to complete the swap */
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external {
        require(amount0Delta > 0 || amount1Delta > 0); // swaps entirely within 0-liquidity regions are not supported

        uint256 swapAmount = amount0Delta > 0 ? uint256(amount0Delta) : uint256(amount1Delta);

        if (keccak256(abi.encodePacked(data)) == keccak256(abi.encodePacked("0x1"))) {
            IUniswapV3Pool pool = CallbackValidation.verifyCallback(
                UNISWAPV3FACTORY,
                DRAGONX,
                TITANX,
                POOLFEE1PERCENT
            );
            require(address(pool) == TITANX_DRAGONX_POOL, "WrongPool");

            s_totalTitanXBuy += swapAmount;

            //swap TitanX for DragonX
            TransferHelper.safeTransferFrom(TITANX, address(this), msg.sender, swapAmount);
            return;
        }

        if (keccak256(abi.encodePacked(data)) == keccak256(abi.encodePacked("0x2"))) {
            IUniswapV3Pool pool = CallbackValidation.verifyCallback(
                UNISWAPV3FACTORY,
                DRAGONX,
                s_HydraAddress,
                POOLFEE1PERCENT
            );
            require(address(pool) == s_poolAddress, "WrongPool");

            /* collected fees are part of the total balance
             * so need to deduct the incentive fees from collected fees
             * in order to get the actual amount used in buy and burn
             */
            uint256 feeFunds = s_feesDragonXFunds;
            if (feeFunds != 0) {
                if (swapAmount < feeFunds) {
                    feeFunds = swapAmount;
                    s_feesDragonXFunds -= feeFunds;
                } else {
                    s_feesDragonXFunds = 0;
                }

                //deduct out the incentive fees from s_feesBuyAndBurn
                feeFunds -= (feeFunds * s_DragonXIncentiveDividend) / INCENTIVE_FEE_PERCENT_BASE;
                s_totalDragonXFeesBuy += feeFunds;
            }
            //update s_totalDragonXBuy which excludes collected fees
            if (swapAmount - feeFunds != 0) s_totalDragonXBuy += swapAmount - feeFunds;

            //swap DragonX for Hydra
            TransferHelper.safeTransferFrom(DRAGONX, address(this), msg.sender, swapAmount);
        }
    }

    /** @notice One-time function to create initial pool to initialize with the desired price ratio.
     * To avoid being front run, must call this function right after contract is deployed and Hydra address is set.
     */
    function createInitialPool() public {
        require(s_poolAddress == address(0), "PoolHasCreated");
        require(s_HydraAddress != address(0), "InvalidHydraAddress");
        _createPool();
    }

    /** @notice One-time function to create initial liquidity pool. */
    function createInitialLiquidity() public {
        require(s_poolAddress != address(0), "NoPoolExists");
        require(!s_initialLiquidityCreated, "LPHasCreated");
        require(IERC20(DRAGONX).balanceOf(address(this)) >= INITIAL_LP_DRAGONX, "NotEnoughDragonX");

        s_initialLiquidityCreated = true;

        // Approve tokens allowance
        TransferHelper.safeApprove(s_HydraAddress, NONFUNGIBLEPOSITIONMANAGER, type(uint256).max);
        TransferHelper.safeApprove(DRAGONX, NONFUNGIBLEPOSITIONMANAGER, type(uint256).max);

        IHydra(s_HydraAddress).mintLPTokens(INITIAL_LP_HYDRA);
        _mintPosition();
    }

    /** @notice collect fees from LP */
    function collectFees() public nonReentrant {
        (uint256 amount0, uint256 amount1) = _collectFees();
        uint256 hydra;
        uint256 dragonx;
        if (DRAGONX < s_HydraAddress) {
            dragonx = amount0;
            hydra = amount1;
        } else {
            hydra = amount0;
            dragonx = amount1;
        }

        s_totalHydraFeesBurn += hydra;
        s_feesDragonXFunds += dragonx;
        burnHydra();
        emit CollectedFees(dragonx, hydra, msg.sender);
    }

    // ==================== Private Functions =======================================
    /** @dev sort tokens in ascending order, that's how uniswap identify the pair
     * @return token0 token address that is digitally smaller than token1
     * @return token1 token address that is digitally larger than token0
     * @return amount0 LP amount for token0
     * @return amount1 LP amount for token1
     */
    function _getTokensConfig()
        private
        view
        returns (address token0, address token1, uint256 amount0, uint256 amount1)
    {
        token0 = DRAGONX;
        token1 = s_HydraAddress;
        amount0 = INITIAL_LP_DRAGONX;
        amount1 = INITIAL_LP_HYDRA;

        if (s_HydraAddress < DRAGONX) {
            token0 = s_HydraAddress;
            token1 = DRAGONX;
            amount0 = INITIAL_LP_HYDRA;
            amount1 = INITIAL_LP_DRAGONX;
        }
    }

    /** @dev create pool with the preset sqrt price ratio */
    function _createPool() private {
        (address token0, address token1, , ) = _getTokensConfig();
        s_poolAddress = INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER)
            .createAndInitializePoolIfNecessary(
                token0,
                token1,
                POOLFEE1PERCENT,
                DRAGONX < s_HydraAddress
                    ? INITIAL_SQRTPRICE_DRAGONX_HYDRA
                    : INITIAL_SQRTPRICE_HYDRA_DRAGONX
            );
    }

    /** @dev mint full range LP token */
    function _mintPosition() private {
        (
            address token0,
            address token1,
            uint256 amount0Desired,
            uint256 amount1Desired
        ) = _getTokensConfig();

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager
            .MintParams({
                token0: token0,
                token1: token1,
                fee: POOLFEE1PERCENT,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amount0Desired,
                amount1Desired: amount1Desired,
                amount0Min: (amount0Desired * 90) / 100,
                amount1Min: (amount1Desired * 90) / 100,
                recipient: address(this),
                deadline: block.timestamp + 600
            });

        (uint256 tokenId, uint256 liquidity, , ) = INonfungiblePositionManager(
            NONFUNGIBLEPOSITIONMANAGER
        ).mint(params);

        s_tokenInfo.tokenId = uint80(tokenId);
        s_tokenInfo.liquidity = uint128(liquidity);
        s_tokenInfo.tickLower = MIN_TICK;
        s_tokenInfo.tickUpper = MAX_TICK;
    }

    /** @dev call uniswapv3 collect funtion to collect LP fees
     * @return amount0 token0 amount
     * @return amount1 token1 amount
     */
    function _collectFees() private returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager
            .CollectParams(
                s_tokenInfo.tokenId,
                address(this),
                type(uint128).max,
                type(uint128).max
            );
        (amount0, amount1) = INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).collect(
            params
        );
    }

    /** @dev check against swap cap and use the amount to swap DragonX.
     * reward TitanX as incentive fee to caller.
     */
    function _titanXBuyDragonX() private {
        uint256 titanXAmount = IERC20(TITANX).balanceOf(address(this));
        require(titanXAmount != 0, "NoAvailableFunds");

        uint256 titanXCap = s_capPerSwapTitanX;
        if (titanXAmount > titanXCap) titanXAmount = titanXCap;

        uint256 incentiveFee = (titanXAmount * s_TitanXIncentiveDividend) /
            INCENTIVE_FEE_PERCENT_BASE;

        titanXAmount -= incentiveFee;
        uint256 dragonxBought = _swapTitanXForDragonX(titanXAmount);
        s_totalDragonXBought += dragonxBought;

        //DragonX amount for Hydra Vortex
        uint256 burnAmount = (dragonxBought * DRAGONX_BURN_PERCENT) / PERCENT_BPS;
        uint256 vortexAmount = (dragonxBought * DRAGONX_VORTEX_PERCENT) / PERCENT_BPS;

        s_totalDragonXBurn += burnAmount;

        //transfer to Dragonx Burn Proxy to be burned
        TransferHelper.safeTransferFrom(DRAGONX, address(this), DRAGONX_BURN_PROXY, burnAmount);
        IDragonX(DRAGONX_BURN_PROXY).burn();

        //fund Hydra vortex
        IHydra(s_HydraAddress).fundVortexDragonX(vortexAmount);

        //transfer incentive fee
        TransferHelper.safeTransferFrom(TITANX, address(this), msg.sender, incentiveFee);
    }

    /** @dev call uniswap swap function to swap TitanX for DragonX
     * @param amountTitanX TitanX amount
     */
    function _swapTitanXForDragonX(uint256 amountTitanX) private returns (uint256 dragonXAmount) {
        //calculate minimum amount for slippage protection
        uint256 minTokenAmount = ((amountTitanX * 1 ether * (100 - s_slippageBuyDragonX)) /
            getCurrentTitanXPrice()) / 100;

        (int256 amount0, int256 amount1) = IUniswapV3Pool(TITANX_DRAGONX_POOL).swap(
            address(this),
            TITANX < DRAGONX,
            int256(amountTitanX),
            TITANX < DRAGONX ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            "0x1"
        );
        dragonXAmount = TITANX < DRAGONX
            ? uint256(amount1 >= 0 ? amount1 : -amount1)
            : uint256(amount0 >= 0 ? amount0 : -amount0);

        //slippage protection check
        require(dragonXAmount >= minTokenAmount, "TooLittleReceived");

        emit BoughtDragonX(amountTitanX, dragonXAmount, msg.sender);
    }

    /** @dev check against swap cap and use the amount to swap Hydra.
     * reward DragonX as incentive fee to caller.
     */
    function _dragonXBuyHydra() private {
        uint256 dragonXAmount = IERC20(DRAGONX).balanceOf(address(this));
        require(dragonXAmount != 0, "NoAvailableFunds");

        uint256 dragonXCap = s_capPerSwapDragonX;
        if (dragonXAmount > dragonXCap) dragonXAmount = dragonXCap;

        uint256 incentiveFee = (dragonXAmount * s_TitanXIncentiveDividend) /
            INCENTIVE_FEE_PERCENT_BASE;
        dragonXAmount -= incentiveFee;

        _swapDragonXForHydra(dragonXAmount);
        TransferHelper.safeTransfer(DRAGONX, msg.sender, incentiveFee);
    }

    /** @dev call uniswap swap function to swap DragonX for Hydra, then burn all Hydra
     * @param amountDragonX DragonX amount
     */
    function _swapDragonXForHydra(uint256 amountDragonX) private {
        //calculate minimum amount for slippage protection
        uint256 minTokenAmount = ((amountDragonX * 1 ether * (100 - s_slippageBuynBurn)) /
            getCurrentDragonXPrice()) / 100;

        (int256 amount0, int256 amount1) = IUniswapV3Pool(s_poolAddress).swap(
            address(this),
            DRAGONX < s_HydraAddress,
            int256(amountDragonX),
            DRAGONX < s_HydraAddress ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1,
            "0x2"
        );
        uint256 hydra = DRAGONX < s_HydraAddress
            ? uint256(amount1 >= 0 ? amount1 : -amount1)
            : uint256(amount0 >= 0 ? amount0 : -amount0);
        //slippage protection check
        require(hydra >= minTokenAmount, "TooLittleReceived");

        s_totalHydraBurn += hydra;
        burnHydra();

        emit BoughtAndBurned(amountDragonX, hydra, msg.sender);
    }

    //views
    /** @notice supported interface check
     * @param interfaceId interfaceId
     * return bool true/false
     */
    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return
            interfaceId == IERC165.supportsInterface.selector ||
            interfaceId == type(IHydra).interfaceId;
    }

    /** @notice get buy and burn current contract day
     * @return day current contract day
     */
    function getCurrentContractDay() public view returns (uint256) {
        return ((block.timestamp - i_genesisTs) / SECONDS_IN_DAY) + 1;
    }

    /** @notice get Hydra DragonX pool address
     * @return address Hydra DragonX pool address
     */
    function getPoolAddress() public view returns (address) {
        return s_poolAddress;
    }

    /** @notice get TitanX balance in buyandburn contract
     * @return TitanX balance
     */
    function getTitanXBuyDragonXFunds() public view returns (uint256) {
        return IERC20(TITANX).balanceOf(address(this));
    }

    /** @notice get buy and burn funds (exclude DragonX fees)
     * @return amount DragonX amount
     */
    function getDragonXBuyAndBurnFunds() public view returns (uint256) {
        return IERC20(DRAGONX).balanceOf(address(this)) - s_feesDragonXFunds;
    }

    /** @notice get buy and burn funds from DragonX fees only
     * @return amount DragonX amount
     */
    function getDragonXFeesBuyAndBurnFunds() public view returns (uint256) {
        return s_feesDragonXFunds;
    }

    /** @notice get total TitanX amount used to buy DragonX
     * @return amount total buy amount
     */
    function getTotalTitanXBuy() public view returns (uint256) {
        return s_totalTitanXBuy;
    }

    /** @notice get total DragonX amount bought using TitanX
     * @return amount total DragonX amount
     */
    function getTotalDragonXBought() public view returns (uint256) {
        return s_totalDragonXBought;
    }

    /** @notice get total DragonX amount used to buy and burn Hydra (exclude DragonX fees)
     * @return amount total DragonX amount
     */
    function getTotalDragonXBuy() public view returns (uint256) {
        return s_totalDragonXBuy;
    }

    /** @notice get total DragonX amount from fees only used to buy and burn Hydra
     * @return amount total DragonX amount
     */
    function getTotalDragonXFeesBuy() public view returns (uint256) {
        return s_totalDragonXFeesBuy;
    }

    /** @notice get total Hydra amount burned
     * @return amount total Hydra amount
     */
    function getTotalHydraBurn() public view returns (uint256) {
        return s_totalHydraBurn;
    }

    /** @notice get total Hydra amount burned from collected LP fees
     * @return amount total Hydra amount
     */
    function getTotalHydraFeesBurn() public view returns (uint256) {
        return s_totalHydraFeesBurn;
    }

    /** @notice get total DragonX amount burned from collected LP fees
     * @return amount total DragonX amount
     */
    function getTotalDragonXBurn() public view returns (uint256) {
        return s_totalDragonXBurn;
    }

    /** @notice get LP token info
     * @return tokenId tokenId
     * @return liquidity liquidity
     * @return tickLower tickLower
     * @return tickUpper tickUpper
     */
    function getTokenInfo()
        public
        view
        returns (uint256 tokenId, uint256 liquidity, int24 tickLower, int24 tickUpper)
    {
        return (
            s_tokenInfo.tokenId,
            s_tokenInfo.liquidity,
            s_tokenInfo.tickLower,
            s_tokenInfo.tickUpper
        );
    }

    /** @notice get LP token URI
     * @return uri URI
     */
    function getTokenURI() public view returns (string memory) {
        return
            INonfungiblePositionManager(NONFUNGIBLEPOSITIONMANAGER).tokenURI(s_tokenInfo.tokenId);
    }

    /** @notice get current sqrt price of the Hydra/DragonX pair
     * @return sqrtPrice sqrt Price X96
     */
    function getCurrentHydraSqrtPriceX96() public view returns (uint160) {
        IUniswapV3Pool pool = IUniswapV3Pool(s_poolAddress);
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        return sqrtPriceX96;
    }

    /** @notice get current price of DragonX/TitanX pair
     * @return price price in TitanX
     */
    function getCurrentTitanXPrice() public view returns (uint256) {
        uint256 sqrtPriceX96 = getTwapTitanXTokenSqrt(DRAGONX, POOLFEE1PERCENT);
        uint256 numerator1 = sqrtPriceX96 * sqrtPriceX96;
        uint256 numerator2 = 10 ** 18;
        uint256 price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        price = TITANX < DRAGONX ? (1 ether * 1 ether) / price : price;
        return price;
    }

    /** @notice get TitanX/{token} twap sqrt ratio
     * @return amount
     */
    function getTwapTitanXTokenSqrt(address token, uint24 fee) public view returns (uint256) {
        address pool = IUniswapV3Factory(UNISWAPV3FACTORY).getPool(TITANX, token, fee);
        (int24 meanTick, ) = OracleLibrary.consult(pool, s_twapSecondsAgo);
        return TickMath.getSqrtRatioAtTick(meanTick);
    }

    /** @notice get current price of the Hydra/DragonX pair
     * @return price price in DragonX
     */
    function getCurrentDragonXPrice() public view returns (uint256) {
        IUniswapV3Pool pool = IUniswapV3Pool(s_poolAddress);
        (uint256 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint256 numerator1 = sqrtPriceX96 * sqrtPriceX96;
        uint256 numerator2 = 10 ** 18;
        uint256 price = FullMath.mulDiv(numerator1, numerator2, 1 << 192);
        price = DRAGONX < s_HydraAddress ? (1 ether * 1 ether) / price : price;
        return price;
    }

    /** @notice get Hydra address
     * @return HydraAddress Hydra address
     */
    function getHydraAddress() public view returns (address) {
        return s_HydraAddress;
    }

    /** @notice get cap amount per buy and burn
     * @return cap amount
     */
    function getDragonXBuyAndBurnCap() public view returns (uint256) {
        return s_capPerSwapDragonX;
    }

    /** @notice get cap amount per buy and burn
     * @return cap amount
     */
    function getTitanXBuyAndBurnCap() public view returns (uint256) {
        return s_capPerSwapTitanX;
    }

    /** @notice get buy DragonX slippage
     * @return slippage
     */
    function getSlippageBuyDragonX() public view returns (uint256) {
        return s_slippageBuyDragonX;
    }

    /** @notice get buynburn slippage
     * @return slippage
     */
    function getSlippageBuynBurn() public view returns (uint256) {
        return s_slippageBuynBurn;
    }

    /** @notice get the buynburn interval between each call in seconds
     * @return seconds
     */
    function getBuyDragonXInterval() public view returns (uint256) {
        return s_intervalBuyDragonX;
    }

    /** @notice get the buynburn interval between each call in seconds
     * @return seconds
     */
    function getBuynBurnInterval() public view returns (uint256) {
        return s_intervalBuynBurn;
    }

    /** @notice get the buy DragonX last called timestamp
     * return ts timestamp in seconds
     */
    function getLastCalledTsBuyDragonX() public view returns (uint256) {
        return s_lastCallTsBuyDragonX;
    }

    /** @notice get the buy and burn last called timestamp
     * return ts timestamp in seconds
     */
    function getLastCalledTsBuynBurn() public view returns (uint256) {
        return s_lastCallTsBuynBurn;
    }

    /** @notice get current DragonX incentive fee dividend
     * @return amount
     */
    function getDragonXIncentiveDividend() public view returns (uint256) {
        return s_DragonXIncentiveDividend;
    }

    /** @notice get current TitanX incentive fee dividend
     * @return amount
     */
    function getTitanXIncentiveDividend() public view returns (uint256) {
        return s_TitanXIncentiveDividend;
    }

    /** @notice get current seconds ago
     * @return seconds
     */
    function getTwapSecondsAgoConfig() public view returns (uint256) {
        return s_twapSecondsAgo;
    }
}
