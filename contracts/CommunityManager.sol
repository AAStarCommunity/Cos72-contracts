// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/**
 * @title CommunityManager
 * 
 */
contract CommunityManager is Ownable
{

    constructor(address initialOwner) Ownable(initialOwner) {}
    address[] public communityList;


    /* ============ External Getters ============ */
    function getCommunityList() external view returns ( address[] memory) {
        return communityList;
    }

    function createCommunity(address communityAddress, bytes memory _data) public {
        ERC1967Proxy proxy = new ERC1967Proxy(communityAddress, _data);
        communityList.push(address(proxy));
    }
}
