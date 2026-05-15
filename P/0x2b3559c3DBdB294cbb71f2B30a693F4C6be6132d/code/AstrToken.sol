// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";
import "IUniswapV2Pair.sol";

contract AstrToken is Ownable, ERC20{
    bool public enableFee;
    bool public limited;
    uint256 public maxHoldingAmount;
    uint256 public minHoldingAmount;
    address public uniswapV2Pair;
    address public nodeFeeAddress;
    mapping(address => bool) public blacklists;

    uint256 distributorGas = 500000;
    address[] public shareholders;
    uint256 currentIndex;
    mapping(address => bool) public _updated;
    uint256 public minPeriod = 1 minutes;
    mapping(address => uint256) public shareholderIndexes;
    uint256 public minDistribution = 200 * 1e18;
    uint256 public LPFeefenhong;

    address public NFTMarket;

    constructor() ERC20("Lucky star Currency", "LSC") {
        _mint(msg.sender, 10_000_000 * 10 ** super.decimals());
    }

     modifier onlyNFTMarket() {
        if (msg.sender != NFTMarket) revert OnlyCallByNFTMarket();
        _;
    }

    function blacklist(
        address _address,
        bool _isBlacklisting
    ) external onlyOwner {
        blacklists[_address] = _isBlacklisting;
    }

    function setRule(
        bool _limited,
        bool _enableFee,
        address _uniswapV2Pair,
        uint256 _maxHoldingAmount,
        uint256 _minHoldingAmount,
        address _nodeFeeAddress,
        address _NFTMarket
    ) external onlyOwner {
        limited = _limited;
        enableFee = _enableFee;
        uniswapV2Pair = _uniswapV2Pair;
        maxHoldingAmount = _maxHoldingAmount;
        minHoldingAmount = _minHoldingAmount;
        nodeFeeAddress = _nodeFeeAddress;
        NFTMarket = _NFTMarket;
    }

    function _beforeTokenTransfer(
        address from, 
        address to,
        uint256 amount
    ) internal virtual override {
        require(!blacklists[to] && !blacklists[from], "Blacklisted");

        if (uniswapV2Pair == address(0)) {
            require(from == owner() || to == owner(), "trading is not started");
            return;
        }

        if (limited && from == uniswapV2Pair) {
            require(
                super.balanceOf(to) + amount <= maxHoldingAmount &&
                    super.balanceOf(to) + amount >= minHoldingAmount,
                "Forbid"
            );
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool takeFee = true;
        bool isAddLdx;
        bool isDelLdx;
        if (to == uniswapV2Pair) {
            isAddLdx = _isAddLiquidityV1();
        } else if (from == uniswapV2Pair) {
            isDelLdx = _isDelLiquidityV1();
        }
        if (isAddLdx || isDelLdx) {
            takeFee = false;
        } else {
            if (from == uniswapV2Pair) {} else if (
                to == uniswapV2Pair
            ) {} else {
                takeFee = false;
            }
        }
        if (!enableFee) {
            takeFee = false;
        }

        _tokenTransfer(from, to, amount, takeFee);

        if (uniswapV2Pair != address(0) && from != uniswapV2Pair) {
            setShare(from);
        }

        if (uniswapV2Pair != address(0) && to != uniswapV2Pair) {
            setShare(to);
        }

        if (
            balanceOf(address(this)) >= minDistribution &&
            from != address(this) &&
            LPFeefenhong + minPeriod <= block.timestamp
        ) {
            process(distributorGas);
            LPFeefenhong = block.timestamp;
        }
    }

    function setShare(address shareholder) private {
        if (_updated[shareholder]) {
            if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0)
                quitShare(shareholder);
            return;
        }
        if (IERC20(uniswapV2Pair).balanceOf(shareholder) == 0) return;
        addShareholder(shareholder);
        _updated[shareholder] = true;
    }

    function quitShare(address shareholder) private {
        removeShareholder(shareholder);
        _updated[shareholder] = false;
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
            shareholders.length - 1
        ];
        shareholderIndexes[
            shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function _tokenTransfer(
        address from,
        address to,
        uint256 amount,
        bool takeFee
    ) private {
        if (takeFee) {
            uint256 nodeFee = (amount * 2) / 100;
            uint256 lpFee = (amount * 1) / 100;
            uint256 transferAmount = amount - nodeFee - lpFee;
            super._transfer(from, to, transferAmount);
            super._transfer(from, nodeFeeAddress, nodeFee);
            super._transfer(from, address(this), lpFee);
            emit nodeFeeShare(from, to, transferAmount, nodeFee, lpFee);
        } else {
            super._transfer(from, to, amount);
        }
    }

    function _isAddLiquidityV1() internal view returns (bool ldxAdd) {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0, uint r1, ) = IUniswapV2Pair(address(uniswapV2Pair))
            .getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if (token0 == address(this)) {
            if (bal1 > r1) {
                uint change1 = bal1 - r1;
                ldxAdd = change1 > 1000;
            }
        } else {
            if (bal0 > r0) {
                uint change0 = bal0 - r0;
                ldxAdd = change0 > 1000;
            }
        }
    }

    function _isDelLiquidityV1() internal view returns (bool ldxDel) {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0, uint r1, ) = IUniswapV2Pair(address(uniswapV2Pair))
            .getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));

        if (token0 == address(this)) {
            if (bal1 < r1) {
                uint change1 = r1 - bal1;
                ldxDel = change1 > 1000;
            }
        } else {
            if (bal0 < r0) {
                uint change0 = r0 - bal0;
                ldxDel = change0 > 1000;
            }
        }
    }

    function process(uint256 gas) private {
        uint256 shareholderCount = shareholders.length;

        if (shareholderCount == 0) return;
        uint256 nowbanance = balanceOf(address(this));
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while (gasUsed < gas && iterations < shareholderCount) {
            if (currentIndex >= shareholderCount) {
                currentIndex = 0;
            }

            uint256 amount = (nowbanance *
                (IERC20(uniswapV2Pair).balanceOf(shareholders[currentIndex]))) /
                (IERC20(uniswapV2Pair).totalSupply());
            if (amount < 1e18) {
                currentIndex++;
                iterations++;
                return;
            }
            if (balanceOf(address(this)) < amount) return;
            distributeDividend(shareholders[currentIndex], amount);

            gasUsed += gasLeft - gasleft();
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function distributeDividend(address shareholder, uint256 amount) internal {
        super._transfer(address(this), shareholder, amount);
    }

    // only market
    function burn(address user,uint256 value) external onlyNFTMarket(){
        _burn(user, value);
    }

    function burn(uint256 value) external onlyNFTMarket(){
        _burn(msg.sender,value);
    }

    event nodeFeeShare(
        address indexed from,
        address indexed to,
        uint256 transferAmount,
        uint256 nodeFee,
        uint256 lpFee
    );
}

error OnlyCallByNFTMarket();