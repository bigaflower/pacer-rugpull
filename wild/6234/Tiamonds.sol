// SPDX-License-Identifier: MIT
pragma solidity =0.8.0;

// contracts/Utils/Address.sol

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// contracts/Utils/Context.sol

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// contracts/Utils/IERC20.sol

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// contracts/Utils/IERC721.sol

interface ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) external view returns (uint256 _balance);

    function ownerOf(uint256 _tokenId) external view returns (address _owner);

    function exists(uint256 _tokenId) external view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) external;

    function getApproved(uint256 _tokenId)
        external
        view
        returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;
}

// contracts/Utils/ReentrancyGuard.sol

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
// abstract contract ReentrancyGuard {
//     // Booleans are more expensive than uint256 or any type that takes up a full
//     // word because each write operation emits an extra SLOAD to first read the
//     // slot's contents, replace the bits taken up by the boolean, and then write
//     // back. This is the compiler's defense against contract upgrades and
//     // pointer aliasing, and it cannot be disabled.

//     // The values being non-zero value makes deployment a bit more expensive,
//     // but in exchange the refund on every call to nonReentrant will be lower in
//     // amount. Since refunds are capped to a percentage of the total
//     // transaction's gas, it is best to keep them low in cases like this one, to
//     // increase the likelihood of the full refund coming into effect.
//     uint256 private constant _NOT_ENTERED = 1;
//     uint256 private constant _ENTERED = 2;

//     uint256 private _status;

//     constructor() {
//         _status = _NOT_ENTERED;
//     }

//     /**
//      * @dev Prevents a contract from calling itself, directly or indirectly.
//      * Calling a `nonReentrant` function from another `nonReentrant`
//      * function is not supported. It is possible to prevent this from happening
//      * by making the `nonReentrant` function external, and making it call a
//      * `private` function that does the actual work.
//      */
//     modifier nonReentrant() {
//         // On the first call to nonReentrant, _notEntered will be true
//         require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

//         // Any calls to nonReentrant after this point will fail
//         _status = _ENTERED;

//         _;

//         // By storing the original value once again, a refund is triggered (see
//         // https://eips.ethereum.org/EIPS/eip-2200)
//         _status = _NOT_ENTERED;
//     }
// }

// New contract used for SaleContractV2
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// contracts/Utils/SafeMath.sol

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// contracts/Utils/Strings.sol

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// contracts/Utils/Counters.sol

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// contracts/Utils/Ownable.sol

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// contracts/LCXVestingToken.sol

