pragma solidity ^0.4.24;

import "./StandardToken.sol";

contract TokenERC20 is StandardToken {
  string public name;
  string public symbol;
  uint8 public decimals;
  address public owner;
  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  modifier onlyOwner {
    require(msg.sender == owner, "Caller is not the owner");
    _;
  }

  constructor(string _name, string _symbol, uint8 _decimals, uint256 _init_supply) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    balances[msg.sender] = totalSupply_ = _init_supply * (10 ** uint(decimals));
    owner = msg.sender;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "New owner is the zero address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  /**
   * Destroy tokens from other account
   * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
   * @param _from the address of the sender
   * @param _value the amount of money to burn
   */
  function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool) {
    require(balances[_from] >= _value);                // Check if the targeted balance is enough
    balances[_from] = balances[_from].sub(_value);     // Subtract from the targeted balance
    totalSupply_ = totalSupply_.sub(_value);           // Update totalSupply
    emit Burn(_from, _value);
    return true;
  }

  /**
   * CENTRAL MINT
   */
  function mintToken(address _to, uint256 _mintedAmount) public onlyOwner {
    balances[_to] = balances[_to].add(_mintedAmount);
    totalSupply_ = totalSupply_.add(_mintedAmount);
    emit Transfer(address(0), owner, _mintedAmount);
    emit Transfer(owner, _to, _mintedAmount);
  }

  /**
   * FREEZING OF ASSETS
   */
  function freezeAccount(address _target, bool _freeze) public onlyOwner {
    frozenAccount[_target] = _freeze;
    emit FrozenFunds(_target, _freeze);
  }
}


