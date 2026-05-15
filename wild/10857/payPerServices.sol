// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./EIP3009.sol";
import "./IDAI.sol";
import "./IERC20.sol";

contract payPerServices is Ownable{
    using Address for address;
    using SafeMath for uint256;

    address public USDC;
    address public USDT;
    address public DAI;
    address public forward;
    address public forwardUSA;
    address public ETHplaceholder = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    mapping (uint8 => mapping (address => uint256)) public servicesPrices;

    event Payment(
        string currency,
        uint256 amount,
        string id,
        address sender,
        address forwardTo,
        uint8 service
    );

    constructor(
        address _USDC,
        address _USDT,
        address _DAI,
        address _forward,
        address _forwardUSA
        ){
        USDC = _USDC;
        USDT = _USDT;
        DAI = _DAI;
        forward = _forward;
        forwardUSA = _forwardUSA;
    }

    function payUSDC(string memory _id, bool _world, uint8 _service) external returns(bool) {
        address to = getTo(_world);
        uint256 priceUSDC = getPrice(_service, USDC);
        require(priceUSDC > 0, "Invalid service-token-price Pointer");
        IERC20(USDC).transferFrom(msg.sender, to, priceUSDC); 
        emit Payment("USDC", priceUSDC, _id, msg.sender, to, _service);
        return true; 
    }

    function payUSDCWithPermit(
        string memory _id, 
        bool _world,
        address _from,
        address _to,
        uint256 _value,
        uint256 _validAfter,
        uint256 _validBefore,
        bytes32 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s, 
        uint8 _service
        ) external{
            address to = getTo(_world);
            uint256 priceUSDC = getPrice(_service, USDC);
            require(priceUSDC > 0, "Invalid service-token-price Pointer");
            require(_value == priceUSDC ,"Wrong price");
            EIP3009(USDC).transferWithAuthorization( _from, to, _value, _validAfter, _validBefore, _nonce, _v, _r, _s);
            emit Payment("USDC", _value, _id, _from, to, _service);
    }

    function payDAI(string memory _id, bool _world, uint8 _service ) external returns(bool) {
        address to = getTo(_world);
        uint256 priceDAI = getPrice(_service, DAI);
        require(priceDAI > 0, "Invalid service-token-price Pointer");
        IERC20(DAI).transferFrom(msg.sender, to, priceDAI);
        emit Payment("DAI", priceDAI, _id, msg.sender, to, _service);
        return true; 
    }

    function payDAIWithPermit(
        string memory _id,
        bool _world,
        address _holder,
        address _spender,
        uint256 _nonce,
        uint256 _expiry,
        bool _allowed,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _service
        ) external {
            address to = getTo(_world);
            uint256 priceDAI = getPrice(_service, DAI);
            IDAI(DAI).permit(_holder, _spender, _nonce, _expiry, _allowed, _v, _r, _s);
            bool success = IDAI(DAI).transferFrom(_holder, to, priceDAI);
            require(success, "Dev: Token transfer failed");
            emit Payment("DAI", priceDAI, _id, _holder, to, _service);
    }

    function payUSDT(string memory _id, bool _world, uint8 _service) external returns(bool) {
        address to = getTo(_world);
        uint256 priceUSDT = getPrice(_service, USDT);
        require(priceUSDT > 0, "Invalid service-token-price Pointer");
        IERC20(USDT).transferFrom(msg.sender, to, priceUSDT);
        emit Payment("USDT", priceUSDT, _id, msg.sender, to, _service);
        return true;
    }

    function payETH(string memory _id, bool _world, uint8 _service) external payable returns(bool) {
        address to = getTo(_world);
        uint256 priceETH = getPrice(_service, ETHplaceholder);
        require(priceETH > 0, "Invalid service-token-price Pointer");
        require(msg.value >= priceETH, "Dev: invalid amount");
        (bool sent, bytes memory data) = to.call{value: msg.value}("");
        require(sent, "Dev: Ether payment error");
        emit Payment("ETH", msg.value, _id, msg.sender, to ,_service);
        return true;
    }

    function setForwarders(address _forwardUSA, address _forward) external onlyOwner returns(bool) {
        forwardUSA = _forwardUSA;
        forward = _forward;
        return true;
    }

    function recoverEther(uint256 _amount) external onlyOwner returns(bool){
        payable(owner()).transfer(_amount);
        return true;
    }

    function recoverERC20(address _tokenAddress, uint256 _amount) external onlyOwner returns(bool){
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(owner(), _amount);
        return true;
    }

    function getTo(bool _world) internal view returns(address){
        address to;
        if (_world) {
          to = forward;
        } else {
          to = forwardUSA;
        }
        return to;
    }

    function getPrice(uint8 _service, address _tokenToPay) public view returns(uint256){
        uint256 price = servicesPrices[_service][_tokenToPay];
        return price;
    }

    function setPayment(uint8 _service, address _tokenToPay, uint256 _price) external onlyOwner returns(bool) {
        servicesPrices[_service][_tokenToPay] = _price;
        return true;
    }

    function bulkSetPayment(
        uint8 _service, 
        address[] memory _tokensToPay, 
        uint256[] memory _prices
    ) external onlyOwner returns(bool) {
        require(_tokensToPay.length == _prices.length, "Input arrays must have the same length");
        for (uint i = 0; i < _tokensToPay.length; i++) {
            servicesPrices[_service][_tokensToPay[i]] = _prices[i];
        }
        return true;
    }
}

