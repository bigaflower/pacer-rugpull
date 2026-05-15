// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.26;

/*
Lush is the 1st vertically integrated influencer & OnlyFans agency, powered by A.I. and Web3

Website: https://lushai.net/
Twitter: https://twitter.com/LushAIAgency
Telegram: https://t.me/lushaiportal
Discord: https://discord.gg/x7GHGg3Uft
Docs: https://lushai.gitbook.io/lushai/
                                                                                                 
                                                                                      
LLLLLLLLLLL            UUUUUUUU     UUUUUUUU   SSSSSSSSSSSSSSS HHHHHHHHH     HHHHHHHHH
L:::::::::L            U::::::U     U::::::U SS:::::::::::::::SH:::::::H     H:::::::H
L:::::::::L            U::::::U     U::::::US:::::SSSSSS::::::SH:::::::H     H:::::::H
LL:::::::LL            UU:::::U     U:::::UUS:::::S     SSSSSSSHH::::::H     H::::::HH
  L:::::L               U:::::U     U:::::U S:::::S              H:::::H     H:::::H  
  L:::::L               U:::::D     D:::::U S:::::S              H:::::H     H:::::H  
  L:::::L               U:::::D     D:::::U  S::::SSSS           H::::::HHHHH::::::H  
  L:::::L               U:::::D     D:::::U   SS::::::SSSSS      H:::::::::::::::::H  
  L:::::L               U:::::D     D:::::U     SSS::::::::SS    H:::::::::::::::::H  
  L:::::L               U:::::D     D:::::U        SSSSSS::::S   H::::::HHHHH::::::H  
  L:::::L               U:::::D     D:::::U             S:::::S  H:::::H     H:::::H  
  L:::::L         LLLLLLU::::::U   U::::::U             S:::::S  H:::::H     H:::::H  
LL:::::::LLLLLLLLL:::::LU:::::::UUU:::::::U SSSSSSS     S:::::SHH::::::H     H::::::HH
L::::::::::::::::::::::L UU:::::::::::::UU  S::::::SSSSSS:::::SH:::::::H     H:::::::H
L::::::::::::::::::::::L   UU:::::::::UU    S:::::::::::::::SS H:::::::H     H:::::::H
LLLLLLLLLLLLLLLLLLLLLLLL     UUUUUUUUU       SSSSSSSSSSSSSSS   HHHHHHHHH     HHHHHHHHH
                                                                                      
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract LushAI is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("LushAI", "LUSH") ERC20Permit("LushAI") {
        _mint(msg.sender, 20_000_000_000 * 10 ** decimals());
    }
}
