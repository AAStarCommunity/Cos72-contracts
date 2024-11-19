// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CommunityStoreV3 is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    struct StoreInfo {
        StoreSettig setting;
        GoodsSetting[] goodsList;
        GoodsPurchase[] userPurchaseHistory;
        GoodsAccountInfo[] goodsAccountInfos;
        bool isAdmin;
        address implementation;
        uint256[] goodsSalesAmount;
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

    struct GoodsPurchase {
        uint256 goodsId;
        uint256 amount;
        uint256 price;
        uint256 time;
        address account;
    }

    struct GoodsAccountInfo {
        uint256 goodsId;
        uint256 buyAllowance;
        uint256 payTokenBalance;
    }

    StoreSettig public setting;
    GoodsSetting[] public goodsList;
    GoodsPurchase[] public goodsPurchaseList;

    mapping(address => GoodsPurchase[]) public userPurchaseHistory;
    mapping(uint256 => uint256) public goodsSalesAmountMap;

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

    function getStoreInfo(
        address account
    ) external view returns (StoreInfo memory) {
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
        StoreInfo memory storeInfo = StoreInfo({
            setting: setting,
            goodsList: goodsList,
            userPurchaseHistory: userPurchaseHistory[account],
            goodsAccountInfos: goodsAccountInfos,
            isAdmin: owner() == account,
            implementation: getImplementationAddress(),
            goodsSalesAmount: goodsSalesAmount
        });
        return storeInfo;
    }

    function getImplementationAddress() public view returns (address) {
        return ERC1967Utils.getImplementation();
    }

    function buy(uint256 goodsId, uint256 count) public payable {
        GoodsPurchase[] storage userGoodsPurchases = userPurchaseHistory[
            msg.sender
        ];
        GoodsSetting memory goodsSetting = goodsList[goodsId - 1];
        GoodsPurchase memory goodsPurchase = GoodsPurchase({
            goodsId: goodsId,
            amount: count,
            price: goodsSetting.price,
            time: block.timestamp,
            account: msg.sender
        });
        userGoodsPurchases.push(goodsPurchase);
        goodsPurchaseList.push(goodsPurchase);
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

    function getPurchaseHistory(
        address account
    ) external view returns (GoodsPurchase[] memory) {
        return userPurchaseHistory[account];
    }

    function addGoods(GoodsSetting memory _setting) public onlyOwner {
        _setting.id = goodsList.length + 1;
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
    }

    function updateGoodsSetting(
        uint256 goodsId,
        GoodsSetting memory _setting
    ) public onlyOwner {
        goodsList[goodsId - 1] = _setting;
    }

    function enableGoods(uint256 goodsId) public onlyOwner {
        goodsList[goodsId - 1].enabled = true;
    }

    function disableGoods(uint256 goodsId) public onlyOwner {
        goodsList[goodsId - 1].enabled = false;
    }

    function updateSettng(StoreSettig memory _setting) public onlyOwner {
        setting = _setting;
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
    }

    function updateGoodsPrice(uint256 goodsId, uint256 price) public onlyOwner {
        goodsList[goodsId - 1].price = price;
    }

    function updateGoodsName(
        uint256 goodsId,
        string memory name
    ) public onlyOwner {
        goodsList[goodsId - 1].name = name;
    }

    function updateGoodsDescription(
        uint256 goodsId,
        string memory description
    ) public onlyOwner {
        goodsList[goodsId - 1].description = description;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}

    function upgrade(address newImplementation) public onlyOwner {
        upgradeToAndCall(newImplementation, "");
    }
}
