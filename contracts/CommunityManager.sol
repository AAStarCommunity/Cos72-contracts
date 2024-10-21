// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { Community } from "./Community.sol";
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

    function createCommunity(bytes memory _data) public {
        Community community = new Community();
        address communityAddress = address(community);
        ERC1967Proxy proxy = new ERC1967Proxy(communityAddress, _data);
        communityList.push(address(proxy));
    }

    // function updateAllCommunity() public {
    //     for(uint256 i = 0;  i < communityList.length; i++) {
    //         Community community = new Community();
    //         address communityAddress = address(community);
    //         communityList[i].delegatecall(
    //             abi.encodeWithSignature("upgrade2(address)", communityAddress)
    //         );
            
    //      //   Community(communityList[i]).delegatecall(bytes4(keccak256("upgradeToAndCall()")), [communityAddress, _data]);
    //     }
    // }
}
