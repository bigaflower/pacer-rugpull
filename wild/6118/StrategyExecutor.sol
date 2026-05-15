// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;










library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();

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

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount) {
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{ value: amount }("");
        if (!(success)) {
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage)
        internal
        returns (bytes memory)
    {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value)
        internal
        returns (bytes memory)
    {
        return functionCallWithValue(
            target, data, value, "Address: low-level call with value failed"
        );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value) {
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))) {
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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







interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}











library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(
            token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata =
            address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(
            returndata.length == 0 || abi.decode(returndata, (bool)),
            "SafeERC20: ERC20 operation did not succeed"
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool)))
            && address(token).code.length > 0;
    }
}







contract MainnetAuthAddresses {
    address internal constant ADMIN_VAULT_ADDR = 0xCCf3d848e08b94478Ed8f46fFead3008faF581fD;
    address internal constant DSGUARD_FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;
    address internal constant ADMIN_ADDR = 0x25eFA336886C74eA8E282ac466BdCd0199f85BB9; // USED IN ADMIN VAULT CONSTRUCTOR
    address internal constant PROXY_AUTH_ADDRESS = 0x149667b6FAe2c63D1B4317C716b0D0e4d3E2bD70;
    address internal constant MODULE_AUTH_ADDRESS = 0x7407974DDBF539e552F1d051e44573090912CC3D;
}







contract AuthHelper is MainnetAuthAddresses { }







interface IAdminVault {
    function owner() external view returns (address);
    function admin() external view returns (address);
    function changeOwner(address _owner) external;
    function changeAdmin(address _admin) external;
}











contract AdminAuth is AuthHelper {
    using SafeERC20 for IERC20;

    IAdminVault public constant adminVault = IAdminVault(ADMIN_VAULT_ADDR);

    error SenderNotOwner();
    error SenderNotAdmin();

    modifier onlyOwner() {
        if (adminVault.owner() != msg.sender) {
            revert SenderNotOwner();
        }
        _;
    }

    modifier onlyAdmin() {
        if (adminVault.admin() != msg.sender) {
            revert SenderNotAdmin();
        }
        _;
    }

    /// @notice withdraw stuck funds
    function withdrawStuckFunds(address _token, address _receiver, uint256 _amount)
        public
        onlyOwner
    {
        if (_token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            payable(_receiver).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_receiver, _amount);
        }
    }
}







contract MainnetCoreAddresses {
    address internal constant REGISTRY_ADDR = 0x287778F121F134C66212FB16c9b53eC991D32f5b;
    address internal constant DEFISAVER_LOGGER = 0xcE7a977Cac4a481bc84AC06b2Da0df614e621cf3;

    address internal constant PROXY_AUTH_ADDR = 0x149667b6FAe2c63D1B4317C716b0D0e4d3E2bD70;
    address internal constant MODULE_AUTH_ADDR = 0x7407974DDBF539e552F1d051e44573090912CC3D;

    address internal constant SUB_STORAGE_ADDR = 0x1612fc28Ee0AB882eC99842Cde0Fc77ff0691e90;
    address internal constant BUNDLE_STORAGE_ADDR = 0x223c6aDE533851Df03219f6E3D8B763Bd47f84cf;
    address internal constant STRATEGY_STORAGE_ADDR = 0xF52551F95ec4A2B4299DcC42fbbc576718Dbf933;

    address internal constant BYTES_TRANSIENT_STORAGE = 0xB3FE6f712c8B8c64CD2780ce714A36e7640DDf0f;
}







contract CoreHelper is MainnetCoreAddresses { }








contract BotAuth is AdminAuth {
    mapping(address => bool) public approvedCallers;

    /// @notice Checks if the caller is approved for the specific subscription
    /// @dev First param is subId but it's not used in this implementation
    /// @dev Currently auth callers are approved for all strategies
    /// @param _caller Address of the caller
    function isApproved(uint256, address _caller) public view returns (bool) {
        return approvedCallers[_caller];
    }

    /// @notice Adds a new bot address which will be able to call executeStrategy()
    /// @param _caller Bot address
    function addCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = true;
    }

    /// @notice Removes a bot address so it can't call executeStrategy()
    /// @param _caller Bot address
    function removeCaller(address _caller) public onlyOwner {
        approvedCallers[_caller] = false;
    }
}








