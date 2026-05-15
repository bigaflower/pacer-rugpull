// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// ==== นำเข้าไลบรารีมาตรฐานจาก OpenZeppelin ==== //
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// ==== สัญญาหลักของเหรียญ ==== //
contract MetaCoreMABO is ERC20, Ownable {

uint256 public constant INITIAL_SUPPLY = 1_000_000_000 * 10 ** 18; // 1 พันล้านเหรียญ
address public liquidityWallet; // ที่เก็บเหรียญสำรองหรือ Liquidity

constructor() ERC20("MetaCore MABO", "MABO") Ownable(msg.sender) {
_mint(msg.sender, INITIAL_SUPPLY);
liquidityWallet = msg.sender;
}

// ==== ฟังก์ชัน Burn: เผาเหรียญเพื่อลด Supply ==== //
function burn(uint256 amount) external {
_burn(msg.sender, amount);
}

// ==== ฟังก์ชัน Mint เพิ่ม (เฉพาะเจ้าของเท่านั้น) ==== //
function mint(address to, uint256 amount) external onlyOwner {
_mint(to, amount);
}

// ==== ฟังก์ชันเปลี่ยนที่อยู่ Liquidity ==== //
function setLiquidityWallet(address newWallet) external onlyOwner {
liquidityWallet = newWallet;
}
}