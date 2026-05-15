// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "./libraries/TransferHelper.sol";
import "./interfaces/IManagement.sol";
import "./interfaces/IExchangeWallet.sol";

contract SubRedManagement {
    address public management;
    address public immutable exchangeWallet;
    string public constant name = "SubRedManagement";
    mapping(address => uint) public platformFee;

    event Subscribe(
        address indexed from,
        address stToken,
        address currencyToken,
        address investor,
        uint amount
    );

    event Redeem(
        address indexed from,
        address stToken,
        address currencyToken,
        address investor,
        uint quantity
    );

    event RefundInvestorTokens(
        address indexed from,
        address[] tokenList,
        address[] investorList,
        uint[] amountList
    );

    event SettleSubscriber(
        address indexed from,
        address stToken,
        address[] investorList,
        uint[] quantityList,
        address[] currencyTokenList,
        uint[] amountList,
        uint[] feeList
    );

    event SettleRedemption(
        address indexed from,
        address stToken,
        address[] investorList,
        uint[] quantityList,
        address[] currencyTokenList,
        uint[] amountList,
        uint[] feeList
    );

    event TransferFund(
        address indexed from,
        address[] tokenList,
        address[] recipientList,
        uint256[] quantityList
    );

    event IssuerRefundFund(
        address indexed from,
        string issueId,
        address[] tokenList,
        uint[] amountList
    );

    event SetFeeForIssuer(
        address indexed from,
        string issueId,
        address[] tokenList,
        uint[] feeList
    );

    event SetManagement(address indexed from, address management);

    event TransferPlatformFee(
        address indexed from,
        address indexed token,
        uint amount
    );

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, "Expired");
        _;
    }

    modifier onlyManagement() {
        require(msg.sender == management, "Caller is not management");
        _;
    }

    modifier onlyContractManager() {
        require(
            IManagement(management).isContractManager(msg.sender),
            "Caller is not contract manager"
        );
        _;
    }

    modifier onlyWhiteInvestor(address investor) {
        require(
            IManagement(management).isWhiteInvestor(investor),
            "Investor is not white investor"
        );
        _;
    }

    modifier onlyPlatformInvestor(address investor) {
        require(
            IManagement(management).isWhiteInvestor(investor) ||
                IManagement(management).isRestrictInvestor(investor),
            "Investor is not platform investor"
        );
        _;
    }

    constructor(address _management, address _exchangeWallet) {
        require(_management != address(0));
        require(_exchangeWallet != address(0));

        management = _management;
        exchangeWallet = _exchangeWallet;
    }

    /**
     * @dev 发起申购，平台投资者向合约转入UT进行申购
     *
     * @param stToken 对应ST代币地址
     * @param currencyToken 用于购买ST代币的货币代币地址
     * @param amount 支付的金额数量
     * @param _deadline 交易的截止时间
     * 注意事项:
     * - 交易必须在截止时间之前完成
     * - 调用者必须是白名单用户
     *
     */
    function subscribe(
        address stToken,
        address currencyToken,
        uint amount,
        uint _deadline
    ) external ensure(_deadline) onlyWhiteInvestor(msg.sender) {
        require(amount > 0, "The subscription amount cannot be zero");
        TransferHelper.safeTransferFrom(
            currencyToken,
            msg.sender,
            address(this),
            amount
        );
        emit Subscribe(
            address(this),
            stToken,
            currencyToken,
            msg.sender,
            amount
        );
    }

    /**
     * @dev 发起赎回，平台投资者向合约转入ST进行赎回
     *
     * @param stToken 代币地址
     * @param currencyToken 结算的法币地址
     * @param quantity 注入的代币数量
     * @param deadline 过期时间
     *
     * Requirements:
     * - 只有平台投资者才能调用该函数
     * - 该ST要支持赎回
     * - 代币数量必须大于0
     *
     * Emits:
     * - Redeem: 成功注入资金时触发此事件
     */

    function redeem(
        address stToken,
        address currencyToken,
        uint quantity,
        uint deadline
    ) external ensure(deadline) onlyPlatformInvestor(msg.sender) {
        require(quantity > 0, "quantity > 0");
        TransferHelper.safeTransferFrom(
            stToken,
            msg.sender,
            address(this),
            quantity
        );
        emit Redeem(
            address(this),
            stToken,
            currencyToken,
            msg.sender,
            quantity
        );
    }

    /**
     * @dev 认购/赎回取消，用于特殊情况下将资金退回给投资者
     *
     * @param tokenList 需要退回的代币的地址
     * @param investorList 需要退回代币的投资者地址
     * @param amountList 每个投资者需要退回的代币金额
     *
     * Requirements:
     * - 只有合约管理员才能调用该函数
     * - UT的转入地址 investorList 必须是白名单用户
     */
    function refundInvestorTokens(
        address[] memory tokenList,
        address[] memory investorList,
        uint[] memory amountList
    ) external onlyContractManager {
        for (uint i = 0; i < investorList.length; i++) {
            require(
                IManagement(management).isWhiteInvestor(investorList[i]),
                "Investor is not white investor"
            );
            TransferHelper.safeTransfer(
                tokenList[i],
                investorList[i],
                amountList[i]
            );
        }
        emit RefundInvestorTokens(
            address(this),
            tokenList,
            investorList,
            amountList
        );
    }

    /**
     * @dev 将指定数量的ERC20代币转移到允许的地址,用于线下换币和结算发行人转移UT
     *
     * @param tokenList ERC20代币的地址
     * @param recipientList 接收代币的投资者地址
     * @param quantityList 要转移的代币数量
     * Requirements:
     * - 只有合约管理员才能调用该函数
     * - recipient必须是允许的地址
     *
     */
    function transferFund(
        address[] memory tokenList,
        address[] memory recipientList,
        uint256[] memory quantityList
    ) external onlyContractManager {
        for (uint i = 0; i < tokenList.length; i++) {
            require(
                recipientList[i] == exchangeWallet ||
                    IExchangeWallet(exchangeWallet).isAllowedAddress(
                        recipientList[i]
                    ),
                "This address is not allow address"
            );
            TransferHelper.safeTransfer(
                tokenList[i],
                recipientList[i],
                quantityList[i]
            );
        }
        emit TransferFund(
            address(this),
            tokenList,
            recipientList,
            quantityList
        );
    }

    /**
     * @dev 用于发行人退还未用完的UT/ST,赎回转入UT。
     *
     * @param issueId 对应发行的项目id
     * @param tokenList 代币地址列表
     * @param amountList 代币数量列表
     *
     * Emits:
     * - IssuerRefundFund: 当发行人退款或赎回时触发。
     */
    function issuerRefundFund(
        string memory issueId,
        address[] memory tokenList,
        uint[] memory amountList
    ) external {
        for (uint256 i = 0; i < tokenList.length; i++) {
            TransferHelper.safeTransferFrom(
                tokenList[i],
                msg.sender,
                address(this),
                amountList[i]
            );
        }

        emit IssuerRefundFund(address(this), issueId, tokenList, amountList);
    }

    /**
     * @dev 用于发行结算投资人，包括向用户转移ST，退还未使用完的代币，以及记录手续费。
     * @param stToken ST 代币的地址。
     * @param investorList 投资者地址列表。
     * @param quantityList 向每个投资者转移的 ST 代币数量列表。
     * @param currencyTokenList 代币地址列表。
     * @param amountList 退还每个投资者的未使用代币数量列表。
     * @param feeList 每个投资者申购产生的手续费。
     *
     * Requirements:
     * - 只有合约管理员可以调用此函数。
     * - 投资者必须是白名单上的投资者。
     *
     * Emits:
     * - SettleSubscriber: 当发行结算成功时触发。
     */
    function settleSubscriber(
        address stToken,
        address[] memory investorList,
        uint[] memory quantityList,
        address[] memory currencyTokenList,
        uint[] memory amountList,
        uint[] memory feeList
    ) external onlyContractManager {
        for (uint256 i = 0; i < investorList.length; i++) {
            require(
                IManagement(management).isWhiteInvestor(investorList[i]),
                "Investor is not white investor"
            );
            if (quantityList[i] > 0) {
                TransferHelper.safeTransfer(
                    stToken,
                    investorList[i],
                    quantityList[i]
                );
            }
            if (amountList[i]> 0) {
                TransferHelper.safeTransfer(
                    currencyTokenList[i],
                    investorList[i],
                    amountList[i]
                );
            }
            platformFee[currencyTokenList[i]] += feeList[i];
        }
        emit SettleSubscriber(
            address(this),
            stToken,
            investorList,
            quantityList,
            currencyTokenList,
            amountList,
            feeList
        );
    }

    /**
     * @dev 每日赎回结算，用于将ST/UT代币转给投资者
     * @param stToken ST 代币的地址。
     * @param investorList 投资者地址列表。
     * @param quantityList 退回投资者部分未赎回的ST。
     * @param currencyTokenList 代币地址列表。
     * @param amountList 投资者赎回ST得到UT的数量列表。
     * @param feeList 投资者赎回时产生的手续费列表。
     * Requirements:
     * - 只有合约管理员才能调用该函数
     *
     * Emits:
     * - SettleRedemption: 成功将ST代币和UT代币退回给投资者时触发此事件
     */
    function settleRedemption(
        address stToken,
        address[] memory investorList,
        uint[] memory quantityList,
        address[] memory currencyTokenList,
        uint[] memory amountList,
        uint[] memory feeList
    ) external onlyContractManager {
        for (uint256 i = 0; i < currencyTokenList.length; i++) {
            require(
                IManagement(management).isWhiteInvestor(investorList[i]) ||
                    IManagement(management).isRestrictInvestor(investorList[i]),
                "Investor is not platform investor"
            );
            if (quantityList[i] > 0) {
                TransferHelper.safeTransfer(
                    stToken,
                    investorList[i],
                    quantityList[i]
                );
            }
            if (amountList[i] - feeList[i] > 0) {
                TransferHelper.safeTransfer(
                    currencyTokenList[i],
                    investorList[i],
                    amountList[i] -= feeList[i]
                );
            }
            platformFee[currencyTokenList[i]] += feeList[i];
        }
        emit SettleRedemption(
            address(this),
            stToken,
            investorList,
            quantityList,
            currencyTokenList,
            amountList,
            feeList
        );
    }

    /**
     * @dev 设置平台手续费
     *
     * @param issueId 对应发行的项目id
     * @param tokenList 货币代币的地址
     * @param feeList 设置的手续费金额
     * Requirements:
     * - 只有合约管理员才能调用该函数
     *
     * Emits:
     * - SetFeeForIssuer: 成功设置平台手续费时触发此事件
     */
    function setFeeForIssuer(
        string memory issueId,
        address[] memory tokenList,
        uint[] memory feeList
    ) external onlyContractManager {
        for (uint256 i = 0; i < tokenList.length; i++) {
            platformFee[tokenList[i]] += feeList[i];
        }
        emit SetFeeForIssuer(address(this), issueId, tokenList, feeList);
    }

    function setManagement(address _management) external onlyManagement {
        require(_management != address(0), "address cannot be address(0)");
        management = _management;
        emit SetManagement(address(this), _management);
    }

    function transferPlatformFee(address currencyToken, uint amount)
        external
        onlyContractManager
    {
        address feeAddress = IManagement(management).platformFeeAddress();
        require(
            platformFee[currencyToken] >= amount,
            "PlatformFee is not enough"
        );
        platformFee[currencyToken] -= amount;
        require(feeAddress != address(0), "address cannot be address(0)");
        TransferHelper.safeTransfer(currencyToken, feeAddress, amount);
        emit TransferPlatformFee(address(this), currencyToken, amount);
    }
}
