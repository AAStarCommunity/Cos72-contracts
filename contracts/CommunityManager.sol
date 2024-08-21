// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import { Community } from "./Community.sol";
/**
 * @title CommunityManager
 * 
 */
contract CommunityManager is Ownable
{

    constructor(address initialOwner) Ownable(initialOwner) {}
    address[] public communityList;
    struct CommunityParams {
        string name;
        string desc;
        string logo;
    }

    /* ============ External Getters ============ */

    function getCommunityList() external view returns ( address[] memory) {
        return communityList;
    }


    function createCommunity(CommunityParams memory data) public {
        Community community = new Community(msg.sender, data.name, data.desc, data.logo);
        address communityAddress = address(community);
        communityList.push(communityAddress);
    }

}
