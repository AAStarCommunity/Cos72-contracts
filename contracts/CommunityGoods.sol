// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CommunityGoods is Ownable
{

    struct GoodsSetting {
        string name;
        string description;
        string logo;
        address payToken;
        address receiver;
        uint256 amount;
        uint256 price;
    }

    struct GoodsPurchase {
        uint256 amount;
        uint256 price;
        uint256 time;
    }

    GoodsSetting public setting;
    uint256 public goodsAmount;
    mapping(address => GoodsPurchase[]) public userPurchaseHistory;

    constructor(address initialOwner, GoodsSetting memory _setting) Ownable(initialOwner)  {
      setting.name = _setting.name;
      setting.description = _setting.description;
      setting.logo = _setting.logo;
      setting.payToken = _setting.payToken;
      setting.amount = _setting.amount;
      setting.price = _setting.price;
      setting.receiver = _setting.receiver;
      goodsAmount = _setting.amount;
    }

    function buy(uint256 count)
        public
    {
        GoodsPurchase[] storage goodsPurchases = userPurchaseHistory[msg.sender];
        GoodsPurchase memory goodsPurchase = GoodsPurchase({
            amount: count,
            price: setting.price,
            time:  block.timestamp
        });
        goodsAmount = goodsAmount - count;
        goodsPurchases.push(goodsPurchase);
        ERC20(setting.payToken).transferFrom(
            address(msg.sender),
            address(setting.receiver),
            setting.price * count
        );
    }

    function getPurchaseHistory(address account) external view returns (GoodsPurchase[] memory) {
        return userPurchaseHistory[account];
    }
}
