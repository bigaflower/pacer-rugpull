// File: contracts/Contracts/interfaces/IERC20.sol


pragma solidity ^0.8.20;

interface IERC20 {
    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// File: contracts/Contracts/interfaces/IUniswapV2Factory.sol


pragma solidity ^0.8.20;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// File: contracts/Contracts/interfaces/IUniswapV2Router02.sol


pragma solidity ^0.8.20;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 tokenAmount,
        uint256 minETHAmount,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 tokenDesired,
        uint256 tokenMin,
        uint256 ethMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 tokenAmount,
            uint256 ethAmount,
            uint256 liquidity
        );
}

// File: contracts/Contracts/utils/Context.sol


pragma solidity ^0.8.20;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// File: contracts/Contracts/access/Ownable.sol


pragma solidity ^0.8.20;


contract Ownable is Context {
    address private _contractOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _contractOwner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _contractOwner;
    }

    modifier onlyOwner() {
        require(_contractOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _updateOwnership(newOwner);
    }

    function _updateOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contractOwner, newOwner);
        _contractOwner = newOwner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_contractOwner, address(0));
        _contractOwner = address(0);
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v5.1.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.20;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS
    }

    /**
     * @dev The signature derives the `address(0)`.
     */
    error ECDSAInvalidSignature();

    /**
     * @dev The signature has an invalid length.
     */
    error ECDSAInvalidSignatureLength(uint256 length);

    /**
     * @dev The signature has an S value that is in the upper half order.
     */
    error ECDSAInvalidSignatureS(bytes32 s);

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with `signature` or an error. This will not
     * return address(0) without also returning an error description. Errors are documented using an enum (error type)
     * and a bytes32 providing additional information about the error.
     *
     * If no error is returned, then the address can be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     */
    function tryRecover(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address recovered, RecoverError err, bytes32 errArg) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly ("memory-safe") {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength, bytes32(signature.length));
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM precompile allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {MessageHashUtils-toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, signature);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[ERC-2098 short signatures]
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address recovered, RecoverError err, bytes32 errArg) {
        unchecked {
            bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
            // We do not check for an overflow here since the shift operation results in 0 or 1.
            uint8 v = uint8((uint256(vs) >> 255) + 27);
            return tryRecover(hash, v, r, s);
        }
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, r, vs);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address recovered, RecoverError err, bytes32 errArg) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS, s);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature, bytes32(0));
        }

        return (signer, RecoverError.NoError, bytes32(0));
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        (address recovered, RecoverError error, bytes32 errorArg) = tryRecover(hash, v, r, s);
        _throwError(error, errorArg);
        return recovered;
    }

    /**
     * @dev Optionally reverts with the corresponding custom error according to the `error` argument provided.
     */
    function _throwError(RecoverError error, bytes32 errorArg) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert ECDSAInvalidSignature();
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert ECDSAInvalidSignatureLength(uint256(errorArg));
        } else if (error == RecoverError.InvalidSignatureS) {
            revert ECDSAInvalidSignatureS(errorArg);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol


// OpenZeppelin Contracts (last updated v5.4.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity >=0.4.16;

/**
 * @dev Interface of the ERC-20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[ERC-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC-20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     *
     * CAUTION: See Security Considerations above.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

// EIP-2612 is Final as of 2022-11-01. This file is deprecated.


// File: contracts/Contracts/MechaOS.sol


/*The decentralized OS where robots work, earn, and prove their actions on-chain, powered by $MECHA.
/*X: https://x.com/usemecha
/*TG: https://t.me/usemecha 
/*Web: https://mechaos.io
 */

pragma solidity ^0.8.20;









/** TOKEN */
contract MechaOS is Context, IERC20, Ownable, IERC20Permit {
    // --- Token Metadata ---
    string private constant _tokenName = "MechaOS";
    string private constant _tokenSymbol = "MECHA";
    uint8 private constant _tokenDecimals = 18;
    uint256 private constant _totalSupply = 100000000 * 10 ** _tokenDecimals;

    // --- ERC20 Storage ---
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _excludedAccounts;

    // --- Swap & Fee Config ---
    uint256 private _minSwapTokens = 50000 * 10 ** _tokenDecimals;
    uint256 private _maxSwapTokens = 500000 * 10 ** _tokenDecimals;
    uint256 private _lastSwapBlock;
    uint256 private _swapCount;
    uint256 public buyFeeRate;
    uint256 public sellFeeRate;
    uint256 public maxTxValue = 1555000 * 10 ** _tokenDecimals;
    uint256 public maxWalletHoldings = 1555000 * 10 ** _tokenDecimals;
    uint256 private _launchBlock;

    // --- DEX Integration ---
    IUniswapV2Router02 private _uniswapV2Router;
    address public uniswapV2Pair;

    // --- Project Wallets ---
    address payable ProjectWallet;
    address payable TreasuryWallet;
    address payable DevelopmentWallet;

    // --- Flags ---
    bool private _isTradingActive = false;

    /** START OF EIP2612/EIP712 VARS */

    using Counters for Counters.Counter;
    mapping(address => Counters.Counter) private _nonces;

    // Cache the domain separator as an immutable value, but also store the chain id it corresponds to
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /** END OF EIP2612/EIP712 VARS */

    // --- Events ---
    event FeeUpdated(uint256 newBuyFee, uint256 newSellFee);
    event SwapThresholdsUpdated(uint256 minSwap, uint256 maxSwap);
    event AccountExclusionUpdated(address account, uint256 value);
    event LimitsDisabled();
    event EthDistributed(uint256 developmentAmount, uint256 projectAmount);

    /** CONSTRUCTOR */

    constructor(
        uint256 initialFee,
        address payable _projectWallet,
        address payable _treasuryWallet,
        address payable _developmentWallet
    ) {
        //**SET UP EIP712*/
        bytes32 hashedName = keccak256(bytes(_tokenName));
        bytes32 hashedVersion = keccak256(bytes("1"));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                typeHash,
                hashedName,
                hashedVersion,
                block.chainid,
                address(this)
            )
        );
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
        //**END EIP712*/

        // --- Fee Init ---
        buyFeeRate = initialFee;
        sellFeeRate = initialFee;

        // --- Wallet Assignments ---
        ProjectWallet = _projectWallet;
        TreasuryWallet = _treasuryWallet;
        DevelopmentWallet = _developmentWallet;

        // --- Token distribution ---
        uint256 liquidityTokens = (_totalSupply * 70) / 100;
        uint256 treasuryTokens = (_totalSupply * 30) / 100;

        _balances[address(this)] = liquidityTokens;
        _balances[TreasuryWallet] = treasuryTokens;

        // --- Initial Exclusions ---
        _excludedAccounts[msg.sender] = 1;
        _excludedAccounts[address(this)] = 1;
        _excludedAccounts[ProjectWallet] = 1;
        _excludedAccounts[TreasuryWallet] = 1;
        _excludedAccounts[DevelopmentWallet] = 1;

        // --- Swap State Init ---
        _lastSwapBlock = 0;
        _swapCount = 0;

        // --- Initial Events ---
        emit Transfer(address(0), address(this), liquidityTokens);
        emit Transfer(address(0), TreasuryWallet, treasuryTokens);
        emit FeeUpdated(buyFeeRate, sellFeeRate);

        emit AccountExclusionUpdated(msg.sender, 1);
        emit AccountExclusionUpdated(address(this), 1);
        emit AccountExclusionUpdated(ProjectWallet, 1);
        emit AccountExclusionUpdated(TreasuryWallet, 1);
        emit AccountExclusionUpdated(DevelopmentWallet, 1);
    }

    // --- ERC20 Functions ---
    function name() public pure returns (string memory) {
        return _tokenName;
    }

    function symbol() public pure returns (string memory) {
        return _tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return _tokenDecimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _totalSupply;
    }

    function getFeeRates()
        external
        view
        returns (uint256 buyTax, uint256 sellTax)
    {
        buyTax = buyFeeRate;
        sellTax = sellFeeRate;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _executeTransfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _setAllowance(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _executeTransfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _setAllowance(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function _setAllowance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // --- Launch Functions --- 
    function startTrading() external onlyOwner {
        require(!_isTradingActive, "Trading is already enabled");
        _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        _setAllowance(address(this), address(_uniswapV2Router), _totalSupply);

        _uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );

        IERC20(uniswapV2Pair).approve(
            address(_uniswapV2Router),
            type(uint256).max
        );
        _isTradingActive = true;
        _launchBlock = block.number;
    }

    // --- Exclude Accounts From Fees ---
    function setExcludedAccount(
        address account,
        uint256 value
    ) external onlyOwner {
        _excludedAccounts[account] = value;

        emit AccountExclusionUpdated(account, value);
    }

    // --- Permanently disables TX & Wallet limits (use once project is stable) ---
    function disableLimits() external onlyOwner {
        maxTxValue = _totalSupply;
        maxWalletHoldings = _totalSupply;

        emit LimitsDisabled();
    }

    // --- Fee Controls ---
    function adjustTaxRates(
        uint256 newBuyTaxRate,
        uint256 newSellTaxRate
    ) external onlyOwner {
        require(newBuyTaxRate <= 25, "Buy tax rate cannot exceed 25%");
        require(newSellTaxRate <= 25, "Sell tax rate cannot exceed 25%");

        buyFeeRate = newBuyTaxRate;
        sellFeeRate = newSellTaxRate;

        emit FeeUpdated(newBuyTaxRate, newSellTaxRate);
    }

    // --- Swapback Settings ---

    function setSwapThresholds(
        uint256 minTokens,
        uint256 maxTokens
    ) external onlyOwner {
        uint256 minFloor = 50_000 * 10 ** _tokenDecimals;
        uint256 maxFloor = 100_000 * 10 ** _tokenDecimals;

        require(minTokens >= minFloor, "Min must be >= 50k tokens");
        require(maxTokens >= maxFloor, "Max must be >= 100k tokens");
        require(maxTokens > minTokens, "Max must be > Min");

        _minSwapTokens = minTokens;
        _maxSwapTokens = maxTokens;

        emit SwapThresholdsUpdated(minTokens, maxTokens);
    }

    function _executeTokenTransfer(
        address from,
        address to,
        uint256 amount,
        uint256 taxRate
    ) private {
        uint256 taxAmount = (amount * taxRate) / 100;
        uint256 transferAmount = amount - taxAmount;

        _balances[from] -= amount;
        _balances[to] += transferAmount;
        _balances[address(this)] += taxAmount;

        emit Transfer(from, to, transferAmount);
    }

    // --- Core Transfer Logic (Taxes, Limits, Swapback) ---
    function _executeTransfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "ERC20: transfer amount must be greater than zero");

        uint256 taxRate = 0;

        if (_excludedAccounts[from] == 0 && _excludedAccounts[to] == 0) {
            require(_isTradingActive, "Trading is not enabled yet");
            require(
                amount <= maxTxValue,
                "Transaction amount exceeds the maximum limit"
            );

            if (to != uniswapV2Pair && to != address(0xdead)) {
                require(
                    balanceOf(to) + amount <= maxWalletHoldings,
                    "Recipient wallet exceeds the maximum limit"
                );
            }

            if (block.number < _launchBlock + 3) {
                taxRate = (from == uniswapV2Pair) ? 30 : 30;
            } else {
                if (from == uniswapV2Pair) {
                    taxRate = buyFeeRate;
                } else if (to == uniswapV2Pair) {
                    uint256 contractTokenBalance = balanceOf(address(this));

                    if (contractTokenBalance > _minSwapTokens) {
                        uint256 swapAmount = _maxSwapTokens;

                        if (contractTokenBalance < swapAmount) {
                            swapAmount = contractTokenBalance;
                        }

                        contractTokenBalance = swapAmount;
                        _exchangeTokensForEth(contractTokenBalance);
                    }
                    taxRate = sellFeeRate;
                }
            }
        }
        _executeTokenTransfer(from, to, amount, taxRate);
    }

    // --- Owner Recovery Controls ---
    function withdrawEth() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No ETH to withdraw");

        payable(owner()).transfer(amount);
    }

    function recoverTokens() external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        require(contractTokenBalance > 0, "No tokens to rescue");

        _executeTokenTransfer(address(this), owner(), contractTokenBalance, 0);
    }

    function executeManualSwap(uint256 percent) external onlyOwner {
        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 swapAmount = (percent * contractTokenBalance) / 100;
        _exchangeTokensForEth(swapAmount);
    }

    // --- Swapback: Convert Tokens to ETH & Distribute ---
    function _exchangeTokensForEth(uint256 tokenAmount) private {
        if (block.number == _lastSwapBlock) {
            require(_swapCount < 1, "Maximum swaps per block reached");
            _swapCount++;
        } else {
            _lastSwapBlock = block.number;
            _swapCount = 1;
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _uniswapV2Router.WETH();

        _setAllowance(address(this), address(_uniswapV2Router), tokenAmount);

        _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractEthBalance = address(this).balance;

        uint256 developmentShare = (contractEthBalance * 6) / 100;
        uint256 projectShare = contractEthBalance - developmentShare;

        DevelopmentWallet.transfer(developmentShare);
        ProjectWallet.transfer(projectShare);

        emit EthDistributed(developmentShare, projectShare);
    }

    /** START OF EIP2612/EIP712 FUNCTIONS */

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (
            address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID
        ) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return
                _buildDomainSeparator(
                    _TYPE_HASH,
                    _HASHED_NAME,
                    _HASHED_VERSION
                );
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    typeHash,
                    nameHash,
                    versionHash,
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(
        bytes32 structHash
    ) internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", _domainSeparatorV4(), structHash)
            );
    }

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev See {IERC20Permit-permit}.
     */

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                _useNonce(owner),
                deadline
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _setAllowance(owner, spender, value); 
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(
        address owner
    ) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(
        address owner
    ) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == type(IERC20Permit).interfaceId;
    }

    /** END OF EIP2612/EIP712 FUNCTIONS */

    receive() external payable {}
}