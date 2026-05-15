//cipherchan.com
//Cipherchan is a token-gated forum, feed, and messaging platform where content can live on-chain (Ethereum) or off-chain (server database). Users authenticate via wallet signature or nickname/password. The CIPHER ERC-20 token controls access tiers, voting power, and premium features. No KYC, no email, no phone number — your identity is your wallet or a pseudonymous nickname.

// SPDX-License-Identifier: MIT
  pragma solidity ^0.8.20;

  contract CipherToken {

      string  public constant name     = "Cipherchan";
      string  public constant symbol   = "CIPHER";
      uint8   public constant decimals = 18;
      uint256 public constant totalSupply = 100_000 * 1e18;

      mapping(address => uint256) public balanceOf;
      mapping(address => mapping(address => uint256)) public allowance;

      address public owner;

      uint256 public maxWalletAmount = (totalSupply * 2) / 100;
      uint256 public maxBuyAmount    = (totalSupply * 2) / 100;
      bool    public limitsEnabled   = true;

      mapping(address => bool) public isExempt;
      mapping(address => bool) public isAmmPair;

      event Transfer(address indexed from, address indexed to, uint256 value);
      event Approval(address indexed owner, address indexed spender, uint256 value);
      event OwnershipTransferred(address indexed previousOwner, address indexed
  newOwner);

      modifier onlyOwner() {
          require(msg.sender == owner, "not owner");
          _;
      }

      constructor() {
          owner = msg.sender;
          isExempt[msg.sender] = true;
          balanceOf[msg.sender] = totalSupply;
          emit Transfer(address(0), msg.sender, totalSupply);
      }

      function approve(address spender, uint256 amount) external returns (bool) {
          allowance[msg.sender][spender] = amount;
          emit Approval(msg.sender, spender, amount);
          return true;
      }

      function transfer(address to, uint256 amount) external returns (bool) {
          return _transfer(msg.sender, to, amount);
      }

      function transferFrom(address from, address to, uint256 amount) external returns
   (bool) {
          uint256 allowed = allowance[from][msg.sender];
          if (allowed != type(uint256).max) {
              require(allowed >= amount, "allowance exceeded");
              allowance[from][msg.sender] = allowed - amount;
          }
          return _transfer(from, to, amount);
      }

      function _transfer(address from, address to, uint256 amount) internal returns
  (bool) {
          require(from != address(0) && to != address(0), "zero address");
          require(balanceOf[from] >= amount, "insufficient balance");

          if (limitsEnabled && !isExempt[from] && !isExempt[to]) {
              if (isAmmPair[from]) {
                  require(amount <= maxBuyAmount, "exceeds max buy");
              }
              if (!isAmmPair[to]) {
                  require(balanceOf[to] + amount <= maxWalletAmount, "exceeds max wallet");
              }
          }

          balanceOf[from] -= amount;
          balanceOf[to]   += amount;
          emit Transfer(from, to, amount);
          return true;
      }

      function setExempt(address addr, bool exempt) external onlyOwner {
          isExempt[addr] = exempt;
      }

      function setAmmPair(address pair, bool isPair) external onlyOwner {
          isAmmPair[pair] = isPair;
      }

      function setMaxWalletPercent(uint256 percent) external onlyOwner {
          require(percent >= 1 && percent <= 100, "1-100");
          maxWalletAmount = (totalSupply * percent) / 100;
      }

      function setMaxBuyPercent(uint256 percent) external onlyOwner {
          require(percent >= 1 && percent <= 100, "1-100");
          maxBuyAmount = (totalSupply * percent) / 100;
      }

      function removeLimits() external onlyOwner {
          limitsEnabled = false;
      }

      function enableLimits() external onlyOwner {
          limitsEnabled = true;
      }

      function transferOwnership(address newOwner) external onlyOwner {
          require(newOwner != address(0), "zero address");
          emit OwnershipTransferred(owner, newOwner);
          owner = newOwner;
      }

      function renounceOwnership() external onlyOwner {
          emit OwnershipTransferred(owner, address(0));
          owner = address(0);
      }
  }