// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface CM {
	function salt() external view returns (bytes32);
}

contract Metadata {
	
	string public name = "Eggs";
	string public symbol = "EGGS";

	string constant private TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	bytes3 constant private BG_COLOR = 0xd1d3dc;
	uint256 constant private PADDING = 2;

	struct Size {
		uint248 size;
		uint8 chance;
	}
	Size[] private sizes;

	struct Color {
		bytes3 primaryColor;
		bytes3 outlineColor;
		uint8 chance;
		string name;
	}
	Color[] private colors;

	CM immutable public eggs;


	constructor() {
		eggs = CM(msg.sender);

		// sizes
		sizes.push(Size(14, 120));
		sizes.push(Size(16, 80));
		sizes.push(Size(18, 50));
		sizes.push(Size(20, 20));
		sizes.push(Size(22, 10));
		sizes.push(Size(24, 5));
		
		// colors
		colors.push(Color(0x179629, 0x15491f, 100, "Slimy Green"));
		colors.push(Color(0xc9a91c, 0x5f5120, 75, "Pacific Blue"));
		colors.push(Color(0x009fff, 0x144d79, 55, "Orange Peel"));
		colors.push(Color(0x3bb5cf, 0x235763, 35, "Old Gold"));
		colors.push(Color(0x908070, 0x463f38, 25, "Slate Gray"));
		colors.push(Color(0xac8fe6, 0x53466d, 15, "Charm Pink"));
		colors.push(Color(0x2b2ca6, 0x191d52, 10, "Metallic Red"));
		colors.push(Color(0xa95178, 0x522b3d, 5, "Royal Purple"));
	}

	function tokenURI(uint256 _tokenId) external view returns (string memory) {
		unchecked {
			( , uint256 _size, uint256 _colorIndex) = _getTokenInfo(_tokenId);
			string memory _json = string(abi.encodePacked('{"name":"EGG #', _uint2str(_tokenId), '","description":"Experimental hybrid ERC-20 & ERC-721","external_url":"https://eggs.wtf/#/token/', _uint2str(_tokenId), '",'));
			_json = string(abi.encodePacked(_json, '"image":"', svgURI(_tokenId), '","attributes":['));
			_json = string(abi.encodePacked(_json, '{"trait_type":"Size","value":', _uint2str(_size - 2 * PADDING), '},'));
			_json = string(abi.encodePacked(_json, '{"trait_type":"Color","value":"', colors[_colorIndex].name, '"}'));
			_json = string(abi.encodePacked(_json, ']}'));
			return string(abi.encodePacked('data:application/json;base64,', _encode(bytes(_json))));
		}
	}

	function svgURI(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('data:image/svg+xml;base64,', _encode(bytes(getSVG(_tokenId)))));
	}
	
	function bmpURI(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('data:image/bmp;base64,', _encode(getBMP(_tokenId))));
	}

	function getSVG(uint256 _tokenId) public view returns (string memory) {
		return string(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" version="1.1" preserveAspectRatio="xMidYMid meet" viewBox="0 0 512 512" width="100%" height="100%"><defs><style type="text/css">svg{image-rendering:optimizeSpeed;image-rendering:-moz-crisp-edges;image-rendering:-o-crisp-edges;image-rendering:-webkit-optimize-contrast;image-rendering:pixelated;image-rendering:optimize-contrast;-ms-interpolation-mode:nearest-neighbor;background-color:', _col2str(BG_COLOR), ';background-image:url(', bmpURI(_tokenId), ');background-repeat:no-repeat;background-size:contain;background-position:50% 50%;}</style></defs></svg>'));
	}
	
	function getBMP(uint256 _tokenId) public view returns (bytes memory) {
		(bytes32 _seed, uint256 _size, uint256 _colorIndex) = _getTokenInfo(_tokenId);
		return _getBMP(_makePalette(colors[_colorIndex].primaryColor, colors[_colorIndex].outlineColor), _convertToColors(_addOutline(_expandAndReflect(_step(_step(_getInitialState(_seed, _size)))))), _size);
	}
	
	
	function _getTokenInfo(uint256 _tokenId) internal view returns (bytes32 seed, uint256 size, uint256 colorIndex) {
		unchecked {
			seed = keccak256(abi.encodePacked("Seed:", _tokenId, eggs.salt()));
			size = _sampleSize(seed);
			colorIndex = _sampleColor(seed);
		}
	}

	function _sampleSize(bytes32 _seed) internal view returns (uint256 size) {
		unchecked {
			uint256 _total = 0;
			for (uint256 i = 0; i < sizes.length; i++) {
				_total += sizes[i].chance;
			}
			uint256 _target = uint256(keccak256(abi.encodePacked("Size:", _seed))) % _total;
			_total = 0;
			for (uint256 i = 0; i < sizes.length; i++) {
				_total += sizes[i].chance;
				if (_target < _total) {
					return sizes[i].size;
				}
			}
		}
	}

	function _sampleColor(bytes32 _seed) internal view returns (uint256 colorIndex) {
		unchecked {
			uint256 _total = 0;
			for (uint256 i = 0; i < colors.length; i++) {
				_total += colors[i].chance;
			}
			uint256 _target = uint256(keccak256(abi.encodePacked("Color:", _seed))) % _total;
			_total = 0;
			for (uint256 i = 0; i < colors.length; i++) {
				_total += colors[i].chance;
				if (_target < _total) {
					return i;
				}
			}
		}
	}

	function _getInitialState(bytes32 _seed, uint256 _size) internal pure returns (uint8[][] memory state) {
		unchecked {
			uint256 _rollingSeed = uint256(keccak256(abi.encodePacked("State:", _seed)));
			state = new uint8[][](_size - 2 * PADDING - 2);
			for (uint256 y = 0; y < state.length; y++) {
				state[y] = new uint8[](_size / 2 - PADDING - 1);
				for (uint256 x = 0; x < state[y].length; x++) {
					state[y][x] = uint8(_rollingSeed % 2);
					if (_rollingSeed < type(uint16).max) {
						_rollingSeed = uint256(keccak256(abi.encodePacked("Roll:", _seed, _rollingSeed)));
					} else {
						_rollingSeed /= 2;
					}
				}
			}
		}
	}

	function _getNeighborhood(uint8[][] memory _state) internal pure returns (uint8[][] memory neighborhood) {
		unchecked {
			neighborhood = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				neighborhood[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					uint8 _count = 0;
					if (y > 0) {
						_count += _state[y - 1][x];
					}
					if (y < _state.length - 1) {
						_count += _state[y + 1][x];
					}
					if (x > 0) {
						_count += _state[y][x - 1];
					}
					if (x < _state[y].length - 1) {
						_count += _state[y][x + 1];
					}
					neighborhood[y][x] = _count;
				}
			}
		}
	}

	function _step(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			uint8[][] memory _neighborhood = _getNeighborhood(_state);
			newState = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				newState[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					newState[y][x] = ((_state[y][x] == 0 && _neighborhood[y][x] <= 1) || (_state[y][x] == 1 && (_neighborhood[y][x] == 2 || _neighborhood[y][x] == 3))) ? 1 : 0;
				}
			}
		}
	}

	function _expandAndReflect(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			newState = new uint8[][](_state.length + 2 * PADDING + 2);
			for (uint256 y = 0; y < newState.length; y++) {
				newState[y] = new uint8[](_state.length + 2 * PADDING + 2);
				for (uint256 x = 0; x < newState[y].length; x++) {
					if (y > PADDING && y <= _state.length + PADDING && x > PADDING && x <= _state.length + PADDING) {
						newState[y][x] = _state[y - PADDING - 1][x > _state[y - PADDING - 1].length + PADDING ? _state.length + PADDING - x : x - PADDING - 1];
					} else {
						newState[y][x] = 0;
					}
				}
			}
		}
	}

	function _addOutline(uint8[][] memory _state) internal pure returns (uint8[][] memory newState) {
		unchecked {
			uint8[][] memory _neighborhood = _getNeighborhood(_state);
			newState = new uint8[][](_state.length);
			for (uint256 y = 0; y < _state.length; y++) {
				newState[y] = new uint8[](_state[y].length);
				for (uint256 x = 0; x < _state[y].length; x++) {
					newState[y][x] = _state[y][x] == 0 && _neighborhood[y][x] > 0 ? 2 : _state[y][x];
				}
			}
		}
	}

	function _convertToColors(uint8[][] memory _state) internal pure returns (bytes memory cols) {
		unchecked {
			uint256 _scanline = _state[0].length;
			if (_scanline % 4 != 0) {
				_scanline += 4 - (_scanline % 4);
			}
			cols = new bytes(_state.length * _scanline);
			for (uint256 y = 0; y < _state.length; y++) {
				for (uint256 x = 0; x < _state[y].length; x++) {
					cols[(_state.length - y - 1) * _scanline + x] = bytes1(_state[y][x]);
				}
			}
		}
	}
	
	function _makePalette(bytes3 _primaryColor, bytes3 _outlineColor) internal pure returns (bytes memory) {
		unchecked {
			return abi.encodePacked(BG_COLOR, bytes1(0), _primaryColor, bytes1(0), _outlineColor, bytes1(0));
		}
	}

	function _getBMP(bytes memory _palette, bytes memory _colors, uint256 _size) internal pure returns (bytes memory) {
		unchecked {
			uint32 _bufSize = 14 + 40 + uint32(_palette.length);
			bytes memory _buf = new bytes(_bufSize - _palette.length);
			_buf[0] = 0x42;
			_buf[1] = 0x4d;
			uint32 _tmp = _bufSize + uint32(_colors.length);
			uint32 b;
			for (uint i = 2; i < 6; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_tmp = _bufSize;
			for (uint i = 10; i < 14; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_buf[14] = 0x28;
			_tmp = uint32(_size);
			for (uint i = 18; i < 22; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
				_buf[i + 4] = bytes1(uint8(b));
			}
			_buf[26] = 0x01;
			_buf[28] = 0x08;
			_tmp = uint32(_colors.length);
			for (uint i = 34; i < 38; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
			}
			_tmp = uint32(_palette.length / 4);
			for (uint i = 46; i < 50; i++) {
				assembly {
					b := and(_tmp, 0xff)
					_tmp := shr(8, _tmp)
				}
				_buf[i] = bytes1(uint8(b));
				_buf[i + 4] = bytes1(uint8(b));
			}
			return abi.encodePacked(_buf, _palette, _colors);
		}
	}

	function _uint2str(uint256 _value) internal pure returns (string memory) {
		unchecked {
			uint256 _digits = 1;
			uint256 _n = _value;
			while (_n > 9) {
				_n /= 10;
				_digits++;
			}
			bytes memory _out = new bytes(_digits);
			for (uint256 i = 0; i < _out.length; i++) {
				uint256 _dec = (_value / (10**(_out.length - i - 1))) % 10;
				_out[i] = bytes1(uint8(_dec) + 48);
			}
			return string(_out);
		}
	}

	function _col2str(bytes3 _col) internal pure returns (string memory str) {
		unchecked {
			str = "#";
			for (uint256 i = 0; i < 6; i++) {
				uint256 _hex = (uint24(_col) >> (4 * (i + 1 - 2 * (i % 2)))) % 16;
				bytes memory _char = new bytes(1);
				_char[0] = bytes1(uint8(_hex) + (_hex > 9 ? 87 : 48));
				str = string(abi.encodePacked(str, string(_char)));
			}
		}
	}

	function _encode(bytes memory _data) internal pure returns (string memory result) {
		unchecked {
			if (_data.length == 0) return '';
			string memory _table = TABLE;
			uint256 _encodedLen = 4 * ((_data.length + 2) / 3);
			result = new string(_encodedLen + 32);

			assembly {
				mstore(result, _encodedLen)
				let tablePtr := add(_table, 1)
				let dataPtr := _data
				let endPtr := add(dataPtr, mload(_data))
				let resultPtr := add(result, 32)

				for {} lt(dataPtr, endPtr) {}
				{
					dataPtr := add(dataPtr, 3)
					let input := mload(dataPtr)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
					resultPtr := add(resultPtr, 1)
					mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
					resultPtr := add(resultPtr, 1)
				}
				switch mod(mload(_data), 3)
				case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
				case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
			}
			return result;
		}
	}
}