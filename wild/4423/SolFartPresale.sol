/*

SolFart - The Gassiest Token on the Blockchain!

  ____        _ _____          _   
 / ___|  ___ | |  ___|_ _ _ __| |_ 
 \___ \ / _ \| | |_ / _` | '__| __|
  ___) | (_) | |  _| (_| | |  | |_ 
 |____/ \___/|_|_|  \__,_|_|   \__|
                                   
The most explosive presale in crypto history!
Get ready for some serious gas! 🚀💨

*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

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


pragma solidity ^0.8.20;

abstract contract Ownable is Context {
    address private _owner;

    error OwnableUnauthorizedAccount(address account);

    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.20;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity ^0.8.20;

library Address {

    error AddressInsufficientBalance(address account);
    error AddressEmptyCode(address target);
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

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
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

            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    function _revert(bytes memory returndata) private pure {
        if (returndata.length > 0) {
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

pragma solidity ^0.8.20;

library SafeERC20 {
    using Address for address;

    error SafeERC20FailedOperation(address token);
    error SafeERC20FailedDecreaseAllowance(
        address spender,
        uint256 currentAllowance,
        uint256 requestedDecrease
    );

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeCall(token.transferFrom, (from, to, value))
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 requestedDecrease
    ) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(
                    spender,
                    currentAllowance,
                    requestedDecrease
                );
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    function forceApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        bytes memory approvalCall = abi.encodeCall(
            token.approve,
            (spender, value)
        );

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(
                token,
                abi.encodeCall(token.approve, (spender, 0))
            );
            _callOptionalReturn(token, approvalCall);
        }
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    function _callOptionalReturnBool(
        IERC20 token,
        bytes memory data
    ) private returns (bool) {

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success &&
            (returndata.length == 0 || abi.decode(returndata, (bool))) &&
            address(token).code.length > 0;
    }
}

pragma solidity ^0.8.0;

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

pragma solidity ^0.8.0;

contract SolFartPresale is Ownable {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;

    AggregatorV3Interface public priceFeed;

    uint8 public priceFeedDec;
    uint256 public priceInUSD;
    uint public immutable saleTokenDec = 18;
    uint256 public totalTokensforSale;
    mapping(address => bool) public allowedPaymentMethod;
    bool public saleStatus;
    address[] public participants;
    mapping(address => bool) public participantExists;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(uint256 => uint256)) public balanceOfPerStage;
    uint256 public totalParticipants;
    uint256 public totalTokensSold;
    uint256 public totalUSDRaised;
    address public feeWallet;
    address public solFartWallet;
    
    struct ParticipantDetails {
        address buyer;
        uint256 amount;
    }

    event BuySolFart(
        address indexed buyer,
        address indexed token,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _aggregatorAddress,
        address _feeWallet,
        address _solFartWallet
    ) Ownable(msg.sender) {
        allowedPaymentMethod[address(0)] = true; // ETH allowed by default

        priceFeed = AggregatorV3Interface(_aggregatorAddress);
        priceFeedDec = priceFeed.decimals();

        feeWallet = _feeWallet;
        solFartWallet = _solFartWallet;
    }

    modifier saleEnabled() {
        require(saleStatus == true, "Presale is not active");
        _;
    }

    modifier saleStopped() {
        require(saleStatus == false, "Presale is still active");
        _;
    }

    function updateAggregator(address _aggregatorAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_aggregatorAddress);
        priceFeedDec = priceFeed.decimals();
    }

    function stopSale() external onlyOwner saleEnabled {
        saleStatus = false;
    }

    function resumeSale() external onlyOwner saleStopped {
        saleStatus = true;
    }

    function switchStage(uint256 _priceInUSD) external onlyOwner {
        priceInUSD = _priceInUSD;
    }

    function startSolFartPresale(
        uint256 _priceInUSD,
        uint256 _totalTokensForSale,
        bool _saleStatus
    ) external onlyOwner {
        priceInUSD = _priceInUSD;
        totalTokensforSale = _totalTokensForSale;
        saleStatus = _saleStatus;
    }

    function addAllowedPayTokens(address[] memory _tokens) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            allowedPaymentMethod[_tokens[i]] = true;
        }
    }

    function removeAllowedPayTokens(
        address[] memory _tokens
    ) external onlyOwner {
        for (uint i = 0; i < _tokens.length; i++) {
            allowedPaymentMethod[_tokens[i]] = false;
        }
    }

    function getETHPrice() public view returns (uint256) {
        (, int answer, , , ) = priceFeed.latestRoundData();

        return uint256(answer) * (10 ** (18 - priceFeedDec));
    }

    function calculateUSDValue(address _token, uint256 _amount) internal view returns (uint256) {
        if (_token == address(0)) {
            // ETH - use price feed
            uint256 ethPrice = getETHPrice();
            return (_amount * ethPrice) / 1e18;
        } else {
            // Check if it's a stablecoin by symbol
            string memory symbol = IERC20Metadata(_token).symbol();
            if (keccak256(bytes(symbol)) == keccak256(bytes("USDT")) || 
                keccak256(bytes(symbol)) == keccak256(bytes("USDC"))) {
                // USDT/USDC = $1, normalize to 18 decimals
                uint8 tokenDec = IERC20Metadata(_token).decimals();
                return (_amount * 1e18) / (10 ** tokenDec);
            } else {
                revert("Token price calculation not supported");
            }
        }
    }

    function getTokenAmount(
        address _token,
        uint256 _amount
    ) public view returns (uint256) {
        uint256 amtOut;
        if (priceInUSD == 0) return 0;

        if (_token != address(0)) {
            require(allowedPaymentMethod[_token], "Token not allowed");
            uint8 tokenDec = IERC20Metadata(_token).decimals();

            amtOut =
                (_amount * (10 ** ((saleTokenDec * 2) - tokenDec))) /
                priceInUSD;
        } else {
            uint256 ethPrice = getETHPrice();

            amtOut =
                ((_amount * (10 ** (18 - saleTokenDec))) * ethPrice) /
                priceInUSD;
        }
        return amtOut;
    }

    function transferFunds(address _token, uint256 _amount) internal {
        uint256 feeAmt = (_amount * 5) / 100;
        if (_token == address(0)) {
            // ETH path
            (bool feeSuccess, ) = payable(feeWallet).call{value: feeAmt}("");
            require(feeSuccess, "Fee transfer failed");
            (bool solFartSuccess, ) = payable(solFartWallet).call{
                value: _amount - feeAmt
            }("");
            require(solFartSuccess, "SolFart transfer failed");
        } else {
            // ERC20 path
            IERC20(_token).safeTransferFrom(msg.sender, feeWallet, feeAmt);
            IERC20(_token).safeTransferFrom(
                msg.sender,
                solFartWallet,
                _amount - feeAmt
            );
        }
    }

    function buySolFart(
        address _token,
        uint256 _amount,
        uint256 _stage
    ) external payable saleEnabled {
        uint256 amount = _token != address(0) ? _amount : msg.value;
        uint256 saleTokenAmt = getTokenAmount(_token, amount);

        require(saleTokenAmt != 0, "Invalid token amount");
        require((totalTokensSold + saleTokenAmt) <= totalTokensforSale, "Exceeds total supply");

        transferFunds(_token, _token == address(0) ? msg.value : _amount);

        // Track USD value raised
        uint256 usdValue = calculateUSDValue(_token, amount);
        totalUSDRaised += usdValue;

        totalTokensSold += saleTokenAmt;

        if (!participantExists[msg.sender]) {
            participants.push(msg.sender);
            participantExists[msg.sender] = true;
            totalParticipants += 1;
        }

        balanceOf[msg.sender] += saleTokenAmt;
        balanceOfPerStage[msg.sender][_stage] += saleTokenAmt;

        emit BuySolFart(msg.sender, _token, amount, saleTokenAmt);
    }

    function participantsDetailsList(
        uint _from,
        uint _to
    ) external view returns (ParticipantDetails[] memory) {
        require(_from < _to, "_from should be less than _to");

        uint to = _to > totalParticipants ? totalParticipants : _to;
        uint from = _from > totalParticipants ? totalParticipants : _from;

        ParticipantDetails[]
            memory participantsDetails = new ParticipantDetails[](to - from);

        for (uint i = from; i < to; i += 1) {
            participantsDetails[i - from] = ParticipantDetails(
                participants[i],
                balanceOf[participants[i]]
            );
        }

        return participantsDetails;
    }

    function emergencyWithdraw(
        address _token,
        uint256 _amount
    ) external onlyOwner {
        if (_token == address(0)) {
            payable(owner()).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(owner(), _amount);
        }
    }

    // View functions for better integration
    function getSaleInfo() external view returns (
        uint256 _priceInUSD,
        uint256 _totalTokensforSale,
        uint256 _totalTokensSold,
        uint256 _totalUSDRaised,
        uint256 _totalParticipants,
        bool _saleStatus
    ) {
        return (
            priceInUSD,
            totalTokensforSale,
            totalTokensSold,
            totalUSDRaised,
            totalParticipants,
            saleStatus
        );
    }

    function getParticipantInfo(address _participant) external view returns (
        uint256 _totalPurchased,
        bool _exists
    ) {
        return (
            balanceOf[_participant],
            participantExists[_participant]
        );
    }
}