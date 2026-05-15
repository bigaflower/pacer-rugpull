// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@lazy-sol/advanced-erc20/contracts/token/AdvancedERC20.sol";

/**
 *                                                                                                               
 *                                            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                                            
 *                                      ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                                     
 *                                ↑↑↑↑↑↑↑↑↑↑↑↑↑                     ↑↑↑↑↑↑↑↑↑↑↑↑↑↑                               
 *                             ↑↑↑↑↑↑↑↑↑↑↑     ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑        ↑↑↑↑↑↑↑↑↑↑                            
 *                          ↑↑↑↑↑↑↑↑      ↑↑↑                          ↑↑↑      ↑↑↑↑↑↑↑↑                         
 *                       ↑↑↑↑↑↑↑↑     ↑↑      ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑     ↑↑     ↑↑↑↑↑↑↑↑                      
 *                     ↑↑↑↑↑↑↑           ↑↑↑↑↑↑                      ↑↑↑↑↑↑           ↑↑↑↑↑↑↑                    
 *                   ↑↑↑↑↑↑           ↑↑↑                                  ↑↑↑           ↑↑↑↑↑↑                  
 *                 ↑↑↑↑↑↑          ↑↑                                          ↑↑          ↑↑↑↑↑↑                
 *               ↑↑↑↑↑↑                                                                      ↑↑↑↑↑↑              
 *             ↑↑↑↑↑    ↑↑                                                                ↑↑    ↑↑↑↑             
 *            ↑↑↑↑   ↑↑↑                                                                    ↑↑    ↑↑↑↑           
 *           ↑↑↑↑  ↑     ↑                                                                ↑↑    ↑↑ ↑↑↑↑          
 *          ↑↑↑  ↑    ↑↑                                                                    ↑↑    ↑  ↑↑↑         
 *        ↑↑↑↑  ↑    ↑↑                                                                      ↑↑     ↑ ↑↑↑        
 *        ↑↑↑ ↑    ↑↑↑                                                                        ↑↑↑    ↑ ↑↑↑       
 *       ↑↑↑ ↑    ↑↑                             ↑↑↑↑↑↑↑↑↑↑                                     ↑↑    ↑ ↑↑↑      
 *      ↑↑↑ ↑    ↑↑                            ↑↑↑↑       ↑↑↑↑↑↑↑↑↑                              ↑↑    ↑ ↑↑↑     
 *     ↑↑↑ ↑    ↑↑                       ↑↑↑↑↑↑↑    ↑↑↑↑         ↑↑↑↑↑                            ↑↑    ↑ ↑↑↑    
 *     ↑↑↑      ↑                    ↑↑↑↑                 ↑↑↑↑↑↑↑↑  ↑↑↑                            ↑↑    ↑ ↑↑    
 *    ↑↑↑      ↑                   ↑↑↑    ↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑   ↑   ↑↑↑ ↑↑↑                           ↑      ↑↑↑   
 *    ↑↑↑     ↑↑                  ↑↑  ↑↑↑↑      ↑↑↑↑↑↑ ↑↑  ↑↑↑   ↑  ↑↑  ↑↑↑↑                         ↑      ↑↑   
 *   ↑↑↑      ↑                  ↑  ↑                ↑ ↑↑ ↑       ↑ ↑↑    ↑↑↑↑                       ↑↑     ↑↑↑  
 *   ↑↑      ↑                  ↑↑     ↑             ↑  ↑ ↑↑  ↑↑ ↑↑ ↑↑  ↑↑   ↑↑↑                      ↑      ↑↑  
 *  ↑↑↑                         ↑   ↑ ↑  ↑↑          ↑↑  ↑↑  ↑↑↑↑  ↑↑ ↑↑↑↑↑↑↑  ↑↑↑                    ↑      ↑↑↑ 
 *  ↑↑↑                         ↑   ↑  ↑  ↑↑↑↑         ↑↑       ↑↑↑  ↑↑    ↑↑↑  ↑↑↑                   ↑      ↑↑↑ 
 *  ↑↑                          ↑↑   ↑  ↑↑   ↑↑↑↑       ↑↑↑↑       ↑↑↑       ↑↑↑  ↑↑                  ↑       ↑↑ 
 *  ↑↑                           ↑↑  ↑↑   ↑↑↑   ↑↑↑↑↑       ↑↑↑↑↑↑↑           ↑↑↑  ↑↑                 ↑↑      ↑↑ 
 *  ↑↑                            ↑↑  ↑↑↑   ↑↑↑↑↑    ↑↑↑↑↑↑↑↑↑                 ↑↑   ↑↑                ↑↑      ↑↑ 
 *  ↑↑                             ↑↑   ↑↑      ↑↑↑↑↑                           ↑↑   ↑↑               ↑       ↑↑ 
 *  ↑↑                              ↑↑↑  ↑↑↑        ↑↑↑↑↑↑↑↑↑↑↑↑↑                ↑↑↑  ↑↑              ↑       ↑↑ 
 *  ↑↑                               ↑↑↑   ↑↑↑                                    ↑↑↑  ↑↑             ↑       ↑↑ 
 *  ↑↑↑                                ↑↑↑   ↑↑                                    ↑↑   ↑↑                   ↑↑↑ 
 *  ↑↑↑     ↑ ↑                          ↑↑↑  ↑↑↑                                   ↑↑   ↑↑                  ↑↑  
 *   ↑↑↑    ↑  ↑                           ↑↑↑  ↑↑↑                                  ↑↑   ↑↑                 ↑↑  
 *   ↑↑↑     ↑ ↑                            ↑↑↑↑  ↑↑↑                                 ↑↑   ↑↑               ↑↑↑  
 *    ↑↑↑    ↑↑ ↑                             ↑↑↑↑  ↑↑↑                                ↑↑↑  ↑↑             ↑↑↑↑  
 *     ↑↑↑    ↑ ↑                               ↑↑↑↑  ↑↑↑↑                              ↑↑↑  ↑↑      ↑     ↑↑    
 *     ↑↑↑↑    ↑ ↑                                ↑↑↑↑  ↑↑↑↑                              ↑↑  ↑↑↑   ↑     ↑↑↑    
 *      ↑↑↑↑      ↑                                 ↑↑↑↑   ↑↑↑                             ↑↑↑  ↑↑       ↑↑↑↑    
 *       ↑↑↑↑      ↑                                   ↑↑↑   ↑↑↑                            ↑↑↑  ↑↑      ↑↑↑     
 *       ↑↑↑        ↑                                    ↑↑↑↑  ↑↑↑                            ↑↑↑↑     ↑↑↑↑      
 *        ↑↑↑↑       ↑                                     ↑↑↑↑ ↑↑↑                            ↑↑     ↑↑↑↑↑      
 *        ↑↑↑↑↑       ↑↑                                     ↑↑↑  ↑↑                                 ↑↑↑↑        
 *           ↑↑↑        ↑↑                                     ↑↑  ↑↑                               ↑↑↑          
 *           ↑↑↑↑        ↑↑↑                                    ↑↑  ↑↑                             ↑↑↑↑          
 *            ↑↑↑↑↑        ↑↑↑                                   ↑  ↑↑                           ↑↑↑↑↑           
 *             ↑↑↑↑↑↑         ↑↑↑                                ↑   ↑             ↑↑  ↑       ↑↑↑↑↑↑            
 *               ↑↑↑↑↑↑          ↑↑↑                             ↑  ↑↑          ↑↑           ↑↑↑↑↑↑              
 *                 ↑↑↑↑↑              ↑↑↑                       ↑↑  ↑↑      ↑↑    ↑↑↑     ↑↑↑↑↑↑                 
 *                   ↑↑↑↑↑        ↑↑      ↑↑↑                   ↑↑  ↑  ↑↑↑     ↑↑↑      ↑↑↑↑↑↑                   
 *                     ↑↑↑↑↑↑↑        ↑↑        ↑↑↑↑↑          ↑↑  ↑↑      ↑↑↑↑      ↑↑↑↑↑↑↑                     
 *                       ↑↑↑↑↑↑↑↑         ↑↑↑                   ↑↑↑↑   ↑↑↑       ↑↑↑↑↑↑↑↑↑                       
 *                          ↑↑↑↑↑↑↑↑             ↑↑↑↑↑↑↑↑↑↑    ↑↑↑↑           ↑ ↑↑↑↑↑↑↑                          
 *                             ↑↑↑↑↑↑↑↑↑↑↑                              ↑ ↑↑↑↑↑↑↑↑↑↑                             
 *                                ↑↑↑↑↑↑↑↑↑↑↑↑↑↑   ↑↑↑↑↑↑      ↑↑   ↑↑↑↑↑↑↑↑↑↑↑↑↑                                
 *                                       ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                                      
 *                                             ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑                                            
 *                                                                                                               
 */

