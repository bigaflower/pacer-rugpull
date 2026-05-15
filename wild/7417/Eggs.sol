/****************************************************
 *                                                  *
 *                EGGS Token (EGGS)                 *
 *                ERC-20721 Standard                *
 *                                                  *
 *  • Total Supply: 256 tokens only                 *
 *  • Initial Liquidity: 1 ETH + 128 EGGS           *
 *  • Mint Price: 0.1 ETH from contract             *
 *  • Available on Uniswap & OpenSea                *
 *                                                  *
 *   Official Links:                                *
 *  - Website: https://eggs.wtf                     *
 *  - X (Twitter): https://x.com/eggs20721          *
 *  - Telegram: https://t.me/eggs20721              *
 *                                                  *
 ****************************************************/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Metadata.sol";



interface Receiver {
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns (bytes4);
}

interface Router {
	function WETH() external pure returns (address);
	function factory() external pure returns (address);
	function addLiquidityETH(address, uint256, uint256, uint256, address, uint256) external payable returns (uint256, uint256, uint256);
}

interface Factory {
	function createPair(address, address) external returns (address);
}


contract Eggs {

	uint256 constant private UINT_MAX = type(uint256).max;
	uint256 constant private TOTAL_SUPPLY = 256;
	uint256 constant private LIQUIDITY_TOKENS = 128;
	Router constant private ROUTER = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

	uint256 constant private M1 = 0x5555555555555555555555555555555555555555555555555555555555555555;
	uint256 constant private M2 = 0x3333333333333333333333333333333333333333333333333333333333333333;
	uint256 constant private M4 = 0x0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f;
	uint256 constant private H01 = 0x0101010101010101010101010101010101010101010101010101010101010101;
	bytes32 constant private TRANSFER_TOPIC = keccak256(bytes("Transfer(address,address,uint256)"));
	bytes32 constant private APPROVAL_TOPIC = keccak256(bytes("Approval(address,address,uint256)"));

	uint256 constant public MINT_COST = 0.1 ether;

	uint8 constant public decimals = 0;

	struct User {
		bytes32 mask;
		mapping(address => uint256) allowance;
		mapping(address => bool) approved;
	}

	struct Info {
		bytes32 salt;
		address pair;
		address owner;
		Metadata metadata;
		mapping(address => User) users;
		mapping(uint256 => address) approved;
		address[] holders;
	}
	Info private info;

	mapping(bytes4 => bool) public supportsInterface;


	event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
	event ERC20Transfer(bytes32 indexed topic0, address indexed from, address indexed to, uint256 tokens) anonymous;
	event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);
	event ERC20Approval(bytes32 indexed topic0, address indexed owner, address indexed spender, uint256 tokens) anonymous;
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);


	modifier _onlyOwner() {
		require(msg.sender == owner());
		_;
	}


	constructor() payable {
		require(msg.value > 0);
		info.owner = 0xee112A6CaAFf9d16D12433F5C952ce871Ca95418;
		info.metadata = new Metadata();
		supportsInterface[0x01ffc9a7] = true; // ERC-165
		supportsInterface[0x80ac58cd] = true; // ERC-721
		supportsInterface[0x5b5e139f] = true; // Metadata
		info.salt = keccak256(abi.encodePacked("Salt:", blockhash(block.number - 1)));
	}

	function setOwner(address _owner) external _onlyOwner {
		info.owner = _owner;
	}

	function setMetadata(Metadata _metadata) external _onlyOwner {
		info.metadata = _metadata;
	}


	function initialize() external {
		require(pair() == address(0x0));
		address _this = address(this);
		address _weth = ROUTER.WETH();
		info.users[_this].mask = bytes32(UINT_MAX);
		info.holders.push(_this);
		emit ERC20Transfer(TRANSFER_TOPIC, address(0x0), _this, TOTAL_SUPPLY);
		for (uint256 i = 0; i < TOTAL_SUPPLY; i++) {
			emit Transfer(address(0x0), _this, TOTAL_SUPPLY + i + 1);
		}
		_approveERC20(_this, address(ROUTER), LIQUIDITY_TOKENS);
		info.pair = Factory(ROUTER.factory()).createPair(_weth, _this);
		ROUTER.addLiquidityETH{value:_this.balance}(_this, LIQUIDITY_TOKENS, 0, 0, owner(), block.timestamp);
		_transferERC20(_this, 0xee112A6CaAFf9d16D12433F5C952ce871Ca95418, 10); // marketing + giveaways
		_transferERC20(_this, owner(), 10); // developer tokens
	}

	function mint(uint256 _tokens) external payable {
		address _this = address(this);
		uint256 _available = balanceOf(_this);
		require(_tokens <= _available);
		uint256 _cost = _tokens * MINT_COST;
		require(msg.value >= _cost);
		_transferERC20(_this, msg.sender, _tokens);
		payable(owner()).transfer(_cost);
		if (msg.value > _cost) {
			payable(msg.sender).transfer(msg.value - _cost);
		}
	}
	
	function approve(address _spender, uint256 _tokens) external returns (bool) {
		if (_tokens > TOTAL_SUPPLY && _tokens <= 2 * TOTAL_SUPPLY) {
			_approveNFT(_spender, _tokens);
		} else {
			_approveERC20(msg.sender, _spender, _tokens);
		}
		return true;
	}

	function setApprovalForAll(address _operator, bool _approved) external {
		info.users[msg.sender].approved[_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	function transfer(address _to, uint256 _tokens) external returns (bool) {
		_transferERC20(msg.sender, _to, _tokens);
		return true;
	}

	function transferFrom(address _from, address _to, uint256 _tokens) external returns (bool) {
		if (_tokens > TOTAL_SUPPLY && _tokens <= 2 * TOTAL_SUPPLY) {
			_transferNFT(_from, _to, _tokens);
		} else {
			uint256 _allowance = allowance(_from, msg.sender);
			require(_allowance >= _tokens);
			if (_allowance != UINT_MAX) {
				info.users[_from].allowance[msg.sender] -= _tokens;
			}
			_transferERC20(_from, _to, _tokens);
		}
		return true;
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
		safeTransferFrom(_from, _to, _tokenId, "");
	}

	function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public {
		_transferNFT(_from, _to, _tokenId);
		uint32 _size;
		assembly {
			_size := extcodesize(_to)
		}
		if (_size > 0) {
			require(Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) == 0x150b7a02);
		}
	}

	function bulkTransfer(address _to, uint256[] memory _tokenIds) external {
		_transferNFTs(_to, _tokenIds);
	}
	

	function owner() public view returns (address) {
		return info.owner;
	}

	function pair() public view returns (address) {
		return info.pair;
	}

	function holders() public view returns (address[] memory) {
		return info.holders;
	}

	function salt() external view returns (bytes32) {
		return info.salt;
	}

	function metadata() external view returns (address) {
		return address(info.metadata);
	}

	function name() external view returns (string memory) {
		return info.metadata.name();
	}

	function symbol() external view returns (string memory) {
		return info.metadata.symbol();
	}

	function tokenURI(uint256 _tokenId) public view returns (string memory) {
		return info.metadata.tokenURI(_tokenId);
	}

	function totalSupply() public pure returns (uint256) {
		return TOTAL_SUPPLY;
	}

	function maskOf(address _user) public view returns (bytes32) {
		return info.users[_user].mask;
	}

	function balanceOf(address _user) public view returns (uint256) {
		return _popcount(maskOf(_user));
	}

	function allowance(address _user, address _spender) public view returns (uint256) {
		return info.users[_user].allowance[_spender];
	}

	function ownerOf(uint256 _tokenId) public view returns (address) {
		unchecked {
			require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
			bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
			address[] memory _holders = holders();
			for (uint256 i = 0; i < _holders.length; i++) {
				if (maskOf(_holders[i]) & _mask == _mask) {
					return _holders[i];
				}
			}
			return address(0x0);
		}
	}

	function getApproved(uint256 _tokenId) public view returns (address) {
		require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
		return info.approved[_tokenId];
	}

	function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
		return info.users[_owner].approved[_operator];
	}

	function getToken(uint256 _tokenId) public view returns (address tokenOwner, address approved, string memory uri) {
		return (ownerOf(_tokenId), getApproved(_tokenId), tokenURI(_tokenId));
	}

	function getTokens(uint256[] memory _tokenIds) external view returns (address[] memory owners, address[] memory approveds, string[] memory uris) {
		uint256 _length = _tokenIds.length;
		owners = new address[](_length);
		approveds = new address[](_length);
		uris = new string[](_length);
		for (uint256 i = 0; i < _length; i++) {
			(owners[i], approveds[i], uris[i]) = getToken(_tokenIds[i]);
		}
	}


	function _approveERC20(address _owner, address _spender, uint256 _tokens) internal {
		info.users[_owner].allowance[_spender] = _tokens;
		emit ERC20Approval(APPROVAL_TOPIC, _owner, _spender, _tokens);
	}

	function _approveNFT(address _spender, uint256 _tokenId) internal {
		bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
		require(maskOf(msg.sender) & _mask == _mask);
		info.approved[_tokenId] = _spender;
		emit Approval(msg.sender, _spender, _tokenId);
	}
	
	function _transferERC20(address _from, address _to, uint256 _tokens) internal {
		unchecked {
			bytes32 _mask;
			uint256 _pos = 0;
			uint256 _count = 0;
			uint256 _n = uint256(maskOf(_from));
			uint256[] memory _tokenIds = new uint256[](_tokens);
			while (_n > 0 && _count < _tokens) {
				if (_n & 1 == 1) {
					_mask |= bytes32(1 << _pos);
					_tokenIds[_count++] = TOTAL_SUPPLY + _pos + 1;
				}
				_pos++;
				_n >>= 1;
			}
			require(_count == _tokens);
			require(maskOf(_from) & _mask == _mask);
			_transfer(_from, _to, _mask, _tokenIds);
		}
	}
	
	function _transferNFT(address _from, address _to, uint256 _tokenId) internal {
		unchecked {
			require(_tokenId > TOTAL_SUPPLY && _tokenId <= 2 * TOTAL_SUPPLY);
			bytes32 _mask = bytes32(1 << (_tokenId - TOTAL_SUPPLY - 1));
			require(maskOf(_from) & _mask == _mask);
			require(msg.sender == _from || msg.sender == getApproved(_tokenId) || isApprovedForAll(_from, msg.sender));
			uint256[] memory _tokenIds = new uint256[](1);
			_tokenIds[0] = _tokenId;
			_transfer(_from, _to, _mask, _tokenIds);
		}
	}
	
	function _transferNFTs(address _to, uint256[] memory _tokenIds) internal {
		unchecked {
			bytes32 _mask;
			for (uint256 i = 0; i < _tokenIds.length; i++) {
				_mask |= bytes32(1 << (_tokenIds[i] - TOTAL_SUPPLY - 1));
			}
			require(_popcount(_mask) == _tokenIds.length);
			require(maskOf(msg.sender) & _mask == _mask);
			_transfer(msg.sender, _to, _mask, _tokenIds);
		}
	}

	function _transfer(address _from, address _to, bytes32 _mask, uint256[] memory _tokenIds) internal {
		unchecked {
			require(_tokenIds.length > 0);
			for (uint256 i = 0; i < _tokenIds.length; i++) {
				if (getApproved(_tokenIds[i]) != address(0x0)) {
					info.approved[_tokenIds[i]] = address(0x0);
					emit Approval(address(0x0), address(0x0), _tokenIds[i]);
				}
				emit Transfer(_from, _to, _tokenIds[i]);
			}
			info.users[_from].mask ^= _mask;
			bool _from0 = maskOf(_from) == 0x0;
			bool _to0 = maskOf(_to) == 0x0;
			info.users[_to].mask |= _mask;
			if (_from0) {
				uint256 _index;
				address[] memory _holders = holders();
				for (uint256 i = 0; i < _holders.length; i++) {
					if (_holders[i] == _from) {
						_index = i;
						break;
					}
				}
				if (_to0) {
					info.holders[_index] = _to;
				} else {
					info.holders[_index] = _holders[_holders.length - 1];
					info.holders.pop();
				}
			} else if (_to0) {
				info.holders.push(_to);
			}
			require(maskOf(_from) & maskOf(_to) == 0x0);
			emit ERC20Transfer(TRANSFER_TOPIC, _from, _to, _tokenIds.length);
		}
	}


	function _popcount(bytes32 _b) internal pure returns (uint256) {
		uint256 _n = uint256(_b);
		if (_n == UINT_MAX) {
			return 256;
		}
		unchecked {
			_n -= (_n >> 1) & M1;
			_n = (_n & M2) + ((_n >> 2) & M2);
			_n = (_n + (_n >> 4)) & M4;
			_n = (_n * H01) >> 248;
		}
		return _n;
	}
}


contract Deploy {
	Eggs immutable public eggs;
	constructor() payable {
		eggs = new Eggs{value:msg.value}();
		eggs.initialize();
	}
}