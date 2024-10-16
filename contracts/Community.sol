// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { PointsToken } from "./PointsToken.sol";
import { CommunityNFT } from "./CommunityNFT.sol";
import { CommunityGoods } from "./CommunityGoods.sol";
import { CommunityStore } from "./CommunityStore.sol";
/**
 * @title Community
 *
 */
contract Community is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    
    struct CommunitySettig {
        string name;
        string description;
        string logo;  
    }

    CommunitySettig public setting;
    mapping(address => uint256) public userMap;
    address[] public userList;
    address[] public nftList;
    address[] public storeList;
    address public pointToken;

    function initialize(address initialOwner, CommunitySettig memory _setting) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        setting = _setting;
    }

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

    function getStoreList() external view returns (address[] memory) {
        return storeList;
    }


     /* ============ Admin Functions ============ */

    function setSetting(CommunitySettig memory _setting) external onlyOwner {
        setting = _setting;
    }

    function setName(string memory _name) external onlyOwner {
        setting.name = _name;
    }

    function setDescription(string memory _description) external onlyOwner {
        setting.description = _description;
    }

    function setLogo(string memory _logo) external onlyOwner {
        setting.logo = _logo;
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

    function createStore(bytes memory _data) external onlyOwner {
        CommunityStore communityStore = new CommunityStore();
        address communityStoreAddress = address(communityStore);
        ERC1967Proxy proxy = new ERC1967Proxy(communityStoreAddress, _data);
        storeList.push(address(proxy));
    }

    function sendPointToken(address account, uint256 amount) external onlyOwner {
        PointsToken(pointToken).mint(account, amount);
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