contract StrategyModel {
    /// @dev Group of strategies bundled together so user can sub to multiple strategies at once
    /// @param creator Address of the user who created the bundle
    /// @param strategyIds Array of strategy ids stored in StrategyStorage
    struct StrategyBundle {
        address creator;
        uint64[] strategyIds;
    }

    /// @dev Template/Class which defines a Strategy
    /// @param name Name of the strategy useful for logging what strategy is executing
    /// @param creator Address of the user which created the strategy
    /// @param triggerIds Array of identifiers for trigger - bytes4(keccak256(TriggerName))
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    /// @param continuous If the action is repeated (continuos) or one time
    struct Strategy {
        string name;
        address creator;
        bytes4[] triggerIds;
        bytes4[] actionIds;
        uint8[][] paramMapping;
        bool continuous;
    }

    /// @dev List of actions grouped as a recipe
    /// @param name Name of the recipe useful for logging what recipe is executing
    /// @param callData Array of calldata inputs to each action
    /// @param subData Used only as part of strategy, subData injected from StrategySub.subData
    /// @param actionIds Array of identifiers for actions - bytes4(keccak256(ActionName))
    /// @param paramMapping Describes how inputs to functions are piped from return/subbed values
    struct Recipe {
        string name;
        bytes[] callData;
        bytes32[] subData;
        bytes4[] actionIds;
        uint8[][] paramMapping;
    }

    /// @dev Actual data of the sub we store on-chain
    /// @dev In order to save on gas we store a keccak256(StrategySub) and verify later on
    /// @param walletAddr Address of the users smart wallet/proxy
    /// @param isEnabled Toggle if the subscription is active
    /// @param strategySubHash Hash of the StrategySub data the user inputted
    struct StoredSubData {
        bytes20 walletAddr; // address but put in bytes20 for gas savings
        bool isEnabled;
        bytes32 strategySubHash;
    }

    /// @dev Instance of a strategy, user supplied data
    /// @param strategyOrBundleId Id of the strategy or bundle, depending on the isBundle bool
    /// @param isBundle If true the id points to bundle, if false points directly to strategyId
    /// @param triggerData User supplied data needed for checking trigger conditions
    /// @param subData User supplied data used in recipe
    struct StrategySub {
        uint64 strategyOrBundleId;
        bool isBundle;
        bytes[] triggerData;
        bytes32[] subData;
    }

    /// @dev Data needed when signing relay transaction
    /// @param maxTxCostInFeeToken Max tx cost user is willing to pay in fee token
    /// @param feeToken Address of the token user is willing to pay fee in
    /// @param tokenPriceInEth Price of the token in ETH
    /// @param deadline Deadline for the relay transaction to be executed
    /// @param shouldTakeFeeFromPosition Flag to indicate if fee should be taken from position, otherwise from EOA/wallet
    struct TxSaverSignedData {
        uint256 maxTxCostInFeeToken;
        address feeToken;
        uint256 tokenPriceInEth;
        uint256 deadline;
        bool shouldTakeFeeFromPosition;
    }
}







interface IAuth {
    ///@param _walletAddr Address of the user's wallet
    ///@param _recipeExecutorAddr Address of the recipe executor
    ///@param _callData Data to be executed by the recipe executor
    function callExecute(address _walletAddr, address _recipeExecutorAddr, bytes memory _callData)
        external
        payable;
}







interface IDFSRegistry {
    function getAddr(bytes4 _id) external view returns (address);

    function addNewContract(bytes32 _id, address _contractAddr, uint256 _waitPeriod) external;

    function startContractChange(bytes32 _id, address _newContractAddr) external;

    function approveContractChange(bytes32 _id) external;

    function cancelContractChange(bytes32 _id) external;

    function changeWaitPeriod(bytes32 _id, uint256 _newWaitPeriod) external;
}







interface IRecipeExecutor {
    function executeRecipe(StrategyModel.Recipe calldata _currRecipe) external payable;

    function executeRecipeFromTxSaver(
        StrategyModel.Recipe calldata _currRecipe,
        StrategyModel.TxSaverSignedData calldata _txSaverData
    ) external payable;

    function executeRecipeFromStrategy(
        uint256 _subId,
        bytes[] calldata _actionCallData,
        bytes[] calldata _triggerCallData,
        uint256 _strategyIndex,
        StrategyModel.StrategySub memory _sub
    ) external payable;

    function executeActionsFromFL(StrategyModel.Recipe calldata _currRecipe, bytes32 _flAmount)
        external
        payable;
}