contract LCXVestingToken is Ownable {
    using SafeMath for uint256;

    address private immutable LCX_TOKEN; // Contract Address of LCX Token
    address private SaleContract; // Contract Address of Sale Tiamond

    struct VestedToken {
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 releasedToken;
        uint256 totalToken;
        bool revoked;
    }

    // mapped with token id
    mapping(address => VestedToken) public vestedUser;

    modifier onlySaleContract(){
        require(SaleContract == _msgSender(), "Only Sale Contract can call");
        _;
    }

    event TokenReleased(address indexed account, uint256 amount);
    event VestingRevoked(address indexed account);
    event SetSaleContractAddress(address);

    constructor(address _lcxAddress){
        require(_lcxAddress != address(0), "Address should not be zero address");
        LCX_TOKEN = _lcxAddress;
    }

    function setSaleAddress(address _saleAddress) external onlyOwner {
        require(_saleAddress != address(0), "Must be an address");
        SaleContract = _saleAddress;
        emit SetSaleContractAddress(_saleAddress);
    }
    

    /**
     * @dev this will set the beneficiary with vesting
     * parameters provided
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vesting
     * @param duration In seconds of total vesting
     * @param startAt UNIX timestamp in seconds from where vesting will start
     */
    function setVesting(
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) external onlySaleContract returns (bool) {
        VestedToken storage vested = vestedUser[account];
        if (vested.start > 0) {
            require(vested.revoked, "Account vesting is still going on");
            uint256 unclaimedTokens = _vestedAmount(account).sub(
                vested.releasedToken
            );
            require(unclaimedTokens == 0, "Account vesting is still going on");
        }
        IERC20(LCX_TOKEN).transferFrom(_msgSender(), address(this), amount);
        _setVesting(account, amount, cliff, duration, startAt);
        return true;
    }

    function userDetails(address account)
        external
        view
        returns (uint256, uint256)
    {
        return (vestedUser[account].duration, vestedUser[account].totalToken);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
    function vestedToken(address account) external view returns (uint256) {
        return _vestedAmount(account);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
    function releasableToken(address account) external view returns (uint256) {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

    /**
     * @dev Internal function to set default vesting parameters
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vestin
     * @param duration In seconds of total vesting duration
     * @param startAt UNIX timestamp in seconds from where vesting will start
     *
     */
    function _setVesting(
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) internal {
        require(account != address(0), "Address should not be zero address");
        require(startAt >= block.timestamp, "Vesting should start after current block time");
        require(cliff <= duration, "Cliff should be less that duration");
        VestedToken storage vested = vestedUser[account];
        vested.cliff = cliff;
        vested.start = startAt;
        vested.duration = duration;
        vested.totalToken = amount;
        vested.releasedToken = 0;
        vested.revoked = false;
    }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * anyone can release their token
     */
    function releaseMyToken() external returns (bool) {
        releaseToken(msg.sender);
        return true;
    }

    /**
     * @notice Transfers vested tokens to the given account.
     * @param account address of the vested user
     */
    function releaseToken(address account) public {
        require(account != address(0), "Address should not be zero address");
        VestedToken storage vested = vestedUser[account];
        uint256 unreleasedToken = _releasableAmount(account); // total releasable token currently
        require(unreleasedToken > 0, "No unreleased tokens in vesting");
        vested.releasedToken = vested.releasedToken.add(unreleasedToken);
        IERC20(LCX_TOKEN).transfer(account, unreleasedToken);
        emit TokenReleased(account, unreleasedToken);
    }

    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
    function _releasableAmount(address account)
        internal
        view
        returns (uint256)
    {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

    /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
    function _vestedAmount(address account) internal view returns (uint256) {
        VestedToken storage vested = vestedUser[account];
        uint256 totalToken = vested.totalToken;
        if (block.timestamp < vested.start.add(vested.cliff)) {
            return 0;
        } else if (
            block.timestamp >= vested.start.add(vested.duration) ||
            vested.revoked
        ) {
            return totalToken;
        } else {
            uint256 numberOfPeriods = (block.timestamp.sub(vested.start)).div(
                vested.cliff
            );
            return
                totalToken.mul(numberOfPeriods.mul(vested.cliff)).div(
                    vested.duration
                );
        }
    }

    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param account address in which the vesting is revoked
     */
    function revoke(address account) external onlyOwner returns (bool) {
        VestedToken storage vested = vestedUser[account];
        require(!vested.revoked, "Already revoked");
        uint256 balance = vested.totalToken;
        uint256 vestedAmount = _vestedAmount(account);
        uint256 refund = balance.sub(vestedAmount);
        require(refund > 0, "Refund amount should be more than zero");
        vested.revoked = true;
        vested.totalToken = vestedAmount;
        IERC20(LCX_TOKEN).transfer(owner(), refund);
        emit VestingRevoked(account);
        return true;
    }
}

// contracts/TiaTokenVesting.sol

contract TiaTokenVesting is Ownable {
    using SafeMath for uint256;
   
    address private immutable TIATokenAddress; 
    ERC721Basic private TIAMONDAddress;
    
    struct VestedToken {
        uint256 tokenId;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 releasedToken;
        uint256 totalToken; 
    }

    // mapped with token id
    mapping(uint256 => VestedToken) public vestedTiamond;

    modifier onlyTiamondContract(){
        require(address(TIAMONDAddress) == _msgSender(), "Only Tiamond Contract can call");
        _;
    }

    event TokenReleased(address indexed account, uint256 amount);
    event VestingRevoked(address indexed account);
    event SetTiamondsAddress(address nftAddress);

    constructor(address _tiaAddress){
       require(_tiaAddress != address(0), "Address should not be zero address");
       TIATokenAddress = _tiaAddress;
    }

    function setTIAMONDAddress(address _nft) external onlyOwner {
        require(_nft != address(0), "Must be an address");
        TIAMONDAddress = ERC721Basic(_nft);
        emit SetTiamondsAddress(_nft);
    }
    
    /**
     * @dev this will set the beneficiary with vesting
     * parameters provided
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vesting
     * @param duration In seconds of total vesting
     * @param startAt UNIX timestamp in seconds from where vesting will start
     */
    function setVesting(
        uint256 _tokenId,
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) external onlyTiamondContract returns (bool) {
        VestedToken storage vested = vestedTiamond[_tokenId];
        require(vested.start == 0, "Already vested tokenId");
        IERC20(TIATokenAddress).transferFrom(_msgSender(), address(this), amount);
        _setVesting(_tokenId, account, amount, cliff, duration, startAt);
        return true;
    }

    function vestedToken(uint256 _tokenId) external view returns (uint256) {
        return _vestedAmount(_tokenId);
    }

    function releasableToken(uint256 _tokenId) external view returns (uint256) {
        return _vestedAmount(_tokenId).sub(vestedTiamond[_tokenId].releasedToken);
    }

    /**
     * @dev Internal function to set default vesting parameters
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vestin
     * @param duration In seconds of total vesting duration
     * @param startAt UNIX timestamp in seconds from where vesting will start
     */
    function _setVesting(
        uint256 _tokenId,
        address account,
        uint256 amount,
        uint256 cliff,
        uint256 duration,
        uint256 startAt
    ) internal {
        require(account != address(0), "Address should not be zero address");
        require(startAt >= block.timestamp, "Vesting should start after current block time");
        require(cliff <= duration, "Cliff should be less that duration");
        VestedToken storage vested = vestedTiamond[_tokenId];
        vested.tokenId = _tokenId;
        vested.cliff = cliff;
        vested.start = startAt;
        vested.duration = duration;
        vested.totalToken = amount;
        vested.releasedToken = 0; 
    }

    function releaseToken(uint256 _tokenId) external {
        address nftOwner = TIAMONDAddress.ownerOf(_tokenId);
        VestedToken storage vested = vestedTiamond[_tokenId];
        uint256 unreleasedToken = _releasableAmount(_tokenId); // total releasable token currently
        require(unreleasedToken > 0, "No unreleased tokens in vesting");
        vested.releasedToken = vested.releasedToken.add(unreleasedToken);
        IERC20(TIATokenAddress).transfer(nftOwner, unreleasedToken);
        emit TokenReleased(nftOwner, unreleasedToken);
    }

    function _releasableAmount(uint256 _tokenId)
        internal
        view
        returns (uint256)
    {
        return _vestedAmount(_tokenId).sub(vestedTiamond[_tokenId].releasedToken);
    }

    function _vestedAmount(uint256 _tokenId) internal view returns (uint256) {
        VestedToken storage vested = vestedTiamond[_tokenId];
        uint256 totalToken = vested.totalToken;
        if (block.timestamp < vested.start.add(vested.cliff)) {
            return 0;
        } else if (
            block.timestamp >= vested.start.add(vested.duration)
        ) {
            return totalToken;
        } else {
            uint256 numberOfPeriods = (block.timestamp.sub(vested.start)).div(
                vested.cliff
            );
            return
                totalToken.mul(numberOfPeriods.mul(vested.cliff)).div(
                    vested.duration
                );
        }
    }
}

// contracts/TIA.sol

// Inspired by https://reflect.finance/

 

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract TIA is Context, IERC20, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    struct Fees {
        uint256 reflectFee;
        uint256 rebalanceFee;
        uint256 burnFee;
    }

    address private TiamondsAddress;
    address private immutable LCX; 

    IUniswapV2Router02 public immutable UniswapV2Router;
    // IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    address private constant deadWallet = 0x000000000000000000000000000000000000dEaD;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1.01e18;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private constant _name = "Tia Token";
    string private constant _symbol = "TIA";
    uint8 private constant _decimals = 9;

    uint256 private _reflectionFee = 50;
    uint256 private _rebalancingFee = 25;
    uint256 private _burningFee = 25;

    event RebalanceAndBurn(uint256, uint256, uint256);
    event SetTiamondsAddress(address);
    event ApproveTiamondsAddress(address, address, uint256);
    event ExcludeAccount(address);
    event IncludeAccount(address);
    event ChangeReflectionFee(uint256);
    event ChangeReBalancingFee(uint256);
    event ChangeBurnFee(uint256);
    event ExcludeFromFee(address);
    event IncludeInFee(address);

    constructor(address _lcxAddress, address _uniswapV2Address) {
        require(_lcxAddress != address(0), "Address should not be zero address");
        require(_uniswapV2Address != address(0), "Address should not be zero address");
        LCX = _lcxAddress;
        UniswapV2Router = IUniswapV2Router02(_uniswapV2Address);
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_uniswapV2Address] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {   
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function setTiamondsAddress(address _tiamonds) external onlyOwner {
        require(_tiamonds != address(0), "Address should not be zero address");
        TiamondsAddress = address(_tiamonds);
        emit SetTiamondsAddress(_tiamonds);
    }

    function approveTiamondSC() external onlyOwner returns (bool) {
        _approve(msg.sender, TiamondsAddress, _tTotal);
        emit ApproveTiamondsAddress(msg.sender, TiamondsAddress, _tTotal);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function isExcluded(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
    }

    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
        emit ExcludeAccount(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
        emit IncludeAccount(account);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 currentReflectionFee = _reflectionFee;
        uint256 currentRebalancingFee = _rebalancingFee;
        uint256 currentBurningFee = _burningFee;
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _reflectionFee = 0;
            _rebalancingFee = 0;
            _burningFee = 0;
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            _reflectionFee = currentReflectionFee;
            _rebalancingFee = currentRebalancingFee;
            _burningFee = currentBurningFee;
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees,
            uint256 tTransferAmount,
            Fees memory tFees
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFees.reflectFee, tFees.reflectFee);
        _reBalanceFee(rFees.rebalanceFee, tFees.rebalanceFee);
        _burnFee(rFees.burnFee, tFees.burnFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees,
            uint256 tTransferAmount,
            Fees memory tFees
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFees.reflectFee, tFees.reflectFee);
        _reBalanceFee(rFees.rebalanceFee, tFees.rebalanceFee);
        _burnFee(rFees.burnFee, tFees.burnFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees,
            uint256 tTransferAmount,
            Fees memory tFees
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFees.reflectFee, tFees.reflectFee);
        _reBalanceFee(rFees.rebalanceFee, tFees.rebalanceFee);
        _burnFee(rFees.burnFee, tFees.burnFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees,
            uint256 tTransferAmount,
            Fees memory tFees
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _reflectFee(rFees.reflectFee, tFees.reflectFee);
        _reBalanceFee(rFees.rebalanceFee, tFees.rebalanceFee);
        _burnFee(rFees.burnFee, tFees.burnFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rReflectFee, uint256 tReflectFee) private {
        _rTotal = _rTotal.sub(rReflectFee);
        _tFeeTotal = _tFeeTotal.add(tReflectFee);
    }

    function _reBalanceFee(uint256 rRebalanceFee, uint256 tRebalanceFee)
        private
    {
        _rOwned[address(this)] = _rOwned[address(this)].add(rRebalanceFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tRebalanceFee);
    }

    function _burnFee(uint256 rBurnFee, uint256 tBurnFee) private {
        _rOwned[address(this)] = _rOwned[address(this)].add(rBurnFee);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tBurnFee);
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            Fees memory,
            uint256,
            Fees memory
        )
    {
        (uint256 tTransferAmount, Fees memory tFees) = _getTValues(tAmount);
        uint256 currentRate = _getRate();
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            Fees memory rFees
        ) = _getRValues(tAmount, tFees, currentRate);
        return (rAmount, rTransferAmount, rFees, tTransferAmount, tFees);
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (uint256, Fees memory)
    {
        Fees memory tFees;
        tFees.reflectFee = tAmount.mul(_reflectionFee).div(1000);
        tFees.rebalanceFee = tAmount.mul(_rebalancingFee).div(1000);
        tFees.burnFee = tAmount.mul(_burningFee).div(1000);
        uint256 tTransferAmount = tAmount
            .sub(tFees.reflectFee)
            .sub(tFees.rebalanceFee)
            .sub(tFees.burnFee);
        return (tTransferAmount, tFees);
    }

    function _getRValues(
        uint256 tAmount,
        Fees memory tFees,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            Fees memory
        )
    {
        Fees memory rFees;
        uint256 rAmount = tAmount.mul(currentRate);
        rFees.reflectFee = tFees.reflectFee.mul(currentRate);
        rFees.rebalanceFee = tFees.rebalanceFee.mul(currentRate);
        rFees.burnFee = tFees.burnFee.mul(currentRate);
        uint256 rTransferAmount = rAmount
            .sub(rFees.reflectFee)
            .sub(rFees.rebalanceFee)
            .sub(rFees.burnFee);
        return (rAmount, rTransferAmount, rFees);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function reflectionFee() external view returns (uint256) {
        return _reflectionFee;
    }

    function changeReflectionFee(uint256 _newFee)
        external
        onlyOwner
        returns (bool)
    {
        _reflectionFee = _newFee;
        emit ChangeReflectionFee(_newFee);
        return true;
    }

    function rebalancingFee() external view returns (uint256) {
        return _rebalancingFee;
    }

    function changeReBalancingFee(uint256 _newFee)
        external
        onlyOwner
        returns (bool)
    {
        _rebalancingFee = _newFee;
        emit ChangeReBalancingFee(_newFee);
        return true;
    }

    function burningFee() external view returns (uint256) {
        return _burningFee;
    }

    function changeBurnFee(uint256 _newFee) external onlyOwner returns (bool) {
        _burningFee = _newFee;
        emit ChangeBurnFee(_newFee);
        return true;
    }

    function excludeFromFee(address account) external onlyOwner returns (bool) {
        require(account != address(0), "ERC20: account is the zero address");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account);
        return true;
    }

    function includeInFee(address account) external onlyOwner returns (bool) {
        require(account != address(0), "ERC20: account is the zero address");
        _isExcludedFromFee[account] = false;
        emit IncludeInFee(account);
        return true;
    }

    function rebalanceAndBurn() external nonReentrant returns (bool) {
        uint256 balanceInContract = balanceOf(address(this));
        uint256 rebalanceAmount = balanceInContract.mul(
            _rebalancingFee).div(_rebalancingFee.add(_burningFee));
        uint256 burnAmount = balanceInContract.mul(
            _burningFee).div(_rebalancingFee.add(_burningFee));
        emit RebalanceAndBurn(balanceInContract, rebalanceAmount, burnAmount);
        _swap(rebalanceAmount);
        _burn(burnAmount);
        return true;
    }

    function _swap(uint256 rebalanceAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = LCX;
        _approve(address(this), address(UniswapV2Router), rebalanceAmount);
        UniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            rebalanceAmount,
            0, // Accept any amount
            path,
            owner(),
            block.timestamp
        );
    }

    function _burn(uint256 burnAmount) internal {
        _transfer(address(this), deadWallet, burnAmount);
        emit Transfer(address(this), deadWallet, burnAmount);
    }
}

// contracts/Tiamonds.sol

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
abstract contract IERC721 is IERC165 {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function approve(address to, uint256 tokenId) public virtual;

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public virtual;

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual;
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
abstract contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safeTransfer`. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes memory data
    ) public virtual returns (bytes4);
}

/**
 * @dev Implementation of the `IERC165` interface.
 *
 * Contracts may inherit from this and call `_registerInterface` to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See `IERC165.supportsInterface`.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See `IERC165.supportsInterface`.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) private _tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => Counters.Counter) private _ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor() {
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) public view override returns (uint256) {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );

        return _ownedTokensCount[owner].current();
    }

    /**
     * @dev Gets the owner of the specified token ID.
     * @param tokenId uint256 ID of the token to query the owner of
     * @return address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _tokenOwner[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );

        return owner;
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param to address to be approved for the given token ID
     * @param tokenId uint256 ID of the token to be approved
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 tokenId)
        public
        view
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf.
     * @param to operator address to set the approval
     * @param approved representing the status of the approval to be set
     */
    function setApprovalForAll(address to, bool approved) public override {
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner.
     * @param owner owner address which you want to query the approval of
     * @param operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address.
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
     * Requires the msg.sender to be the owner, approved, or operator.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

        _transferFrom(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg.sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether the specified token exists.
     * @param tokenId uint256 ID of the token to query the existence of
     * @return bool whether the token exists
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID.
     * @param spender address of the spender to query
     * @param tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     * is an operator of the owner, or is the owner of the token
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to The address that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal virtual {
        require(
            ownerOf(tokenId) == owner,
            "ERC721: burn of token that is not own"
        );

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(ownerOf(tokenId), tokenId);
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * This function is deprecated.
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!checkContract(address(this))) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(
            msg.sender,
            from,
            tokenId,
            _data
        );
        return (retval == _ERC721_RECEIVED);
    }

    function checkContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Private function to clear current approval of a given token ID.
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract IERC721Enumerable is IERC721 {
    function totalSupply() public view virtual returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view virtual returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token with optional enumeration extension logic
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
    using SafeMath for uint256;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Constructor function.
     */
    constructor() {
        // register the supported interface to conform to ERC721Enumerable via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner.
     * @param owner address owning the tokens list to be accessed
     * @param index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract.
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens.
     * @param index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        require(
            index < totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Internal function to transfer ownership of a given token ID to another address.
     * As opposed to transferFrom, this imposes no restrictions on msg.sender.
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function _transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

    /**
     * @dev Internal function to mint a new token.
     * Reverts if the given token ID already exists.
     * @param to address the beneficiary that will own the minted token
     * @param tokenId uint256 ID of the token to be minted
     */
    function _mint(address to, uint256 tokenId) internal override {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned
     */
    function _burn(address owner, uint256 tokenId) internal override {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
        // Since tokenId will be deleted, we can clear its slot in _ownedTokensIndex to trigger a gas refund
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

    /**
     * @dev Gets the list of token IDs of the requested owner.
     * @param owner address owning the tokens
     * @return uint256[] List of token IDs owned by the requested address
     */
    function _tokensOfOwner(address owner)
        internal
        view
        returns (uint256[] storage)
    {
        return _ownedTokens[owner];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the _ownedTokensIndex mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokens[from][_ownedTokens[from].length - 1];
        // _ownedTokens[from].length--;

        // Note that _ownedTokensIndex[tokenId] hasn't been cleared: it still points to the old slot (now occupied by
        // lastTokenId, or just over the end of the array if the token was the last one).
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        _allTokens.pop();
        _allTokensIndex[tokenId] = 0;
    }
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
abstract contract IERC721Metadata is IERC721 {
    function name() external view virtual returns (string memory);

    function symbol() external view virtual returns (string memory);

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        returns (string memory);
}

contract Tiamonds is ERC165, ERC721, IERC721Metadata, Ownable {
    // Token name
    string private constant _name = "Tiamonds";
    // Token symbol
    string private constant _symbol = "TIAMOND";
    // TIA token Contract Address
    address private immutable TIATokenAddress;
    // TIA Fund Manager Address
    address public immutable TIAFundAddress;
    // Number of Tia Token to be allocated per NFT
    uint256 public _allocatedTiaPerNFT = 1e15;
    // TIA Token Vesting Default Parameters
    uint256 public cliff = 60;
    uint256 public duration = 6e7;
    // NFT Proof URI
    string constant baseURI = "https://files.tiamonds.com/nft/";
    // Tia vesting
    address private immutable TiaTokenVestingContractAddress ;

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(uint256 => string) private _tokenURIs;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    event Mint(uint256, address);
    event ChangeAllocatedTiaPerNFT(uint256);
    event ChangeTIADefaultVestingParameter(uint256, uint256);

    /**
     * @dev Constructor function
     */
    constructor(address _tiaAddress, address _tiaFundAddress, address _tiaVestingSC) {
        require(_tiaAddress != address(0), "Address should not be zero address");
        require(_tiaVestingSC != address(0), "Address should not be zero address");
        require(_tiaFundAddress != address(0), "Address should not be zero address");
        TIATokenAddress = _tiaAddress;
        TiaTokenVestingContractAddress = _tiaVestingSC;
        TIAFundAddress = _tiaFundAddress;
        // register the supported interfaces to confirm to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function mint() external onlyOwner returns (uint256) {
        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        string memory tokenUri = string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
        _setTokenURI(tokenId, tokenUri);
        if(_allocatedTiaPerNFT > 0){
            TIA(TIATokenAddress).transferFrom(TIAFundAddress, address(this), _allocatedTiaPerNFT);
            TIA(TIATokenAddress).approve(TiaTokenVestingContractAddress, _allocatedTiaPerNFT);
            TiaTokenVesting(TiaTokenVestingContractAddress).setVesting( tokenId, msg.sender, _allocatedTiaPerNFT, cliff, duration, block.timestamp);
        }
        emit Mint(tokenId, msg.sender);
        return tokenId;
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external pure override returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Can be changed in the future by the owner if proposed in governance 
     */
    function changeAllocatedTiaPerNFT(uint256 _newAmount) external onlyOwner {
        _allocatedTiaPerNFT = _newAmount;
        emit ChangeAllocatedTiaPerNFT(_newAmount);
    }

    /**
     * @dev Can be changed in the future by the owner if proposed in governance 
     */
    function changeTIADefaultVestingParameter(uint256 _newCliff, uint256 _newDuration) external onlyOwner {
        cliff = _newCliff;
        duration = _newDuration;
        emit ChangeTIADefaultVestingParameter(_newCliff, _newDuration);
    }
}