/**
 * Copyright 2025 Circle Internet Group, Inc. All rights reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
pragma solidity ^0.8.0;

// imported contracts and libraries
import {Access} from "../entitlements/Access.sol";
import {ERC20} from "./ERC20.sol";
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {Ownable} from "../entitlements/Ownable.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {UUPSUpgradeable} from "openzeppelin/proxy/utils/UUPSUpgradeable.sol";

// interfaces
import {IToken} from "../../interfaces/IToken.sol";
import {Teller} from "../tellers/Teller.sol";

import "../../config/constants.sol";
import "../../config/errors.sol";

/**
 * @title   YieldCoin
 * @author  dsshap
 * @dev     Represent the shares of a tokenized Fund
 *             The value of the token should always be positive.
 */
contract YieldCoin is ERC20, Initializable, Access, Ownable, UUPSUpgradeable {
    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event TellerSet(address teller, address newTeller);
    event UnderlyingSet(address token);
    event Sweep(address indexed recipient, address token, uint256 amount);
    event MinterConfigured(address minter, uint256 amount);

    /// @notice ***DEPRECATED***
    event FeeRecipientSet(address recipient, address newRecipient);
    event ManagementFeeSet(uint256 managementFee, uint256 newManagementFee);
    event OracleSet(address oracle, address newOracle);
    event TradeToFiat(address indexed recipient, address token, uint256 amount);
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event FeeProcessed(address indexed recipient, uint256 fee);

    /*///////////////////////////////////////////////////////////////
                         State Variables V1 & V2
    //////////////////////////////////////////////////////////////*/

    uint256[7] private __deprecatedGap0;

    /*///////////////////////////////////////////////////////////////
                         State Variables V3
    //////////////////////////////////////////////////////////////*/

    /// @notice the addresses that are able to mint new tokens
    mapping(address => uint256) public minterAllowance;

    /*///////////////////////////////////////////////////////////////
                         State Variables V4
    //////////////////////////////////////////////////////////////*/

    uint256 internal _decimals;

    uint256 internal immutable _initialChainId;

    bytes32 internal _initialDomainSeparator;

    uint256[1] private __deprecatedGap1;

    /*///////////////////////////////////////////////////////////////
                Constructor for implementation Contract
    //////////////////////////////////////////////////////////////*/

    constructor(address _authority) ERC20() Access(_authority) {
        _initialChainId = block.chainid;

        _disableInitializers();
    }

    /*///////////////////////////////////////////////////////////////
                            Initializer
    //////////////////////////////////////////////////////////////*/

    function initialize(string memory _name, string memory _symbol, uint8 _dec, address _owner, address _minter)
        external
        initializer
    {
        if (_owner == address(0)) revert BadAddress();
        if (_minter == address(0)) revert BadAddress();

        _transferOwnership(_owner);

        name = _name;
        symbol = _symbol;
        _decimals = _dec;

        minterAllowance[_minter] = type(uint256).max;

        _initialDomainSeparator = _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                        ERC20 Functions
    //////////////////////////////////////////////////////////////*/

    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        _assertPermission(msg.sender);
        _assertCanReceive(address(this), _to);

        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _amount) public virtual override returns (bool) {
        if (_isFundAdmin()) {
            balanceOf[_from] -= _amount;

            // Cannot overflow because the sum of all user
            // balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[_to] += _amount;
            }

            emit Transfer(_from, _to, _amount);

            return true;
        } else {
            _assertPermission(msg.sender);
            _assertCanReceive(address(this), _from, _to);

            return super.transferFrom(_from, _to, _amount);
        }
    }

    function mint(address _to, uint256 _amount) external returns (bool) {
        uint256 allowed = minterAllowance[msg.sender]; // Saves gas for limited approvals.
        if (allowed != type(uint256).max) minterAllowance[msg.sender] = allowed - _amount;

        // checking that recipient has permissions to hold/transfer token
        _assertCanReceive(address(this), _to);

        _mint(_to, _amount);

        return true;
    }

    /**
     * @notice burns for sender
     * @param _amount The amount to burn
     */
    function burn(uint256 _amount) external {
        _assertPermission(msg.sender);

        _burn(msg.sender, _amount);
    }

    /**
     * @notice burns tokens for a user
     * @dev only callable by minter
     * @param _from The address to burn tokens for
     * @param _amount The amount of tokens to burn
     */
    function burn(address _from, uint256 _amount) public {
        if (minterAllowance[msg.sender] == 0) revert NoAccess();

        // checking that recipient has permissions to hold/transfer token
        _assertCanReceive(address(this), _from);

        _burn(_from, _amount);
    }

    /**
     * @notice burns tokens for a user
     * @dev only callable by minter
     * @param _from The address to burn tokens for
     * @param _amount The amount of tokens to burn
     */
    function burnFor(address _from, uint256 _amount) external {
        burn(_from, _amount);
    }

    function decimals() public view returns (uint8) {
        return uint8(_decimals);
    }

    /**
     * @notice Sends token to be converted to fiat
     * @param _token address of token
     * @param _amount is the amount
     * @param _recipient the destination
     */
    function sweep(address _token, uint256 _amount, address _recipient) external virtual {
        _assertFundAdmin();

        if (!authority.doesUserHaveRole(_recipient, ROLE_RESERVES)) revert NotPermissioned();

        emit Sweep(_recipient, _token, _amount);

        SafeERC20.safeTransfer(IToken(_token), _recipient, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                        Management Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Sets the minter role and the amount of tokens the minter is allowed to mint
     * @param _minter is the address of the new minter
     * @param _amount is the amount of tokens the minter is allowed to mint
     */
    function setMinterAllowance(address _minter, uint256 _amount) public {
        _assertPermission(msg.sender);

        if (_minter == address(0)) revert BadAddress();

        emit MinterConfigured(_minter, _amount);

        minterAllowance[_minter] = _amount;
    }

    /**
     * @notice Increments the amount of token a minter is allowed to mint
     * @param _minter is the address of the new minter
     * @param _amount is the amount of tokens to increase the allowance by
     */
    function incrementMinterAllowance(address _minter, uint256 _amount) external {
        uint256 current = minterAllowance[_minter];

        setMinterAllowance(_minter, current + _amount);
    }

    /**
     * @notice Decrements the amount of tokens a minter is allowed to mint
     * @param _minter is the address of the new minter
     * @param _amount is the amount of tokens to decrease the allowance by
     */
    function decrementMinterAllowance(address _minter, uint256 _amount) external {
        uint256 current = minterAllowance[_minter];
        uint256 decrement = current > _amount ? _amount : current;

        setMinterAllowance(_minter, current - decrement);
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        return block.chainid == _initialChainId ? _initialDomainSeparator : _computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                    Override Upgrade Permission
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Upgradable by the owner.
     *
     */
    function _authorizeUpgrade(
        address /*newImplementation*/
    )
        internal
        virtual
        override
    {
        _assertOwner();
    }
}