library DFSIds {
    bytes4 internal constant RECIPE_EXECUTOR = bytes4(keccak256("RecipeExecutor"));
    bytes4 internal constant STRATEGY_EXECUTOR = bytes4(keccak256("StrategyExecutorID")); // Abstract, so support both L1 and L2
    bytes4 internal constant TX_SAVER_EXECUTOR = bytes4(keccak256("TxSaverExecutor"));
    bytes4 internal constant BOT_AUTH = bytes4(keccak256("BotAuth"));
    bytes4 internal constant BOT_AUTH_FOR_TX_SAVER = bytes4(keccak256("BotAuthForTxSaver"));
    bytes4 internal constant KYBER_SCALING_HELPER = bytes4(keccak256("KyberInputScalingHelper"));
    bytes4 internal constant LLAMALEND_SWAPPER = bytes4(keccak256("LlamaLendSwapper"));
    bytes4 internal constant CURVE_SWAPPER = bytes4(keccak256("CurveUsdSwapper"));
    bytes4 internal constant CURVE_TRANSIENT_SWAPPER =
        bytes4(keccak256("CurveUsdSwapperTransient"));
}







enum WalletType {
    DSPROXY,
    SAFE,
    DSAPROXY
}







interface IDSProxy {
    function execute(bytes memory _code, bytes memory _data)
        external
        payable
        returns (address, bytes32);

    function execute(address _target, bytes memory _data) external payable returns (bytes32);

    function setCache(address _cacheAddr) external payable returns (bool);

    function owner() external view returns (address);

    function guard() external view returns (address);
}







interface IDSProxyFactory {
    function isProxy(address _proxy) external view returns (bool);
    function build(address owner) external returns (IDSProxy proxy);
    function build() external returns (IDSProxy proxy);
}






interface IInstaList {
    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }

    struct AccountList {
        address prev;
        address next;
    }

    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }

    struct UserList {
        uint64 prev;
        uint64 next;
    }

    function accountAddr(uint64 _id) external view returns (address);
    function accountID(address _addr) external view returns (uint64);
    function accountLink(uint64 _id) external view returns (AccountLink memory);
    function accountList(uint64 _id, address _user) external view returns (AccountList memory);
    function userLink(address _user) external view returns (UserLink memory);
    function userList(address _user, uint64 _id) external view returns (UserList memory);
}







interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external;

    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) external payable returns (bool success);

    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Operation operation
    ) external returns (bool success);

    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures)
        external
        view;

    function checkNSignatures(
        address executor,
        bytes32 dataHash,
        bytes memory, /* data */
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function approveHash(bytes32 hashToApprove) external;

    function domainSeparator() external view returns (bytes32);

    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) external view returns (bytes32);

    function nonce() external view returns (uint256);

    function setFallbackHandler(address handler) external;

    function getOwners() external view returns (address[] memory);

    function isOwner(address owner) external view returns (bool);

    function getThreshold() external view returns (uint256);

    function enableModule(address module) external;

    function isModuleEnabled(address module) external view returns (bool);

    function disableModule(address prevModule, address module) external;

    function getModulesPaginated(address start, uint256 pageSize)
        external
        view
        returns (address[] memory array, address next);
}







contract MainnetDSAProxyFactoryAddresses {
    address internal constant DSA_LIST_ADDR = 0x4c8a1BEb8a87765788946D6B19C6C6355194AbEb;
}







contract DSAProxyFactoryHelper is MainnetDSAProxyFactoryAddresses { }







contract MainnetProxyFactoryAddresses {
    address internal constant PROXY_FACTORY_ADDR = 0xA26e15C895EFc0616177B7c1e7270A4C7D51C997;
}







contract DSProxyFactoryHelper is MainnetProxyFactoryAddresses { }














contract SmartWalletUtils is DSProxyFactoryHelper, DSAProxyFactoryHelper {
    /// @notice Determine the type of wallet an address represents
    function _getWalletType(address _wallet) internal view returns (WalletType) {
        if (_isDSProxy(_wallet)) {
            return WalletType.DSPROXY;
        }

        if (_isDSAProxy(_wallet)) {
            return WalletType.DSAPROXY;
        }

        // Otherwise, we assume we are in context of Safe
        return WalletType.SAFE;
    }

    /// @notice Check if the wallet is a DSProxy
    function _isDSProxy(address _wallet) internal view returns (bool) {
        return IDSProxyFactory(PROXY_FACTORY_ADDR).isProxy(_wallet);
    }

    /// @notice Check if the wallet is a DSA Proxy Account
    function _isDSAProxy(address _wallet) internal view returns (bool) {
        return IInstaList(DSA_LIST_ADDR).accountID(_wallet) != 0;
    }

    /// @notice Fetch the owner of the smart wallet or the wallet itself
    /// @dev For 1/1 Safe it returns the owner, otherwise it returns the wallet itself
    /// @param _wallet Address of the smart wallet
    /// @return Address of the owner or wallet
    function _fetchOwnerOrWallet(address _wallet) internal view returns (address) {
        if (_isDSProxy(_wallet)) return IDSProxy(_wallet).owner();

        // Otherwise, we assume we are in context of Safe
        address[] memory owners = ISafe(_wallet).getOwners();
        return owners.length == 1 ? owners[0] : _wallet;
    }
}
















