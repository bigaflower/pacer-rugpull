import "lib/forge-std/src/mocks/MockERC20.sol";
import "contracts/external/openzeppelin/contracts/access/Ownable.sol";

contract TestUSDC is MockERC20, Ownable {
  constructor() Ownable() {
    initialize("TestUSDC", "t-USDC", 6);
  }

  function mint(address to, uint256 value) public onlyOwner {
    _mint(to, value);
  }

  function burn(address from, uint256 value) public onlyOwner {
    _burn(from, value);
  }
}
