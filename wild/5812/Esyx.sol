/* 
$ESYX - Automatic solutions for YOU 


Website: https://www.esyx.io/
Twitter: https://x.com/esyx_io
Telegram: https://t.me/esyx_portal
*/

pragma solidity 0.8.25;

// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    event Transfer(address indexed from, address indexed to, uint256 value);
}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _symbol;
    string private _name;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

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
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(
        bytes memory returndata,
        string memory errorMessage
    ) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }
}

interface IDexFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IDexRouter {
    function WETH() external pure returns (address);

    function factory() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

contract ESYX is ERC20, Ownable {
    bool public tradingAllowed;
    uint24 public sellTax;
    uint256 public maxWallet;
    uint24 public buyTax;

    mapping(address => bool) public feeExemption;
    mapping(address => bool) public limitExemption;
    mapping(address => bool) public isAMMPair;

    // phase 1
    uint24 public sellPhase1Tax = 2500; // 25%
    uint128 public maxWalletPhase1;
    bool public step1Activated;
    uint24 public buyPhase1Tax = 2500; // 25%

    // phase 2
    uint128 public maxWalletPhase2;
    uint24 public buyPhase2Tax = 2000; // 20%
    bool public step2Activated;
    uint24 public sellPhase2Tax = 2000; // 20%

    // phase 3
    uint24 public sellPhase3Tax = 1000; // 10%
    bool public step3Activated;
    uint24 public buyPhase3Tax = 1000; // 10%
    uint128 public maxWalletPhase3;

    // phase 4
    uint24 public sellPhaseFinal = 500; // 5%
    uint128 public maxWalletStepFinal;
    uint24 public buyPhaseFinal = 500; // 5%

    bool public limitsInPlace = true;

    uint256 public lastSwapBlock;
    mapping(address => uint256) private _holderLastTransferBlock;

    address public immutable WETH;
    IDexRouter public immutable dexRouter;
    address public immutable lpPair;
    uint256 public immutable minTokensToSwap;

    bool public isDynamicTax = true;
    uint256 public launchTimestamp;
    uint64 public constant FEE_DIVISOR = 10000;

    bool public transferDelayEnabled = false;

    address public devAddress = 0x74cca5dF944c17f4282B7bD3634829eaf262fD14;
    address public mktAddress =
        0x4eab3497D44610dC80327B320dEBAa63a5C4fa74;

    constructor() ERC20("ESYX", "ESYX") {
        uint256 _totalSupply = 100_000_000 * 1e18; // 100M
        _mint(address(msg.sender), _totalSupply);

        dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = dexRouter.WETH();
        lpPair = IDexFactory(dexRouter.factory()).createPair(
            address(this),
            WETH
        );

        minTokensToSwap = (totalSupply() * 50) / 100000;
        isAMMPair[lpPair] = true;

        feeExemption[address(0xdead)] = true;
        feeExemption[msg.sender] = true;
        feeExemption[address(dexRouter)] = true;
        feeExemption[address(this)] = true;

        limitExemption[msg.sender] = true;
        limitExemption[address(0xdead)] = true;
        limitExemption[lpPair] = true;
        limitExemption[address(this)] = true;

        maxWalletPhase1 = 500_000 * 1e18; // 0.5% f 100M total supply
        maxWalletPhase2 = 1_000_000 * 1e18; // 1% of 100M total supply
        maxWalletPhase3 = 1_500_000 * 1e18; // 1.5% of 100M total supply
        maxWalletStepFinal = 2_000_000 * 1e18; // 2% of 100M total supply

        _approve(address(msg.sender), address(dexRouter), totalSupply());
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (!feeExemption[from] && !feeExemption[to]) {
            require(tradingAllowed, "Trading not active");
            amount -= manageTax(from, to, amount);
            checkTxLimits(from, to, amount);
        }

        super._transfer(from, to, amount);
    }

    function checkTxLimits(address from, address to, uint256 amount) internal {
        if (limitsInPlace) {
            bool exFromLimitsTo = limitExemption[to];
            uint256 balanceOfTo = balanceOf(to);

            // buy
            if (isAMMPair[from] && !exFromLimitsTo) {
                require(amount + balanceOfTo <= maxWallet, "Max Wallet");
            } else if (!exFromLimitsTo) {
                require(amount + balanceOfTo <= maxWallet, "Max Wallet");
            }

            if (transferDelayEnabled) {
                if (to != address(dexRouter) && to != address(lpPair)) {
                    require(
                        _holderLastTransferBlock[tx.origin] < block.number,
                        "Transfer Delay"
                    );
                    if (from == address(lpPair)) {
                        require(
                            tx.origin == to,
                            "no buying to external wallets yet"
                        );
                    }
                    _holderLastTransferBlock[to] = block.number;
                    _holderLastTransferBlock[tx.origin] = block.number;
                }
            }
        }
    }

    function swapTokensForETH(uint256 tokenAmt) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmt,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function manageTax(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256) {
        if (
            balanceOf(address(this)) >= minTokensToSwap &&
            !isAMMPair[from] &&
            lastSwapBlock + 1 <= block.number
        ) {
            convertTax();
        }

        if (isDynamicTax) {
            setTaxesInternally();
        }

        uint128 tax = 0;

        uint24 taxes;

        if (isAMMPair[to]) {
            taxes = sellTax;
        } else if (isAMMPair[from]) {
            taxes = buyTax;
        }

        if (taxes > 0) {
            tax = uint128((amount * taxes) / FEE_DIVISOR);
            super._transfer(from, address(this), tax);
        }

        return tax;
    }

    function openTrading() external onlyOwner {
        require(!tradingAllowed, "Trading already enabled");
        tradingAllowed = true;
        maxWallet = maxWalletPhase1;
        sellTax = sellPhase1Tax;
        buyTax = buyPhase1Tax;
        transferDelayEnabled = true;
        launchTimestamp = block.timestamp;
        step1Activated = true;
    }

    function convertTax() private {
        uint256 contractBalance = balanceOf(address(this));

        lastSwapBlock = block.number;

        if (contractBalance > minTokensToSwap * 10) {
            contractBalance = minTokensToSwap * 10;
        }

        if (contractBalance > 0) {
            swapTokensForETH(contractBalance);

            uint256 ethBalance = address(this).balance;

            bool success;

            if (mktAddress != address(0)) {
                uint256 valueForMarketing = ethBalance / 2;
                (success, ) = mktAddress.call{value: valueForMarketing}(
                    ""
                );
                ethBalance -= valueForMarketing;
            }

            (success, ) = devAddress.call{value: ethBalance}("");
        }
    }

    function setTaxesInternally() internal {
        uint256 currentTimestamp = block.timestamp;

        uint256 timeSinceLaunch;

        if (currentTimestamp >= launchTimestamp) {
            timeSinceLaunch = currentTimestamp - launchTimestamp;
        }

        if (transferDelayEnabled && timeSinceLaunch >= 1 minutes) {
            transferDelayEnabled = false;
        }

        if (timeSinceLaunch >= 20 minutes) {
            isDynamicTax = false;
            buyTax = buyPhaseFinal;
            sellTax = sellPhaseFinal;
            maxWallet = maxWalletStepFinal;
        } else if (timeSinceLaunch >= 10 minutes) {
            if (!step3Activated) {
                buyTax = buyPhase3Tax;
                sellTax = sellPhase3Tax;
                maxWallet = maxWalletPhase3;
                step3Activated = true;
            }
        } else if (timeSinceLaunch >= 5 minutes) {
            if (!step2Activated) {
                buyTax = buyPhase2Tax;
                sellTax = sellPhase2Tax;
                maxWallet = maxWalletPhase2;
                step2Activated = true;
            }
        }
    }

    function updateTax(uint24 _buyTax, uint24 _sellTax) external onlyOwner {
        require(
            _buyTax < buyTax || _buyTax <= 500,
            "Cannot increase buy tax over 5%"
        );
        require(
            _sellTax < sellTax || _sellTax <= 500,
            "Cannot increase buy tax over 5%"
        );
        buyTax = _buyTax;
        sellTax = _sellTax;
    }

    function removeLimits() external onlyOwner {
        limitsInPlace = false;
    }

    receive() external payable {}

    // private
    function _simulateTaxBuckets(
        uint256 totalTokens,
        uint24 buyTaxBps,
        uint24 sellTaxBps
    ) private pure returns (uint256) {
        uint256 bucketA = (totalTokens * buyTaxBps) / 10000 / 3;
        uint256 bucketB = ((totalTokens * (buyTaxBps + sellTaxBps)) / 2) /
            10000 /
            3;
        uint256 bucketC = totalTokens - bucketA - bucketB;
        return bucketA * 3 + bucketB * 2 + bucketC;
    }

    function _computeSlippageAdjustedAmount(
        uint256 amountIn,
        uint256 slippageBps,
        uint256 liquidityFactor
    ) private pure returns (uint256) {
        if (liquidityFactor == 0) return amountIn;
        uint256 base = (amountIn * (10000 - slippageBps)) / 10000;
        return (base * liquidityFactor) / (liquidityFactor + 1);
    }

    function _computeSwapDistribution(
        uint256 ethAmount,
        uint8 marketingSharePercent,
        uint8 devSharePercent
    ) private pure returns (uint256) {
        uint256 m = (ethAmount * marketingSharePercent) / 100;
        uint256 d = (ethAmount * devSharePercent) / 100;
        return ethAmount - m - d;
    }

    function _virtualBurnEstimate(
        uint256 tokens,
        uint8 rounds
    ) private pure returns (uint256) {
        uint256 t = tokens;
        for (uint8 i = 0; i < rounds; i++) {
            t = t - (t / (10 + i));
        }
        return t;
    }

    function _complexFeeHash(
        address token,
        uint24 buyBps,
        uint24 sellBps
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(token, buyBps, sellBps));
    }

    function _tokenDilutionSimulation(
        uint256 holders,
        uint256 avgBalance
    ) private pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < 5; i++) {
            total += holders * (avgBalance + i * 123);
        }
        return total / 5;
    }
}
