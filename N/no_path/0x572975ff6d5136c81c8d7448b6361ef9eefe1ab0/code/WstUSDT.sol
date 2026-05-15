// Sources flattened with hardhat v2.16.1 https://hardhat.org

// File contracts/interface/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    /**
     * @return the number of decimals for getting user representation of a token amount.
     */
    function decimals() external pure returns (uint8);

    /**
     * @return the name of the token.
     */
    function name() external pure returns (string memory);

    /**
     * @return the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external pure returns (string memory);

}


// File contracts/interface/IProxy.sol


pragma solidity ^0.8.18;

interface IProxy {
    function _acceptImplementation() external;
    function admin() external view returns (address);
}


// File contracts/AdminStorage.sol


pragma solidity ^0.8.18;

contract AdminStorage {
    /**
    * @notice Administrator for this contract
    */
    address public admin;

    /**
    * @notice Pending administrator for this contract
    */
    address public pendingAdmin;

    /**
    * @notice Active brains of this contract
    */
    address public implementation;

    /**
    * @notice Pending brains of this contract
    */
    address public pendingImplementation;
}


// File contracts/WstUSDTStorage.sol


pragma solidity ^0.8.18;

contract WstUSDTStorage is AdminStorage {

    mapping(address => uint256) internal balance;

    mapping(address => mapping(address => uint256)) internal allowances;

    uint256 internal _totalSupply;

}


// File contracts/WstUSDTG2.sol


pragma solidity ^0.8.18;



interface IStUSDT is IERC20 {

    function sharesOf(address _account) external view returns (uint256);

    function getSharesByUnderlying(uint256 _underlyingAmount) external view returns (uint256);

    function getUnderlyingByShares(uint256 _sharesAmount) external view returns (uint256);

    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);

}


