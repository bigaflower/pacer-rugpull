// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "./utils/ERC20.sol";
import "./utils/Ownable.sol";

interface IEarlyERC20Ver2_0 {
    function initialize(address _deployer, address _pair, string calldata _name, string calldata _symbol) external;
    function deployer() external view returns (address);
    function proxy() external view returns (address);
    function open() external;
}

contract EarlyERC20Ver2_0 is ERC20, IEarlyERC20Ver2_0, Ownable {
    address public deployer;
    address public pair;
    bool public isOpen = false;
    address public immutable proxy;

    bool private initialized = false;
    uint256 private constant BASE_TOTAL_SUPPLY = 1_000_000_000 * 10**18;

    event Initialized(address indexed _deployer, string _name, string _symbol);

    constructor(address _tokenProxy) Ownable(_tokenProxy) {
        proxy = _tokenProxy;
    }

    function initialize(address _deployer, address _pair, string calldata _name, string calldata _symbol) external {
        require(msg.sender == proxy, "Unauthenticated");
        require(!initialized, "Already initialized");
        initialized = true;

        deployer = _deployer;
        pair = _pair;
        name = _name;
        symbol = _symbol;

        _mint(proxy, BASE_TOTAL_SUPPLY);

        emit Initialized(_deployer, _name, _symbol);
    }

    function open() external {
        require(msg.sender == proxy, "Unauthenticated");
        isOpen = true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        if (!isOpen) {
            require(sender != pair && recipient != pair, "NOT_ALLOWED");
        }

        super._transfer(sender, recipient, amount);
    }
}