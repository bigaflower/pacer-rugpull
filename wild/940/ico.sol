// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(
    uint80 _roundId
  ) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

  function latestRoundData()
    external
    view
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

library Address {

    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

interface IERC20Permit {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);

    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }
  
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

contract GcxpIco is ReentrancyGuard, Ownable {

    using SafeERC20 for IERC20;
    using Address for address;

    // Chainlink price feed for ETH/USD
    AggregatorV3Interface internal priceFeedForEth;

    // Chainlink price feed for BTC/USD
    AggregatorV3Interface internal priceFeedForBtc;

    address public constant FUNDER_WALLET = 0x0572798938a8aA670B31b4369733a890E56684fd;
    address public usdtToken = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address public btcToken= 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address public gcxpCoin = 0x09580506415e36c1DdE0d08eB8910ADEC13c064b;

    uint256 constant GCXP_DECIMALS = 1e18;
    uint256 public constant ICO_TOTAL_LIMIT = 30_000_000_000 * 1e18; // 30 Billion
    
    uint256 public usdtRaised;
    uint256 public totalSoldGcxpToken;
    uint256 public gcxpPerDollar = 1e16; // 0.01 in wei where 1 GCXP = 0.01 USD

    bool public isActive;

    enum BuyType {
        eth,
        usdt,
        btc
    }

    struct ICOConfig {
        uint8 currentSalePhase;
        uint256 saleStartTime;
        uint256 saleEndTime;
    }

    struct UserDeposit {
        uint256 dollarValue;    // dollar amount 
        uint256 estimatedAmount; // user payed amount
        uint256 userGcxpAmount;   // user estimate GCXP
        uint256 investTime;      // user invest time in second
        BuyType currencyType;     // store currency type
        uint8 salePhaseType;       // store sale phase type
    } 

    ICOConfig private _icoConfig;

    mapping(address => uint256) public userPurchaseInUsd;
    mapping(address => UserDeposit[]) public userDeposits; // userAddress => UserDeposit
    
    event BuyWithToken(address indexed userAddress, uint256 usdAmount, uint256 estimatedAmount, uint256 gcxpAmount, BuyType buyType);
    event BuyWithNative(address indexed userAddress, uint256 usdAmount, uint256 estimatedNative, uint256 gcxpAmount, BuyType buyType);
    event TokenAddressesUpdated(address indexed usdtToken, address btcToken, address gcxpCoin);
    event NativeWithdraw(address indexed to, uint256 amount);
    event SaleConfigured(uint8 phase, uint256 start, uint256 end, uint256 price);
    event ToggleSale();
  
    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }
    
    modifier onlyEoA(address _account) {
        require(!isContract(_account), "Contract Address");
        _;
    }

    modifier nonZero(uint256 amount) {
        require(amount >= 1 ," Invalid input amount");
        _;
    }

    modifier notPaused() {
        require(isActive, "Sale is paused.");
        _;
    }

    modifier isSaleStarted() {
        require(block.timestamp > _icoConfig.saleStartTime && _icoConfig.saleEndTime > block.timestamp," Sale is not started or sale is ended");
        _;
    }

    constructor(address _priceFeedForEth, address _priceFeedForBtc) Ownable(msg.sender) {
        require(_priceFeedForEth != address(0), "Invalid ETH feed");
        require(_priceFeedForBtc != address(0), "Invalid BTC feed");
        priceFeedForEth = AggregatorV3Interface(_priceFeedForEth);
        priceFeedForBtc = AggregatorV3Interface(_priceFeedForBtc);
    }

    /**** OnlyOwner ****/

    /// @notice Function to toggle sale if needed only by owner
    function toggleSale() external onlyOwner{
        isActive = !isActive;
        emit ToggleSale();
    }
    
    function updateTokenAddresses(address _usdtToken, address _btcToken, address _gcxpCoin) external onlyOwner {
        require(_usdtToken != address(0), "USDT address cannot be zero");
        require(_btcToken != address(0), "BTC address cannot be zero");
        require(_gcxpCoin != address(0), "GCXP address cannot be zero");
        usdtToken = _usdtToken;
        btcToken = _btcToken;
        gcxpCoin = _gcxpCoin;
        emit TokenAddressesUpdated(_usdtToken, _btcToken, _gcxpCoin);
    }

    /// @notice This function is used to config the sale
    /// @param setCurrentSalePhase This is used to set the sale phase like 1,2,3
    /// @param saleStart The start time of the phase
    /// @param saleEnd The end time of the phase
    /// @param _gcxpPerDollar The gcxp coin price in each phase, pass the value in wei
    function configSale(uint8 setCurrentSalePhase, uint256 saleStart, uint256 saleEnd, uint256 _gcxpPerDollar) external onlyOwner returns(bool) {
        require(saleStart > block.timestamp && saleEnd > saleStart ,"End time must be greater than start time");
        _icoConfig.currentSalePhase = setCurrentSalePhase;
        _icoConfig.saleStartTime = saleStart;
        _icoConfig.saleEndTime = saleEnd;
        gcxpPerDollar = _gcxpPerDollar;
        isActive = true;
        emit SaleConfigured(setCurrentSalePhase, saleStart, saleEnd, _gcxpPerDollar);
        return true;
    }
   
    /// @notice This function is used for withdraw the token from contract if token stuck
    /// @param tokenAddress The token contract address 
    /// @param tokenAmount The exact amount which is availabe on contract address, we have to pass tokenAmount in wei
    function getTokenFromContract(address tokenAddress, uint256 tokenAmount) external onlyOwner returns(bool){
        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(FUNDER_WALLET, tokenAmount);
        return true;
    }

    /// @dev Owner-only function to withdraw native ETH from the contract.
    /// @param amount The amount of ETH (in wei) to withdraw.
    function withdrawNative(uint256 amount) external nonReentrant onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        Address.sendValue(payable(FUNDER_WALLET), amount);
        emit NativeWithdraw(FUNDER_WALLET, amount);
    }

    /**** Public Functions ****/
    
    /// @notice Function is used to get phase details
    function getICOConfig() external view returns (
        uint8 _currentSalePhase,
        uint256 _saleStartTime,
        uint256 _saleEndTime

    ) {
        _currentSalePhase = _icoConfig.currentSalePhase;
        _saleStartTime = _icoConfig.saleStartTime;
        _saleEndTime = _icoConfig.saleEndTime;
    }

    /// @notice Function to get the live eth price in usd
    function getEthPriceInUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedForEth.latestRoundData();
        return price;
    }

    /// @notice Function to get the live btc token price in usd
    function getBtcPriceInUSD() public view returns (int256) {
        (, int256 price, , , ) = priceFeedForBtc.latestRoundData();
        return price;
    }
    
    /// @notice Function is used to get the estimated value of assert and gcxp coin corresponding to usd
    /// @param usdAmount The usd amount from whihc user wanted to buy gcxp coin we have to pass in real number
    /// @param buyType From which assert user wanted to buy the gcxp coin like 0 mean eth, 1 mean usdt, and 2 mean btc
    function estimateFund(uint256 usdAmount, BuyType buyType) public view nonZero(usdAmount) returns(uint256, uint256){
        uint256 oneTokenPriceInUsd = gcxpPerDollar;
        if(BuyType.eth == buyType){
            int256 liveEthPrice = getEthPriceInUSD() * 10 ** 10; // eth is 18 decimals
            uint256 dollarAmount = usdAmount * GCXP_DECIMALS * GCXP_DECIMALS;
            uint256 ethInDollar = (dollarAmount) / uint256(liveEthPrice) ;
            uint256 gcxpAmount = (usdAmount * GCXP_DECIMALS * GCXP_DECIMALS) / oneTokenPriceInUsd;
            return (ethInDollar, gcxpAmount);
        }
        if (BuyType.usdt == buyType){
            uint256 usdtAmount = usdAmount * (10**6); // usdt is 6 decimals
            uint256 gcxpAmount = (usdAmount * GCXP_DECIMALS * GCXP_DECIMALS) / oneTokenPriceInUsd;
            return (usdtAmount, gcxpAmount); 
        }
        if (BuyType.btc == buyType){
            int256 liveBtcPrice = getBtcPriceInUSD();  // btc is 8 decimals
            uint256 dollarAmount = usdAmount;
            uint256 btcInDollar = (dollarAmount *10**16) / uint256(liveBtcPrice) ;
            uint256 gcxpAmount = (usdAmount * GCXP_DECIMALS * GCXP_DECIMALS) / oneTokenPriceInUsd;
            return (btcInDollar, gcxpAmount); 
        }
        revert();
    }
     
    /// @notice This function is used buy Gcxp coin using token(USDT, BTC) in all sale
    /// @param usdAmount The usdAmount which means if user want to buy for 50$ so just pass 50
    /// @param buyType From which token user wanted to buy the gcxp coin like 1 mean usdt, and 2 mean btc
    function buyWithToken(uint256 usdAmount, BuyType buyType) external
        nonReentrant
        notPaused
        nonZero(usdAmount)
        onlyEoA(msg.sender)
        isSaleStarted
        returns (bool)
    {   
        require(buyType == BuyType.usdt || buyType == BuyType.btc, "Invalid token type");
        address tokenAddress;
        tokenAddress = (buyType == BuyType.usdt) ? usdtToken : btcToken;
        IERC20 token = IERC20(tokenAddress);
        uint256 estimatedAmount;
        uint256 gcxpAmount;
        (estimatedAmount, gcxpAmount) = estimateFund(usdAmount, buyType);
        require(IERC20(gcxpCoin).balanceOf(address(this)) >= gcxpAmount,"Not enough tokens in contract");
        _checkSupply(gcxpAmount);
        require(token.allowance(msg.sender, address(this)) >= estimatedAmount,"Insufficient allowance");
        updateUserState(usdAmount, estimatedAmount, gcxpAmount, block.timestamp, buyType, _icoConfig.currentSalePhase);
        token.safeTransferFrom(msg.sender, FUNDER_WALLET, estimatedAmount);
        IERC20(gcxpCoin).safeTransfer(msg.sender, gcxpAmount);
        emit BuyWithToken(msg.sender, usdAmount, estimatedAmount, gcxpAmount, buyType);
        return true;
    }
    
    /// @notice This function is used buy Gcxp coin using native token
    /// @param usdAmount The amount is in usd means if user want to buy for 50$ so just pass 50
    function buyWithNative(uint256 usdAmount) external payable
        nonReentrant
        notPaused
        onlyEoA(msg.sender)
        nonZero(usdAmount)
        isSaleStarted
        returns (bool)
    {
        uint256 estimatedNative;
        uint256 gcxpAmount;
        (estimatedNative, gcxpAmount) = estimateFund(usdAmount, BuyType.eth);
        require(IERC20(gcxpCoin).balanceOf(address(this)) >= gcxpAmount,"Not enough tokens in contract");
        _checkSupply(gcxpAmount);
        require(msg.value >= estimatedNative, "Insufficient Native value");
        updateUserState(usdAmount, estimatedNative, gcxpAmount, block.timestamp, BuyType.eth, _icoConfig.currentSalePhase);
        if(msg.value > estimatedNative){
            uint256 userExtraCoin = msg.value - estimatedNative;
            Address.sendValue(payable(msg.sender), userExtraCoin);
        }
        Address.sendValue(payable(FUNDER_WALLET), estimatedNative);
        IERC20(gcxpCoin).safeTransfer(msg.sender, gcxpAmount);
        emit BuyWithNative(msg.sender, usdAmount, estimatedNative, gcxpAmount, BuyType.eth);
        return true;
    }

    /// @notice To get the user invest details
    /// @param userAddress The user address from which we need to get details
    function getUserDetails(address userAddress) external view returns (UserDeposit[] memory) {
        return userDeposits[userAddress];
    }

    /**** Internal ****/

    /// @dev function to update the user details
    function updateUserState(uint256 usdAmount, uint256 estimatedAmount, uint256 gcxpAmount, uint256 investTime, BuyType buyType, uint8 salePhase) internal {
        userDeposits[msg.sender].push(UserDeposit(usdAmount, estimatedAmount, gcxpAmount, investTime, buyType, salePhase));
        userPurchaseInUsd[msg.sender] += usdAmount;
        usdtRaised += usdAmount;
        totalSoldGcxpToken += gcxpAmount;
    }
    
    /// @dev Function to check is total supply reached or not
    /// @param _tokenAmount The gcxp coin amount
    function _checkSupply(uint256 _tokenAmount) internal view {
        require(totalSoldGcxpToken + _tokenAmount <= ICO_TOTAL_LIMIT, "ICO token cap reached");
    }
    
    /// @dev Function is to check caller is contract or not
    /// @param account The address
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    receive() external payable { }
}