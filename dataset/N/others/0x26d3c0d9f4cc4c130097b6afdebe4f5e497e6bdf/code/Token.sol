// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./WrappedToken.sol";

contract Token is WrappedToken {
  IERC20 public constant underlyingToken1 =
    IERC20(0xf10Cf9Cb8Ded35CBf43baBfc9aeCf50A05da4CbA);

  function _getTokenById(
    uint256 tokenId
  ) internal pure override returns (IERC20) {
    if (tokenId == 0) return underlyingToken1;
    revert("Invalid token ID");
  }
}
