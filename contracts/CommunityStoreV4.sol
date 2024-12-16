// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract CommunityStoreV4 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct StoreInfo {
        StoreSettig setting;
        GoodsSetting[] goodsList;
        address implementation;
        uint256 version;
    }

    struct StoreSettig {
        string name;
        string description;
        string image;
        address receiver;
    }

    struct GoodsSetting {
        uint256 id;
        string name;
        string description;
        string[] images;
        string[] descImages;
        address payToken;
        string payTokenSymbol;
        uint256 payTokenDecimals;
        uint256 amount;
        uint256 price;
        bool enabled;
    }

    struct GoodsOrder {
        uint256 goodsId;
        uint256 amount;
        uint256 price;
        uint256 time;
        uint256 accountId;
        uint256 id;
        uint256 status;
    }

    struct GoodsOrderDetail {
        GoodsSetting goodsSetting;
        uint256 amount;
        uint256 price;
        uint256 time;
        address account;
        uint256 id;
        uint256 status;
    }

    struct GoodsAccountInfo {
        uint256 goodsId;
        uint256 buyAllowance;
        uint256 payTokenBalance;
    }

    struct GoodsStatInfo {
        uint256 goodsId;
        uint256 salesAmount;
    }

    StoreSettig public setting;
    GoodsSetting[] public goodsList;


    GoodsOrder[] public allOrderList;

    mapping(address => uint256[]) public accountOrderList;
    mapping(uint256 => uint256) public goodsSalesAmountMap;
    mapping(uint256 => uint256[]) public goodsOrderList;
    mapping(address => uint256) public accountIdMap;
    uint256 public storeInfoVersion;
    address[] public accountList;
    uint256 public ORDER_STATUS_PAYED = 1;
    uint256 public ORDER_STATUS_CLAIMED = 2;



    function initialize(
        address initialOwner,
        StoreSettig memory _setting
    ) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        setting.name = _setting.name;
        setting.description = _setting.description;
        setting.image = _setting.image;
        setting.receiver = _setting.receiver;
    }

    /* ============ External Getters ============ */

    function getGoodsList() external view returns (GoodsSetting[] memory) {
        return goodsList;
    }

    function getStoreInfo() external view returns (StoreInfo memory) {
        StoreInfo memory storeInfo = StoreInfo({
            setting: setting,
            goodsList: goodsList,
            implementation: getImplementationAddress(),
            version: storeInfoVersion
        });
        return storeInfo;
    }

    function getStoreAccountInfo(
        address account
    ) external view returns (GoodsAccountInfo[] memory) {
        uint256 goodsCount = goodsList.length;
        GoodsAccountInfo[] memory goodsAccountInfos = new GoodsAccountInfo[](
            goodsCount
        );
        uint256[] memory goodsSalesAmount = new uint256[](goodsCount);
        for (uint256 i = 0; i < goodsCount; i++) {
            GoodsSetting memory goodsSetting = goodsList[i];
            if (goodsSetting.payToken == address(0)) {
                uint256 buyAllowance = type(uint256).max;
                uint256 payTokenBalance = account.balance;
                GoodsAccountInfo memory goodsAccountInfo = GoodsAccountInfo({
                    goodsId: goodsSetting.id,
                    buyAllowance: buyAllowance,
                    payTokenBalance: payTokenBalance
                });
                goodsAccountInfos[i] = goodsAccountInfo;
            }
            else {
                uint256 buyAllowance = ERC20(goodsSetting.payToken).allowance(
                    account,
                    address(this)
                );
                uint256 payTokenBalance = ERC20(goodsSetting.payToken).balanceOf(
                    account
                );
                GoodsAccountInfo memory goodsAccountInfo = GoodsAccountInfo({
                    goodsId: goodsSetting.id,
                    buyAllowance: buyAllowance,
                    payTokenBalance: payTokenBalance
                });
                goodsAccountInfos[i] = goodsAccountInfo;
                goodsSalesAmount[i] = goodsSalesAmountMap[goodsSetting.id];
            }
        
        }
        return goodsAccountInfos;
    }

    function getStoreGoodsStatInfo() external view returns (GoodsStatInfo[] memory) {
        uint256 goodsCount = goodsList.length;
        GoodsStatInfo[] memory goodsStatInfos = new GoodsStatInfo[](
            goodsCount
        );
        for (uint256 i = 0; i < goodsCount; i++) {
            GoodsSetting memory goodsSetting = goodsList[i];
            GoodsStatInfo memory info = GoodsStatInfo({
                    goodsId: goodsSetting.id,
                    salesAmount: goodsSalesAmountMap[goodsSetting.id]
            });
            goodsStatInfos[i] = info;
        }
        return goodsStatInfos;
    }

    function getImplementationAddress() public view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function buy(uint256 goodsId, uint256 count) public payable {
          require(
                goodsId < goodsList.length,
                "The goodsId is not exist"
            );
        GoodsSetting memory goodsSetting = goodsList[goodsId];
       
        if (accountList.length == 0) {
            accountIdMap[msg.sender] = accountList.length;
            accountList.push(msg.sender);
        }
        else {
            if (accountList[accountIdMap[msg.sender]] != msg.sender) {
                accountIdMap[msg.sender] = accountList.length;
                accountList.push(msg.sender);
            }
        }
        GoodsOrder memory goodsOrder = GoodsOrder({
            goodsId: goodsId,
            amount: count,
            price: goodsSetting.price,
            time: block.timestamp,
            accountId: accountIdMap[msg.sender],
            id: allOrderList.length,
            status: ORDER_STATUS_PAYED
        });
        allOrderList.push(goodsOrder);
        accountOrderList[msg.sender].push(goodsOrder.id);
        goodsOrderList[goodsSetting.id].push(goodsOrder.id);
        goodsSalesAmountMap[goodsSetting.id] = goodsSalesAmountMap[goodsSetting.id] + count;
        if (goodsSetting.payToken == address(0)) {
            require(
                msg.value >= (goodsSetting.price * count),
                "The Payment Amount Is Too Low"
            );

            payable(setting.receiver).transfer(msg.value);
        } else {
            ERC20(goodsSetting.payToken).transferFrom(
                address(msg.sender),
                address(setting.receiver),
                goodsSetting.price * count
            );
        }
    }

    function comment(uint256 orderId, string memory comment) public {
        
    }

    function getAccountOrders(
        address account,
        uint256 startIndex,
        uint256 pageSize
    ) external view returns (GoodsOrderDetail[] memory, uint256 total) {
        uint256 orderTotal = accountOrderList[account].length;
        uint256 pageItemsCount = (startIndex + pageSize) > orderTotal ?  (orderTotal - startIndex - 1) : pageSize;
        GoodsOrderDetail[] memory orders = new GoodsOrderDetail[](
            pageItemsCount
        );
        uint256 orderIndex = startIndex;
        uint256 orderCount = 0;
        for(; (orderIndex < orderTotal) && (orderCount < pageItemsCount);) {
            GoodsOrder memory order = (allOrderList[accountOrderList[account][orderIndex]]);
            orders[orderCount] = GoodsOrderDetail({
                 goodsSetting: goodsList[order.goodsId],
                 amount: order.amount,
                 price: order.price,
                 time: order.time,
                 account: accountList[order.accountId],
                 id: order.id,
                 status: order.status
            }); 

            orderCount++;
            orderIndex++;

        }
        return (orders, orderTotal);
    }

      function getAccountOrdersTotal(
        address account
    ) external view returns (uint256 total) {

        return accountOrderList[account].length;
    }

    function getAllOrders(uint256 startIndex, uint256 pageSize) external view returns (GoodsOrderDetail[] memory, uint256 total) {
        uint256 orderTotal = allOrderList.length;
        uint256 pageItemsCount = startIndex + pageSize > orderTotal ?  (orderTotal - startIndex - 1) : pageSize;
        GoodsOrderDetail[] memory orders = new GoodsOrderDetail[](
            pageItemsCount
        );
        uint256 orderIndex = startIndex;
        uint256 orderCount = 0;
        for(; orderIndex < orderTotal && orderCount < pageItemsCount;) {
            GoodsOrder memory order = (allOrderList[orderIndex]);
            orders[orderCount] = GoodsOrderDetail({
                 goodsSetting: goodsList[order.goodsId],
                 amount: order.amount,
                 price: order.price,
                 time: order.time,
                 account: accountList[order.accountId],
                 id: order.id,
                 status: order.status
            }); 
            orderCount++;
            orderIndex++;
        }
        return (orders, orderTotal);
    }

    function getGoodsOrders(uint256 goodsId, uint256 startIndex, uint256 pageSize) external view returns (GoodsOrderDetail[] memory, uint256 total) {
        uint256 orderTotal = goodsOrderList[goodsId].length;
        uint256 pageItemsCount = startIndex + pageSize > orderTotal ?  (orderTotal - startIndex - 1) : pageSize;
        GoodsOrderDetail[] memory orders = new GoodsOrderDetail[](
            pageItemsCount
        );
        uint256 orderIndex = startIndex;
        uint256 orderCount = 0;
        for(; orderIndex < orderTotal && orderCount < pageItemsCount;) {
            GoodsOrder memory order = (allOrderList[goodsOrderList[goodsId][orderIndex]]);
            orders[orderCount] = GoodsOrderDetail({
                 goodsSetting: goodsList[order.goodsId],
                 amount: order.amount,
                 price: order.price,
                 time: order.time,
                 account: accountList[order.accountId],
                 id: order.id,
                 status: order.status
            }); 
            orderCount++;
            orderIndex++;
        }
        return (orders, orderTotal);
    }

    function addGoods(GoodsSetting memory _setting) public onlyOwner {
        _setting.id = goodsList.length;
        if (_setting.payToken == address(0)) {
            _setting.payTokenSymbol = "ETH";
            _setting.payTokenDecimals = 18;
        }
        else {
            ERC20 tokenContract = ERC20(_setting.payToken);
            _setting.payTokenSymbol = tokenContract.symbol();
            _setting.payTokenDecimals = tokenContract.decimals();
        }
        goodsList.push(_setting);
        storeInfoVersion++;
    }

    function claimOrder(uint256 orderId, bytes calldata signature) public onlyOwner {
        GoodsOrder storage order = allOrderList[orderId];
        bytes32 hash = keccak256(abi.encodePacked(order.goodsId, order.amount, order.price, accountList[order.accountId], order.id, order.status));
        bytes32 message = MessageHashUtils.toEthSignedMessageHash(hash);
        address signer = ECDSA.recover(message, signature);
        require(
                signer == accountList[order.accountId],
                "Order account is Valid"
            );
        require(
                order.status == ORDER_STATUS_CLAIMED,
                "Order is claimed"
            );
        order.status = ORDER_STATUS_CLAIMED;
    }

    function updateGoodsSetting(
        uint256 goodsId,
        GoodsSetting memory _setting
    ) public onlyOwner {
        goodsList[goodsId - 1] = _setting;
        storeInfoVersion++;
    }

    function enableGoods(uint256 goodsId) public onlyOwner {
        goodsList[goodsId - 1].enabled = true;
        storeInfoVersion++;
    }

    function disableGoods(uint256 goodsId) public onlyOwner {
        goodsList[goodsId - 1].enabled = false;
        storeInfoVersion++;
    }

    function updateSettng(StoreSettig memory _setting) public onlyOwner {
        setting = _setting;
        storeInfoVersion++;
    }

    function updateGoodsPayToken(
        uint256 goodsId,
        address payToken
    ) public onlyOwner {
        goodsList[goodsId - 1].payToken = payToken;
        if (payToken == address(0)) {
            goodsList[goodsId - 1].payTokenSymbol = "ETH";
            goodsList[goodsId - 1].payTokenDecimals = 18;
        }
        else {
            ERC20 tokenContract = ERC20(payToken);
            goodsList[goodsId - 1].payTokenSymbol = tokenContract.symbol();
            goodsList[goodsId - 1].payTokenDecimals = tokenContract.decimals();
        }
        storeInfoVersion++;
    }

    // function updateGoodsPrice(uint256 goodsId, uint256 price) public onlyOwner {
    //     goodsList[goodsId - 1].price = price;
    //     storeInfoVersion++;
    // }

    // function updateGoodsName(
    //     uint256 goodsId,
    //     string memory name
    // ) public onlyOwner {
    //     goodsList[goodsId - 1].name = name;
    //     storeInfoVersion++;
    // }

    // function updateGoodsDescription(
    //     uint256 goodsId,
    //     string memory description
    // ) public onlyOwner {
    //     goodsList[goodsId - 1].description = description;
    //     storeInfoVersion++;
    // }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function upgrade(address newImplementation) public onlyOwner {
        upgradeToAndCall(newImplementation, "");
    }
}