abstract contract StrategyExecutorCommon is StrategyModel, AdminAuth, CoreHelper, SmartWalletUtils {
    IDFSRegistry private constant registry = IDFSRegistry(REGISTRY_ADDR);

    /// Caller must be authorized bot
    error BotNotApproved(address, uint256);
    /// Subscription must be enabled
    error SubNotEnabled(uint256);

    /// @notice Checks if msg.sender has auth, reverts if not
    /// @param _subId Id of the strategy
    function _checkCallerAuth(uint256 _subId) internal view returns (bool) {
        return BotAuth(registry.getAddr(DFSIds.BOT_AUTH)).isApproved(_subId, msg.sender);
    }

    /// @notice Calls auth contract which has the auth from the user wallet which will call RecipeExecutor
    /// @param _subId Strategy data we have in storage
    /// @param _actionsCallData All input data needed to execute actions
    /// @param _triggerCallData All input data needed to check triggers
    /// @param _strategyIndex Which strategy in a bundle, need to specify because when sub is part of a bundle
    /// @param _sub StrategySub struct needed because on-chain we store only the hash
    /// @param _userWallet Address of the user's wallet
    function _callActions(
        uint256 _subId,
        bytes[] calldata _actionsCallData,
        bytes[] calldata _triggerCallData,
        uint256 _strategyIndex,
        StrategySub memory _sub,
        address _userWallet
    ) internal {
        address authAddr = _isDSProxy(_userWallet) ? PROXY_AUTH_ADDR : MODULE_AUTH_ADDR;

        IAuth(authAddr).callExecute{ value: msg.value }(
            _userWallet,
            registry.getAddr(DFSIds.RECIPE_EXECUTOR),
            abi.encodeWithSelector(
                IRecipeExecutor.executeRecipeFromStrategy.selector,
                _subId,
                _actionsCallData,
                _triggerCallData,
                _strategyIndex,
                _sub
            )
        );
    }
}






interface ISubStorage {
    function subscribeToStrategy(StrategyModel.StrategySub memory _sub) external returns (uint256);
    function updateSubData(uint256 _subId, StrategyModel.StrategySub calldata _sub) external;
    function activateSub(uint256 _subId) external;
    function deactivateSub(uint256 _subId) external;
    function getSub(uint256 _subId) external view returns (StrategyModel.StoredSubData memory);
    function getSubsCount() external view returns (uint256);
}









contract StrategyExecutor is StrategyExecutorCommon {
    /// Subscription data hash must match stored subData hash
    error SubDatHashMismatch(uint256, bytes32, bytes32);

    /// @notice Checks all the triggers and executes actions
    /// @dev Only authorized callers can execute it
    /// @param _subId Id of the subscription
    /// @param _strategyIndex Which strategy in a bundle, need to specify because when sub is part of a bundle
    /// @param _triggerCallData All input data needed to execute triggers
    /// @param _actionsCallData All input data needed to execute actions
    /// @param _sub StrategySub struct needed because on-chain we store only the hash
    function executeStrategy(
        uint256 _subId,
        uint256 _strategyIndex,
        bytes[] calldata _triggerCallData,
        bytes[] calldata _actionsCallData,
        StrategySub memory _sub
    ) external {
        // check bot auth
        if (!_checkCallerAuth(_subId)) {
            revert BotNotApproved(msg.sender, _subId);
        }

        StoredSubData memory storedSubData = ISubStorage(SUB_STORAGE_ADDR).getSub(_subId);

        bytes32 subDataHash = keccak256(abi.encode(_sub));

        // data sent from the caller must match the stored hash of the data
        if (subDataHash != storedSubData.strategySubHash) {
            revert SubDatHashMismatch(_subId, subDataHash, storedSubData.strategySubHash);
        }

        // subscription must be enabled
        if (!storedSubData.isEnabled) {
            revert SubNotEnabled(_subId);
        }

        // execute actions
        _callActions(
            _subId,
            _actionsCallData,
            _triggerCallData,
            _strategyIndex,
            _sub,
            address(storedSubData.walletAddr)
        );
    }
}
