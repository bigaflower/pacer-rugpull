// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import './interfaces/IERC20.sol';
import './interfaces/IManagement.sol';
import './BaseERC20.sol';
import './interfaces/IUpgradedToken.sol';

contract SecurityToken  is BaseERC20 {
    uint8 public transferFlag = 1;
    bool public upgraded;
    address public upgradedAddress;
    address public management;
    bool public paused;
    address public issuer;
    
    event SetSTManagement(address indexed from, address indexed newManagement);
    event Issue(address indexed from, address indexed to, uint256 value);
    event Redeem(address indexed from, address indexed to, uint256 value);
    event Paused(bool paused);
    event Flag(uint8 transferFlag);
    event Upgrade(address newAddress);

    modifier whenNotPaused() {
        require(!paused,"Paused");
        _;
    } 

    modifier onlyManagement() {
        require(msg.sender == management,"Caller is not management");
        _;
    }

    modifier onlyContractManager() {
        require(IManagement(management).isContractManager(msg.sender),"Caller is not contract manager");
        _;
    }

    constructor(
        string memory _name, 
        address _issuer,
        uint _amount,
        address _management
    ) BaseERC20(_name) {
        require(_management!= address(0));
        management = _management;
        issuer = _issuer;
        decimals = _amount;
    }


    function transfer(
        address to, 
        uint value
    )external whenNotPaused returns (bool) {
         if(upgraded){
            return IUpgradedToken(upgradedAddress).transferByLegacy(msg.sender, to, value);
        }
        if(transferFlag == 1){
            require(IManagement(management).isWhiteContract(msg.sender)&&//发起者白名单合约		
                (IManagement(management).isWhiteInvestor(to) || IManagement(management).isRestrictInvestor(to)),'Forbid transfer');
        }else if(transferFlag == 2){
            require((IManagement(management).isWhiteContract(msg.sender)||IManagement(management).isWhiteInvestor(msg.sender) || IManagement(management).isRestrictInvestor(msg.sender)) &&
                (IManagement(management).isWhiteInvestor(to) || IManagement(management).isRestrictInvestor(to)),'Forbid transfer');//发起者平台用户
        }else{	
            require(!IManagement(management).isBlockInvestor(msg.sender),'Block');//任何地址（非block地址）
        }
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(
        address from,
        address to,
        uint value
    )external whenNotPaused  returns (bool) {
        if(upgraded){
            return IUpgradedToken(upgradedAddress).transferFromByLegacy(msg.sender, from ,to, value);
        }
        if(transferFlag == 1){
            require(IManagement(management).isWhiteContract(msg.sender)&&//发起者白名单合约
                (IManagement(management).isWhiteInvestor(from) || IManagement(management).isRestrictInvestor(from))&&
                (IManagement(management).isWhiteContract(to)||IManagement(management).isWhiteInvestor(to) || IManagement(management).isRestrictInvestor(to)),'Forbid transferFrom');
        }else if(transferFlag == 2){
            require((IManagement(management).isWhiteContract(msg.sender)||IManagement(management).isWhiteInvestor(msg.sender) || IManagement(management).isRestrictInvestor(msg.sender))&& //发起者平台用户
                (IManagement(management).isWhiteInvestor(from) || IManagement(management).isRestrictInvestor(from))&&
                (IManagement(management).isWhiteContract(to)||IManagement(management).isWhiteInvestor(to) || IManagement(management).isRestrictInvestor(to)),'Forbid transferFrom');
        }else{	
            require(!IManagement(management).isBlockInvestor(from),'Block'); //任何地址（非block地址）
        }
        if (_allowance[from][msg.sender] != MAX_INT) {
            _allowance[from][msg.sender] -=  value;
        }
        _transfer(from, to, value);
        return true;
    }
    function totalSupply() override public view returns (uint) {
        if (upgraded) {
            return IUpgradedToken(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }
    function approve(address _spender, uint _value) public override returns(bool) {
        if (upgraded) {
            return IUpgradedToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        }
    }
    function balanceOf(address who) public view override returns (uint) {
        if (upgraded) {
            return IUpgradedToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }
    function allowance(address _owner, address _spender) public view override returns (uint remaining) {
        if (upgraded) {
            return IUpgradedToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

    function setManagement(address _management) external onlyManagement  {
        require(_management!= address(0));
        management = _management;
        emit SetSTManagement(address(this),_management);
    }

    function setTransferFlag(uint8 _transferFlag) external onlyContractManager {
        transferFlag = _transferFlag;
        emit Flag(_transferFlag);
    }

    function setPause(bool _paused) external onlyContractManager {
        paused = _paused;
        emit Paused(_paused);
    }

    function issue(
        address investor,
        uint256 value
    ) external onlyContractManager  {
        if (transferFlag == 1 || transferFlag == 2){
            require(IManagement(management).isWhiteInvestor(investor) || IManagement(management).isWhiteContract(investor),"Forbid issue");
        }else{
            require(!IManagement(management).isBlockInvestor(investor),"Block"); //任何地址（非blocklist地址）
        }
        _mint(investor,value);
        emit Issue(address(this),investor,value);
    }

    function redeem(
        address investor,
        uint256 value
    ) external onlyContractManager {
        _burn(investor,value);
        emit Redeem(address(this),investor,value);
    }

    function upgrade(address _upgradedAddress) external onlyContractManager {
        require(_upgradedAddress!= address(0));
        upgraded = true;
        upgradedAddress = _upgradedAddress;
        emit Upgrade(_upgradedAddress);
    }
}
