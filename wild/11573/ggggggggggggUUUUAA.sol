// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.28;

/// @title Guau
/// @notice An ultra-optimized ERC20 test
contract Guau {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Thrown when caller is not authorized for owner-only functions
    error Unauthorized();
    /// @dev Thrown when account has insufficient balance for operation
    error InsufficientBalance();
    /// @dev Thrown when spender has insufficient allowance for operation
    error InsufficientAllowance();
    /// @dev Thrown when attempting to transfer to or from zero address
    error InvalidAddress();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          CONSTANTS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Token name with frog
    string public constant name = unicode"𓆏guau𓆏";

    /// @notice Token symbol with frog
    string public constant symbol = unicode"𓆏GUAU𓆏";

    /// @notice Number of decimals for token amounts
    uint8 public constant decimals = 18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                           STORAGE                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Total token supply
    /// @dev Storage slot 0
    uint256 public totalSupply;

    /// @notice Contract owner address
    /// @dev Storage slot 1
    address public owner;

    /// @notice Balance of each account
    /// @dev Storage slot 2 - mapping(address => uint256)
    mapping(address => uint256) public balanceOf;

    /// @notice Allowance granted by owner to spender
    /// @dev Storage slot 3 - mapping(address => mapping(address => uint256))
    mapping(address => mapping(address => uint256)) public allowance;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          MODIFIERS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Restricts function access to contract owner only
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTRUCTOR                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Initializes contract and sets deployer as owner
    /// @dev Uses assembly to set owner in storage slot 1
    constructor() payable {
        assembly {
            sstore(1, caller())
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ERC20 OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Transfers tokens from caller to recipient
    /// @dev Uses assembly for gas-optimized execution with overflow checks
    /// @param to Recipient address
    /// @param amount Amount of tokens to transfer
    /// @return success True if transfer succeeded
    function transfer(address to, uint256 amount) public returns (bool success) {
        assembly {
            // Cache caller for gas savings
            let sender := caller()
            
            // Revert if recipient is zero address
            if iszero(to) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }
            
            // Load sender balance: keccak256(abi.encode(sender, 2))
            mstore(0x00, sender)
            mstore(0x20, 2)
            let senderBalanceSlot := keccak256(0x00, 0x40)
            let senderBalance := sload(senderBalanceSlot)
            
            // Revert if insufficient balance
            if gt(amount, senderBalance) {
                mstore(0x00, 0xf4d678b8) // InsufficientBalance()
                revert(0x1c, 0x04)
            }
            
            // Update sender balance (checked math via gt above)
            sstore(senderBalanceSlot, sub(senderBalance, amount))
            
            // Load and update recipient balance: keccak256(abi.encode(to, 2))
            mstore(0x00, to)
            mstore(0x20, 2)
            let recipientBalanceSlot := keccak256(0x00, 0x40)
            let recipientBalance := sload(recipientBalanceSlot)
            
            // Check for overflow in recipient balance
            let newRecipientBalance := add(recipientBalance, amount)
            if lt(newRecipientBalance, recipientBalance) {
                // Overflow protection
                revert(0, 0)
            }
            
            sstore(recipientBalanceSlot, newRecipientBalance)
            
            // Emit Transfer(sender, to, amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                sender, 
                to
            )
        }
        return true;
    }

    /// @notice Transfers tokens from one address to another using allowance
    /// @dev Supports infinite approval pattern (max uint256 allowance is not decreased)
    /// @param from Token owner address
    /// @param to Recipient address
    /// @param amount Amount of tokens to transfer
    /// @return success True if transfer succeeded
    function transferFrom(address from, address to, uint256 amount) public returns (bool success) {
        assembly {
            let spender := caller()
            
            // Revert if from or to is zero address
            if iszero(from) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }
            if iszero(to) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }

            // Compute allowance slot: keccak256(spender, keccak256(from, 3))
            mstore(0x00, from)
            mstore(0x20, 3)
            let innerSlot := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, innerSlot)
            let allowanceSlot := keccak256(0x00, 0x40)
            let currentAllowance := sload(allowanceSlot)

            // Check and update allowance (skip if max uint256 for infinite approval)
            if iszero(eq(currentAllowance, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) {
                if lt(currentAllowance, amount) {
                    mstore(0x00, 0x13be252b) // InsufficientAllowance()
                    revert(0x1c, 0x04)
                }
                sstore(allowanceSlot, sub(currentAllowance, amount))
            }

            // Load from balance: keccak256(abi.encode(from, 2))
            mstore(0x00, from)
            mstore(0x20, 2)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            // Revert if insufficient balance
            if lt(fromBalance, amount) {
                mstore(0x00, 0xf4d678b8) // InsufficientBalance()
                revert(0x1c, 0x04)
            }

            // Update from balance
            sstore(fromBalanceSlot, sub(fromBalance, amount))

            // Load and update recipient balance: keccak256(abi.encode(to, 2))
            mstore(0x00, to)
            mstore(0x20, 2)
            let toBalanceSlot := keccak256(0x00, 0x40)
            let toBalance := sload(toBalanceSlot)
            
            // Check for overflow
            let newToBalance := add(toBalance, amount)
            if lt(newToBalance, toBalance) {
                revert(0, 0)
            }
            
            sstore(toBalanceSlot, newToBalance)

            // Emit Transfer(from, to, amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from, 
                to
            )
        }
        return true;
    }

    /// @notice Approves spender to transfer tokens on behalf of caller
    /// @dev Setting amount to max uint256 creates infinite approval
    /// @param spender Address authorized to spend tokens
    /// @param amount Maximum amount spender can transfer
    /// @return success True if approval succeeded
    function approve(address spender, uint256 amount) public returns (bool success) {
        assembly {
            let owner_ := caller()

            // Compute allowance slot: keccak256(spender, keccak256(owner, 3))
            mstore(0x00, owner_)
            mstore(0x20, 3)
            let innerSlot := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, innerSlot)
            let allowanceSlot := keccak256(0x00, 0x40)

            // Store allowance
            sstore(allowanceSlot, amount)

            // Emit Approval(owner, spender, amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925,
                owner_, 
                spender
            )
        }
        return true;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         MINT / BURN                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Mints new tokens to specified address
    /// @dev Only callable by owner. Increases total supply
    /// @param to Recipient address for minted tokens
    /// @param amount Amount of tokens to mint
    function mint(address to, uint256 amount) public onlyOwner {
        assembly {
            // Revert if recipient is zero address
            if iszero(to) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }
            
            // Update total supply with overflow check
            let totalSupplyBefore := sload(0x00)
            let totalSupplyAfter := add(totalSupplyBefore, amount)
            if lt(totalSupplyAfter, totalSupplyBefore) {
                // Overflow in total supply
                revert(0, 0)
            }
            sstore(0x00, totalSupplyAfter)

            // Update recipient balance: keccak256(abi.encode(to, 2))
            mstore(0x00, to)
            mstore(0x20, 2)
            let toBalanceSlot := keccak256(0x00, 0x40)
            let toBalance := sload(toBalanceSlot)
            
            // Check for overflow
            let newBalance := add(toBalance, amount)
            if lt(newBalance, toBalance) {
                revert(0, 0)
            }
            
            sstore(toBalanceSlot, newBalance)

            // Emit Transfer(address(0), to, amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                0x0000000000000000000000000000000000000000, 
                to
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OWNERSHIP                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Transfers ownership to new address
    /// @dev Only callable by current owner
    /// @param newOwner Address of new owner
    function transferOwnership(address newOwner) public onlyOwner {
        assembly {
            // Revert if new owner is zero address
            if iszero(newOwner) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }
            
            let previousOwner := caller()
            
            // Update owner storage slot
            sstore(1, newOwner)

            // Emit OwnershipTransferred(previousOwner, newOwner)
            log3(
                0x00, 
                0x00, 
                0x8be0079c531659141344cd1fd0a4f28419497f9722a3daafe3b4186f6b6457e0, // keccak256("OwnershipTransferred(address,address)")
                previousOwner, 
                newOwner
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                            BURN                            */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @notice Burns tokens from caller's balance
    /// @dev Decreases total supply
    /// @param amount Amount of tokens to burn
    function burn(uint256 amount) public {
        assembly {
            let sender := caller()

            // Load sender balance: keccak256(abi.encode(sender, 2))
            mstore(0x00, sender)
            mstore(0x20, 2)
            let senderBalanceSlot := keccak256(0x00, 0x40)
            let senderBalance := sload(senderBalanceSlot)

            // Revert if insufficient balance
            if lt(senderBalance, amount) {
                mstore(0x00, 0xf4d678b8) // InsufficientBalance()
                revert(0x1c, 0x04)
            }

            // Update sender balance
            sstore(senderBalanceSlot, sub(senderBalance, amount))

            // Update total supply (underflow impossible due to balance check)
            let totalSupplyBefore := sload(0x00)
            sstore(0x00, sub(totalSupplyBefore, amount))

            // Emit Transfer(sender, address(0), amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                sender, 
                0x0000000000000000000000000000000000000000
            )
        }
    }

    /// @notice Burns tokens from specified address using caller's allowance
    /// @dev Decreases both allowance and total supply
    /// @param from Address to burn tokens from
    /// @param amount Amount of tokens to burn
    function burnFrom(address from, uint256 amount) public {
        assembly {
            let spender := caller()
            
            // Revert if from is zero address
            if iszero(from) {
                mstore(0x00, 0xc5723b51) // InvalidAddress()
                revert(0x1c, 0x04)
            }

            // Compute and check allowance: keccak256(spender, keccak256(from, 3))
            mstore(0x00, from)
            mstore(0x20, 3)
            let innerSlot := keccak256(0x00, 0x40)
            mstore(0x00, spender)
            mstore(0x20, innerSlot)
            let allowanceSlot := keccak256(0x00, 0x40)
            let currentAllowance := sload(allowanceSlot)

            // Update allowance (skip if max uint256)
            if iszero(eq(currentAllowance, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)) {
                if lt(currentAllowance, amount) {
                    mstore(0x00, 0x13be252b) // InsufficientAllowance()
                    revert(0x1c, 0x04)
                }
                sstore(allowanceSlot, sub(currentAllowance, amount))
            }

            // Load from balance: keccak256(abi.encode(from, 2))
            mstore(0x00, from)
            mstore(0x20, 2)
            let fromBalanceSlot := keccak256(0x00, 0x40)
            let fromBalance := sload(fromBalanceSlot)

            // Revert if insufficient balance
            if lt(fromBalance, amount) {
                mstore(0x00, 0xf4d678b8) // InsufficientBalance()
                revert(0x1c, 0x04)
            }

            // Update from balance
            sstore(fromBalanceSlot, sub(fromBalance, amount))

            // Update total supply
            let totalSupplyBefore := sload(0x00)
            sstore(0x00, sub(totalSupplyBefore, amount))

            // Emit Transfer(from, address(0), amount)
            mstore(0x00, amount)
            log3(
                0x00, 
                0x20, 
                0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef,
                from, 
                0x0000000000000000000000000000000000000000
            )
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                            EVENTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Emitted when tokens are approved for spending
    /// @param owner Token owner granting approval
    /// @param spender Address granted spending rights
    /// @param amount Amount of tokens approved
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /// @dev Emitted when tokens are transferred
    /// @param from Sender address (zero address for minting)
    /// @param to Recipient address (zero address for burning)
    /// @param amount Amount of tokens transferred
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @dev Emitted when ownership is transferred
    /// @param previousOwner Previous owner address
    /// @param newOwner New owner address
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}