contract WstUSDT is WstUSDTStorage, IERC20{

    IStUSDT public immutable stUSDT;

    // -------------------------------- constructor --------------------------------
    constructor (IStUSDT _stUSDT) {
        require(address(_stUSDT) != address(0), "ZERO_STUSDT_ADDRESS");
        stUSDT = _stUSDT;
    }

    // -------------------------------- trc20 functions --------------------------------
    function decimals() public pure returns (uint8) {
        return 18;
    }

    function name() external pure returns (string memory) {
        return "Wrapped Staked USDT";
    }

    function symbol() external pure returns (string memory) {
        return "wstUSDT";
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _account) public view returns (uint256) {
        return balance[_account];
    }

    function transfer(address _recipient, uint256 _amount) public  returns (bool)
    {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint256 _amount) public returns (bool)
    {
        _approve(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public returns (bool)
    {
        uint256 currentAllowance = allowances[_sender][msg.sender];
        require(currentAllowance > 0, "ZERO_ALLOWANCE");
        require(currentAllowance >= _amount, "TRANSFER_AMOUNT_EXCEEDS_ALLOWANCE");

        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, currentAllowance - _amount);
        return true;
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender] + _addedValue);
        return true;
    }

    function decreaseAllowance(address _spender, uint256 _subtractedValue) public returns (bool) {
        uint256 currentAllowance = allowances[msg.sender][_spender];
        require(currentAllowance >= _subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO");
        _approve(msg.sender, _spender, currentAllowance - _subtractedValue);
        return true;
    }

    function _transfer(address _sender, address _recipient, uint256 _amount) internal {
        require(_recipient != address(0), "TRANSFER_TO_ZERO_ADDRESS");
        uint256 balanceOfSender = balance[_sender];
        require(balanceOfSender >= _amount, "NO_ENOUGH_BALANCE_TO_TRANSFER");
        balanceOfSender -= _amount;
        balance[_sender] = balanceOfSender;
        balance[_recipient] += _amount;
        emit Transfer(_sender, _recipient, _amount);
    }

    function _approve(address _owner, address _spender, uint256 _amount) internal {
        require(_owner != address(0), "APPROVE_FROM_ZERO_ADDRESS");
        require(_spender != address(0), "APPROVE_TO_ZERO_ADDRESS");
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    }


    // -------------------------------- base functions --------------------------------
    /**
     * @notice Exchanges stUSDT to wstUSDT
     * @param stUSDTAmount amount of stUSDT to wrap in exchange for wstUSDT
     * @dev Requirements:
     *  - `stUSDTAmount` must be non-zero
     *  - msg.sender must approve at least `stUSDTAmount` stUSDT to this
     *    contract.
     *  - msg.sender must have at least `stUSDTAmount` of stUSDT.
     * User should first approve _stUSDTAmount to the WstUSDT contract
     * @return Amount of wstUSDT user receives after wrap
     */
    function wrap(uint256 stUSDTAmount) external returns (uint256) {
        require(stUSDTAmount > 0, "CAN'T_WRAP_ZERO_STUSDT");

        uint256 wstUSDTAmount = stUSDT.getSharesByUnderlying(stUSDTAmount);
        stUSDT.transferFrom(msg.sender, address(this), stUSDTAmount);

        balance[msg.sender] += wstUSDTAmount;
        _totalSupply += wstUSDTAmount;
        emit Transfer(address(0), msg.sender, wstUSDTAmount);

        return wstUSDTAmount;
    }

    /**
     * @notice Exchange wstUSDT to stUSDT
     * @param wstUSDTAmount amount of wstUSDT to uwrap in exchange for stUSDT
     * @dev Requirements:
     *  - `wstUSDTAmount` must be non-zero
     *  - msg.sender must have at least `wstUSDTAmount` wstUSDT.
     * @return Amount of stUSDT user receives after unwrap
     */
    function unwrap(uint256 wstUSDTAmount) external returns (uint256) {
        require(wstUSDTAmount > 0, "ZERO_AMOUNT_UNWRAP_NOT_ALLOWED");
        uint256 balanceOfWstUSDT = balance[msg.sender];
        require(balanceOfWstUSDT >= wstUSDTAmount, "NO_ENOUGH_BALANCE_TO_UNWRAP");
        uint256 stUSDTAmount = stUSDT.getUnderlyingByShares(wstUSDTAmount);

        _totalSupply -= wstUSDTAmount;
        balanceOfWstUSDT -= wstUSDTAmount;
        balance[msg.sender] = balanceOfWstUSDT;

        stUSDT.transferShares(msg.sender, wstUSDTAmount);

        emit Transfer(msg.sender, address(0), wstUSDTAmount);

        return stUSDTAmount;
    }

    /**
     * @notice Get amount of wstUSDT for a given amount of stUSDT
     * @param stUSDTAmount amount of stUSDT
     * @return Amount of wstUSDT for a given stUSDT amount
     */
    function getWstUSDTByStUSDT(uint256 stUSDTAmount) external view returns (uint256) {
        return stUSDT.getSharesByUnderlying(stUSDTAmount);
    }

    /**
     * @notice Get amount of stUSDT for a given amount of wstUSDT
     * @param wstUSDTAmount amount of wstUSDT
     * @return Amount of stUSDT for a given wstUSDT amount
     */
    function getStUSDTByWstUSDT(uint256 wstUSDTAmount) external view returns (uint256) {
        return stUSDT.getUnderlyingByShares(wstUSDTAmount);
    }

    /**
     * @notice Get amount of stUSDT for 1 wstUSDT
     * @return Amount of stUSDT for 1 wstUSDT
     */
    function stUSDTPerToken() external view returns (uint256) {
        return stUSDT.getUnderlyingByShares(1e18);
    }

    /**
     * @notice Get amount of wstUSDT for 1 stUSDT
     * @return Amount of wstUSDT for 1 stUSDT
     */
    function tokensPerStUSDT() external view returns (uint256) {
        return stUSDT.getSharesByUnderlying(1e18);
    }

    function _become(IProxy proxy) external {
        require(msg.sender == proxy.admin(), "only admin can change brains");
        proxy._acceptImplementation();
    }

}