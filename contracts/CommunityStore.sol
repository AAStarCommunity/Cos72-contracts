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

    struct StoreSettig {
        string name;
        string description;
        string logo;
    }

    struct GoodsSetting {
        uint256 id;
        string name;
        string description;
        string logo;
        address payToken;
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

    StoreSettig public setting;
    GoodsSetting [] public goodsList;
   
    mapping(address => GoodsPurchase[]) public userPurchaseHistory;

    function initialize(address initialOwner, StoreSettig memory _setting) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        setting.name = _setting.name;
        setting.description = _setting.description;
        setting.logo = _setting.logo;
    }

   /* ============ External Getters ============ */

    
    function getGoodsList() external view returns (GoodsSetting[] memory) {
        return goodsList;
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

    function getImplementationAddress() public view returns(address) {
        return ERC1967Utils.getImplementation();
    }   
}
