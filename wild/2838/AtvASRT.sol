// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ERC20} from "./ERC20.sol";
import {OwnableDelayModule} from "./OwnableDelayModule.sol";

contract AtvASRT is ERC20, OwnableDelayModule {

    uint256 public constant MAX_SUPPLY = 6000000 * 10 ** 18; // Max supply of 2 million ASRT tokens

    mapping(address => bool) public whitelistedMember;
    mapping(address => uint256) public allowance;

    event TokensMinted(address to, uint256 amount);

    constructor() ERC20("AtvASRT", "ASRT"){}

    modifier minters() {
        require(allowance[msg.sender] > 0, "ASRT: caller is not a minter");
        _;
    }

    // Function to mint tokens to a specific address
    function mint(address to, uint256 amount) external {
        isDelayModule();
        require(amount > 0, "ASRT: Zero amount passed");
        require(totalSupply() + (amount) <= MAX_SUPPLY, "ASRT: Exceeds max supply");
        _mint(to, amount);
        emit TokensMinted(to, amount);
    }

    function mintDirect(uint256 amount) external minters {
        require(amount > 0, "ASRT: Zero amount passed");
        require(totalSupply() + (amount) <= MAX_SUPPLY, "ASRT: Exceeds max supply");
        require(allowance[msg.sender] >= amount, "ASRT: amount exceeds the allowance");
        allowance[msg.sender] -= amount;
        _mint(msg.sender, amount);
        emit TokensMinted(msg.sender, amount);
    }

    function updateMinter(address account, uint256 _allowance) external onlyOwner {
        require(account != address(0), "ASRT: Zero Address");
        allowance[account] = _allowance;
    }

    function addWhitelist(address account) external {
        isDelayModule();
        require(account != address(0), "ASRT: Zero Address");
        whitelistedMember[account] = true;
    }

    function removeWhitelist(address account) external onlyOwner {
        require(account != address(0), "ASRT: Zero Address");
        whitelistedMember[account] = false;
    }

    /**
     * @dev Being non transferrable, the ASRT token does only implement one type of the
     * standard ERC20 functions for transfer that is 'transferFrom' with some restriction.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(whitelistedMember[msg.sender], "ASRT: Not a whitelisted caller");
        address owner = _msgSender();
        _transfer(owner, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `to` must be the whitelisted accounts.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        require(whitelistedMember[msg.sender], "ASRT: Not a Whitelisted Caller");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
}
