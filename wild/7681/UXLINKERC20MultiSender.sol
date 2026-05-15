// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/updao/UPDAOERC20MultiSender.sol


pragma solidity ^0.8.18;


contract UXLINKERC20MultiSender  {

    string public toolName;

    /// @notice Addresses of super operators
    mapping(address => bool) public superOperators;

    // set the withdrawal fee to 10000/1000000 = 1%.
    uint256 public withdrawalFee = 10000;

    /// Events
    /// @notice Emitted after super operator is updated
    event AuthorizedOperator(address indexed operator, address indexed holder);

    /// @notice Emitted after super operator is updated
    event RevokedOperator(address indexed operator, address indexed holder);

    // ========= Internal Safe ERC20 Helpers (no OZ dependency) =========
    function _safeTransfer(address token, address to, uint256 amount) internal {
        // IERC20(token).transfer(to, amount)
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, amount));
        require(ok, "TRANSFER_CALL_FAILED");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "TRANSFER_FAILED");
        }
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        // IERC20(token).transferFrom(from, to, amount)
        (bool ok, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount));
        require(ok, "TRANSFERFROM_CALL_FAILED");
        if (data.length > 0) {
            require(abi.decode(data, (bool)), "TRANSFERFROM_FAILED");
        }
    }

    /// @notice Requires sender to be contract super operator
    modifier isSuperOperator() {
        // Ensure sender is super operator
        require(superOperators[msg.sender], "Not super operator");
        _;
    }
    
    /// @notice 
    constructor() {
        toolName = "UXLINKERC20MultiSender";
        superOperators[msg.sender] = true;
    }
   

    function allowance(address _token) view public returns (uint){
        IERC20 token = IERC20(_token);
        return token.allowance(msg.sender,address(this));
    }


    function batch_transfer(address _token, address[] memory to, uint256 amount) public {
        require(_token != address(0), "TOKEN_ZERO");
        uint256 len = to.length;
        require(len > 0, "EMPTY_LIST");
        require(amount > 0, "AMOUNT_ZERO");

        uint256 fee = calculateWithdrawalFee(amount);
        uint256 amountAfterFee = amount - fee;
        for (uint256 i = 0; i < len; i++) {
            _safeTransferFrom(_token, msg.sender, to[i], amountAfterFee);
        }

        if (fee > 0) {
            fee = fee * len;
            _safeTransferFrom(_token, msg.sender, address(this), fee);
        }
    }

    function batch_transfer_diffent_amount(address _token, address[] memory to, uint[] memory amount) public {
        require(_token != address(0), "TOKEN_ZERO");
        uint256 len = to.length;
        require(len > 0, "EMPTY_LIST");
        require(len == amount.length, "LENGTH_MISMATCH");

        uint256 totalFee = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 fee = calculateWithdrawalFee(amount[i]);
            uint256 amountAfterFee = amount[i] - fee;

            totalFee += fee;
            _safeTransferFrom(_token, msg.sender, to[i], amountAfterFee);
        }

        if (totalFee > 0) {
            _safeTransferFrom(_token, msg.sender, address(this), totalFee);
        }
    }

    function batch_transfer_different_amount(address _token, address[] memory to, uint[] memory amount) public {
        batch_transfer_diffent_amount(_token, to, amount);
    }

    /// @notice Able to receive ETH
    receive() external payable {}

    function setWithdrawalFee(uint256 _fee) external isSuperOperator {
        require(_fee <= 1000000, "withdrawalFee must be less than or equal to 1000000");
        withdrawalFee = _fee;
    }

    function calculateWithdrawalFee(uint256 amount) internal view returns (uint256) {
        return (amount * withdrawalFee) / 1000000;
    }

    /**
     * Allow withdraw of ETH tokens from the contract
     */
    function withdrawETH(address recipient) public isSuperOperator {
        uint256 balance = address(this).balance;
        require(balance > 0, "balance is zero");
        payable(recipient).transfer(balance);
    }

    function withdrawStuckToken(address _token, address _to) external isSuperOperator {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        require(_contractBalance > 0, "_contractBalance is zero");
        _safeTransfer(_token, _to, _contractBalance);
    }

     /// @notice Allows super operator to update super operator
    function authorizeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = true;
        emit AuthorizedOperator(_operator, msg.sender);
    }

    /// @notice Allows super operator to update super operator
    function revokeOperator(address _operator) external isSuperOperator {
        superOperators[_operator] = false;
        emit RevokedOperator(_operator, msg.sender);
    }

}