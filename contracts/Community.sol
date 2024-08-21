// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { PointsToken } from "./PointsToken.sol";
import { CommunityNFT } from "./CommunityNFT.sol";
/**
 * @title Community
 *
 */
contract Community is Ownable {
    
    constructor(address initialOwner, string memory _name, string memory _description, string memory _logo) Ownable(initialOwner) {
        name = _name;
        description = _description;
        logo = _logo;
    }

    string public name;
    string public description;
    string public logo;
    mapping(address => uint256) public userMap;
    address[] public userList;
    address[] public nftList;
    address public pointToken;

    /* ============ External Write Functions ============ */

    function join() public {
        userList.push(msg.sender);
        userMap[msg.sender] = 1;
    }

    function quit() public {
        userMap[msg.sender] = 0;
    }


    /* ============ External Getters ============ */

    
    function getUserList() external view returns (address[] memory) {
        return userList;
    }

    function getNFTList() external view returns (address[] memory) {
        return nftList;
    }






     /* ============ Admin Functions ============ */

    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function setDescription(string memory _description) external onlyOwner {
        description = _description;
    }

    function setLogo(string memory _logo) external onlyOwner {
        logo = _logo;
    }

    function setPointToken(address _pointToken) external onlyOwner {
        pointToken = _pointToken;
    }

    function createPointToken(string memory _name, string memory _symbol) external onlyOwner {
        ERC20 token = new PointsToken(address(this), _name, _symbol);
        pointToken = address(token);
    }

    function createNFT(string memory _name, string memory _symbol, string memory _baseTokenURI, uint256 _price) external onlyOwner {
        CommunityNFT token = new CommunityNFT(msg.sender, _name, _symbol, _baseTokenURI, pointToken, _price);
        nftList.push(address(token));
    }

    function sendPointToken(address account, uint256 amount) external onlyOwner {
        PointsToken(pointToken).mint(account, amount);
    }
}
