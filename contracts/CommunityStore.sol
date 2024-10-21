// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CommunityStore is Initializable, OwnableUpgradeable, UUPSUpgradeable
{
    struct StoreInfo {
       StoreSettig setting;
       GoodsSetting[] goodsList;
       GoodsPurchase [] userPurchaseHistory;
       GoodsAccountInfo [] goodsAccountInfos;
    }

    struct StoreSettig {
        string name;
        string description;
        string image;
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
        address receiver;
        uint256 amount;
        uint256 price;
        bool enabled;
    }

    struct GoodsPurchase {
        uint256 goodsId;
        uint256 amount;
        uint256 price;
        uint256 time;
    }

    struct GoodsAccountInfo {
        uint256 goodsId;
        uint256 buyAllowance;
        // accountInfo.stakingAllowance = ERC20(pool.depositToken).allowance(
        //         account,
        //         address(pancakeStaking)
        //     );
    }

    
    StoreSettig public setting;
    GoodsSetting [] public goodsList;
   
    mapping(address => GoodsPurchase[]) public userPurchaseHistory;

    function initialize(address initialOwner, StoreSettig memory _setting) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        setting.name = _setting.name;
        setting.description = _setting.description;
        setting.image = _setting.image;
    }

   /* ============ External Getters ============ */

    
    function getGoodsList() external view returns (GoodsSetting[] memory) {
        return goodsList;
    }

    function getStoreInfo(address account) external view returns (StoreInfo memory) {
        uint256 goodsCount = goodsList.length;
        GoodsAccountInfo[] memory goodsAccountInfos = new GoodsAccountInfo[](goodsCount);
        for(uint256 i = 0; i < goodsCount; i++) {
            GoodsSetting memory goodsSetting = goodsList[i];
            uint256 buyAllowance = ERC20(goodsSetting.payToken).allowance(account, address(this));
            GoodsAccountInfo memory goodsAccountInfo = GoodsAccountInfo({
                goodsId: goodsSetting.id,
                buyAllowance: buyAllowance
            });
            goodsAccountInfos[i] = goodsAccountInfo;

        }
        StoreInfo memory storeInfo = StoreInfo({
            setting: setting,
            goodsList: goodsList,
            userPurchaseHistory: userPurchaseHistory[account],
            goodsAccountInfos: goodsAccountInfos
        });
        return storeInfo;
    }

    function getImplementationAddress() public view returns(address) {
        return ERC1967Utils.getImplementation();
    }



    function buy(uint256 goodsId, uint256 count)
        public
    {
        GoodsPurchase[] storage goodsPurchases = userPurchaseHistory[msg.sender];
        GoodsSetting memory goodsSetting = goodsList[goodsId - 1];
        GoodsPurchase memory goodsPurchase = GoodsPurchase({
            goodsId: goodsId,
            amount: count,
            price: goodsSetting.price,
            time:  block.timestamp
        });
      
        goodsPurchases.push(goodsPurchase);
        ERC20(goodsSetting.payToken).transferFrom(
            address(msg.sender),
            address(goodsSetting.receiver),
            goodsSetting.price * count
        );
    }

    function getPurchaseHistory(address account) external view returns (GoodsPurchase[] memory) {
        return userPurchaseHistory[account];
    }

    function addGoods(GoodsSetting memory _setting) public onlyOwner {
         _setting.id = goodsList.length + 1;
        ERC20 tokenContract = ERC20(_setting.payToken);
        _setting.payTokenSymbol = tokenContract.symbol();
        _setting.payTokenDecimals = tokenContract.decimals();
        goodsList.push(_setting);
    }

    function updateGoodsSetting(uint256 goodsId, GoodsSetting memory _setting) public onlyOwner {
        goodsList[goodsId - 1] = _setting;
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}

    function upgrade(address newImplementation) public onlyOwner {
        upgradeToAndCall(newImplementation, "");
    }
}
