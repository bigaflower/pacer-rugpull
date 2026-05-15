// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

event Deposit(
  address indexed user,
  address indexed tokenAddress,
  uint256 amount
);
event Withdrawal(
  address indexed user,
  address indexed tokenAddress,
  uint256 amount
);

abstract contract WrappedToken is
  ERC20Upgradeable,
  AccessControlUpgradeable,
  UUPSUpgradeable,
  ReentrancyGuardUpgradeable
{
  using SafeERC20 for IERC20;

  bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
  uint8 private constant noOfDecimals = 6;

  function initialize(
    string memory name,
    string memory symbol,
    address admin
  ) public initializer {
    __ERC20_init(name, symbol);
    __AccessControl_init();
    __UUPSUpgradeable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(UPGRADER_ROLE, admin);
  }

  function deposit(uint256 tokenId, uint256 amount) public nonReentrant {
    IERC20 underlyingToken = _getTokenById(tokenId);
    require(
      underlyingToken.balanceOf(msg.sender) >= amount,
      "Insufficient collateral"
    );
    underlyingToken.safeTransferFrom(msg.sender, address(this), amount);
    _mint(msg.sender, amount);
    emit Deposit(msg.sender, address(underlyingToken), amount);
  }

  function withdraw(uint256 tokenId, uint256 amount) public nonReentrant {
    IERC20 underlyingToken = _getTokenById(tokenId);
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    _burn(msg.sender, amount);
    underlyingToken.safeTransfer(msg.sender, amount);
    emit Withdrawal(msg.sender, address(underlyingToken), amount);
  }

  function _authorizeUpgrade(
    address newImplementation
  ) internal override onlyRole(UPGRADER_ROLE) {}

  function decimals() public view virtual override returns (uint8) {
    return noOfDecimals;
  }

  function _getTokenById(
    uint256 tokenId
  ) internal pure virtual returns (IERC20);
}