/**
 * @title Lizcoin ERC20
 *
 * @notice The ERC-20 token Lizcoin is the governance token for the Gaming Sub-DAO of Lizard Labs.
 *      While the studio focuses on immersive, interconnected gaming experiences, the token is primarily used for
 *      yield farming and revenue distribution for active participants, protocol governance, and liquidity staking.
 *
 * @notice Token Summary:
 *      - Symbol: LIZ
 *      - Name: Lizcoin
 *      - Decimals: 18
 *      - Initial total supply: 9B (1B to be minted as staking rewards)
 *      - Final total supply: 10B (not enforced by the token contract)
 *      - Initial supply holder (initial holder) address: 0xC93c904fFE3d55E15483eF37e38ECAF8Fe003Ba7
 *      - Mintability: configurable (initially enabled, but possible to revoke forever)
 *      - Burnability: configurable (initially enabled, but possible to revoke forever)
 *      - DAO Support: supports voting delegation
 *
 * @notice Features Summary:
 *      - Supports atomic allowance modification, resolves well-known ERC20 issue with approve (arXiv:1907.00903)
 *      - Voting delegation and delegation on behalf via EIP-712 (like in Compound CMP token) - gives the token
 *        powerful governance capabilities by allowing holders to form voting groups by electing delegates
 *      - Unlimited approval feature (like in 0x ZRX token) - saves gas for transfers on behalf
 *        by eliminating the need to update “unlimited” allowance value
 *      - ERC-1363 Payable Token - ERC721-like callback execution mechanism for transfers,
 *        transfers on behalf and approvals; allows creation of smart contracts capable of executing callbacks
 *        in response to transfer or approval in a single transaction
 *      - EIP-2612: permit - 712-signed approvals - improves user experience by allowing to use a token
 *        without having an ETH to pay gas fees
 *      - EIP-3009: Transfer With Authorization - improves user experience by allowing to use a token
 *        without having an ETH to pay gas fees
 *
 * @dev Based on the https://github.com/lazy-sol/advanced-erc20 implementation
 *
 * @author Lizard Labs Core Contributors
 */
contract LizcoinERC20 is AdvancedERC20 {
	/**
	 * @dev Deploys the token smart contract,
	 *      sets token name, symbol, initial token supply
	 *
	 * @param _initialHolder initial holder of the token supply
	 */
	constructor(address _initialHolder) AdvancedERC20 (
		msg.sender, // _contractOwner smart contract owner (has minting/burning and all other permissions)
		"Lizcoin", // _name token name to set
		"LIZ", // _symbol token symbol to set
		_initialHolder, //  _initialHolder owner of the initial token supply
		// 9 bil + 15 mil + 16'358'635 + 147'227'717
		9_178_586_352 ether, // _initialSupply initial token supply (9.18 bil)
		0xFFFF // _initialFeatures RBAC features enabled initially
	) {}
}
