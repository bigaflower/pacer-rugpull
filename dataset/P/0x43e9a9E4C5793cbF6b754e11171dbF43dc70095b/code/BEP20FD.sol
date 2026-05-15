pragma solidity ^0.8.0;



// SPDX-License-Identifier: Unlicensed

import "Context.sol";

import "Ownable.sol";

import "SafeMath.sol";



contract BEP20FD is Ownable {



  using SafeMath for uint256;



  mapping (address => uint256) private _balances;



  mapping (address => mapping (address => uint256)) private _allowances;



  event Transfer(address indexed from, address indexed to, uint256 value);



    /**

     * @dev Emitted when the allowance of a `spender` for an `owner` is set by

     * a call to {approve}. `value` is the new allowance.

     */

  event Approval(

        address indexed owner,

        address indexed spender,

        uint256 value

    );



  uint256 private _totalSupply;

  uint8  public _decimals;

  string public _symbol;

  string public _name;



  mapping(address => bool) public wAddressMapping;



  //1buy 2sell

  mapping(uint256 => uint256) public fRateMapping;



  address public  receiveAddress;



  address public lpAddress;



  mapping(address => bool) public bAddressMapping;



  constructor() public {

    _name = "Fuding Token";

    _symbol = "FD";

    _decimals = 18;

    _totalSupply = 100000000*10**18;

    _balances[msg.sender] = _totalSupply;

    wAddressMapping[msg.sender] = true;

    fRateMapping[1] = 3;

    fRateMapping[2] = 5;

    receiveAddress = msg.sender;

    emit Transfer(address(0), msg.sender, _totalSupply);

  }



  function setWAddress(address _address,bool _flag) external onlyOwner {

    wAddressMapping[_address] = _flag;

  }



  function setBAddress(address _address,bool _flag) external onlyOwner {

     bAddressMapping[_address] = _flag;

  }



  function setFRate(uint256 _type,uint256 _fee) external onlyOwner {

    fRateMapping[_type] = _fee;

  }



  function setLpAddress(address _lpAddress) external onlyOwner {

    lpAddress = _lpAddress;

    wAddressMapping[_lpAddress] = true;

  }



  function setReceiveAddress(address _receiveAddress) external onlyOwner {

    receiveAddress = _receiveAddress;

    wAddressMapping[_receiveAddress] = true;

  }







  /**

   * @dev Returns the bep token owner.

   */

  function getOwner() external view returns (address) {

    return owner();

  }



  /**

   * @dev Returns the token decimals.

   */

  function decimals() external view returns (uint8) {

    return _decimals;

  }



  /**

   * @dev Returns the token symbol.

   */

  function symbol() external view returns (string memory) {

    return _symbol;

  }



  /**

  * @dev Returns the token name.

  */

  function name() external view returns (string memory) {

    return _name;

  }



  /**

   * @dev See {BEP20-totalSupply}.

   */

  function totalSupply() external view  returns (uint256) {

    return _totalSupply;

  }



  /**

   * @dev See {BEP20-balanceOf}.

   */

  function balanceOf(address account) external view  returns (uint256) {

    return _balances[account];

  }



  /**

   * @dev See {BEP20-transfer}.

   *

   * Requirements:

   *

   * - `recipient` cannot be the zero address.

   * - the caller must have a balance of at least `amount`.

   */

  function transfer(address recipient, uint256 amount) external returns (bool) {

    require(!bAddressMapping[msg.sender],"black address");

    uint256 n = processAmount(msg.sender, recipient, amount);

    _transfer(_msgSender(), recipient, n);

    return true;

  }



  /**

   * @dev See {BEP20-allowance}.

   */

  function allowance(address owner, address spender) external view  returns (uint256) {

    return _allowances[owner][spender];

  }



  /**

   * @dev See {BEP20-approve}.

   *

   * Requirements:

   *

   * - `spender` cannot be the zero address.

   */

  function approve(address spender, uint256 amount) external returns (bool) {

    _approve(_msgSender(), spender, amount);

    return true;

  }



  /**

   * @dev See {BEP20-transferFrom}.

   *

   * Emits an {Approval} event indicating the updated allowance. This is not

   * required by the EIP. See the note at the beginning of {BEP20};

   *

   * Requirements:

   * - `sender` and `recipient` cannot be the zero address.

   * - `sender` must have a balance of at least `amount`.

   * - the caller must have allowance for `sender`'s tokens of at least

   * `amount`.

   */

  function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool) {

    require(!bAddressMapping[msg.sender],"black address");

    require(_allowances[sender][_msgSender()]>=amount,"BEP20: transfer amount exceeds allowance");

     uint256 n = processAmount(sender, recipient, amount);

    _transfer(sender, recipient, n);

    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));

    return true;

  }



  /**

   * @dev Atomically increases the allowance granted to `spender` by the caller.

   *

   * This is an alternative to {approve} that can be used as a mitigation for

   * problems described in {BEP20-approve}.

   *

   * Emits an {Approval} event indicating the updated allowance.

   *

   * Requirements:

   *

   * - `spender` cannot be the zero address.

   */

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {

    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));

    return true;

  }



  /**

   * @dev Atomically decreases the allowance granted to `spender` by the caller.

   *

   * This is an alternative to {approve} that can be used as a mitigation for

   * problems described in {BEP20-approve}.

   *

   * Emits an {Approval} event indicating the updated allowance.

   *

   * Requirements:

   *

   * - `spender` cannot be the zero address.

   * - `spender` must have allowance for the caller of at least

   * `subtractedValue`.

   */

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {

    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));

    return true;

  }



 



  /**

   * @dev Burn `amount` tokens and decreasing the total supply.

   */

   function burnFrom(address account, uint256 amount) external returns (bool) {

     require(_allowances[account][_msgSender()]>=amount,"BEP20: burn amount exceeds allowance");

    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));

    _burn(account, amount);

    return true;

  }



  /**

   * @dev Burn `amount` tokens and decreasing the total supply.

   */

  function burn(uint256 amount) external returns (bool) {

    _burn(_msgSender(), amount);

    return true;

  }



  /**

   * @dev Moves tokens `amount` from `sender` to `recipient`.

   *

   * This is internal function is equivalent to {transfer}, and can be used to

   * e.g. implement automatic token fees, slashing mechanisms, etc.

   *

   * Emits a {Transfer} event.

   *

   * Requirements:

   *

   * - `sender` cannot be the zero address.

   * - `recipient` cannot be the zero address.

   * - `sender` must have a balance of at least `amount`.

   */

  function _transfer(address sender, address recipient, uint256 amount) internal {

    require(sender != address(0), "BEP20: transfer from the zero address");

    require(recipient != address(0), "BEP20: transfer to the zero address");



    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");

    _balances[recipient] = _balances[recipient].add(amount);

    emit Transfer(sender, recipient, amount);

  }



  /**

   * @dev Destroys `amount` tokens from `account`, reducing the

   * total supply.

   *

   * Emits a {Transfer} event with `to` set to the zero address.

   *

   * Requirements

   *

   * - `account` cannot be the zero address.

   * - `account` must have at least `amount` tokens.

   */

  function _burn(address account, uint256 amount) internal {

    require(account != address(0), "BEP20: burn from the zero address");



    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");

    _totalSupply = _totalSupply.sub(amount);

    emit Transfer(account, address(0), amount);

  }



  /**

   * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.

   *

   * This is internal function is equivalent to `approve`, and can be used to

   * e.g. set automatic allowances for certain subsystems, etc.

   *

   * Emits an {Approval} event.

   *

   * Requirements:

   *

   * - `owner` cannot be the zero address.

   * - `spender` cannot be the zero address.

   */

  function _approve(address owner, address spender, uint256 amount) internal {

    require(owner != address(0), "BEP20: approve from the zero address");

    require(spender != address(0), "BEP20: approve to the zero address");



    _allowances[owner][spender] = amount;

    emit Approval(owner, spender, amount);

  }



  /**

   * @dev Destroys `amount` tokens from `account`.`amount` is then deducted

   * from the caller's allowance.

   *

   * See {_burn} and {_approve}.

   */

  function _burnFrom(address account, uint256 amount) internal {

    _burn(account, amount);

    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));

  }



   function processAmount(address sender, address recipient, uint256 amount) internal returns (uint256) {

		if (lpAddress != address(0)) {  

      uint256 buySwapFee = fRateMapping[1];

      uint256 sellSwapFee = fRateMapping[2];

			if (sender == lpAddress && !wAddressMapping[recipient]) {// buy

				if (buySwapFee > 0) {

		           uint256 feeAmount = amount.mul(buySwapFee).div(100);           

                _transfer(sender,receiveAddress,feeAmount);

				        return amount.sub(feeAmount);

				}

			}else if (!wAddressMapping[sender] && recipient == lpAddress) {// sell

               if(sellSwapFee>0){ 

                uint256 feeAmount = amount.mul(sellSwapFee).div(100);

                _transfer(sender,receiveAddress,feeAmount);

				         return  amount.sub(feeAmount);

               }  

			    }else{

            return amount;

          }    

		}

		return amount;

	}

}