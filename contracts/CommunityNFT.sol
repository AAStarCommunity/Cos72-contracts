// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
/**

 */
contract CommunityNFT is

    ERC721URIStorage,
   
    Ownable
{

    uint256 private _tokenIdCounter;

    string public baseTokenURI;

    address public payToken;

    uint256 public price;
 

    constructor(address initialOwner, string memory _name, string memory _symbol, string memory _baseTokenURI, address _payToken, uint256 _price) Ownable(initialOwner) ERC721(_name, _symbol) {
       baseTokenURI = _baseTokenURI; 
       payToken = _payToken;
       price = _price;
    }

    mapping(address => uint256 []) public tokenIds;
 

    /**
     * @param count Number of minted box count, Cannot be the zero
     * @dev Safely mint multiple tokens and send them to to address. If minting in the pre-sales stage, you need to provide Merkel proof parameters
     * @notice The batch mint tokens, Need to payment the amount of count * unitPrice
     */
    function mint(address account, uint256 count)
        public
    {
        // Batch Mint NFT
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = _tokenIdCounter;
            _safeMint(account, tokenId);
            _tokenIdCounter = _tokenIdCounter + 1;
            tokenIds[account].push(tokenId);
        }

        ERC20(payToken).transferFrom(
            address(msg.sender),
            address(this),
            price * count
        );
    }

    /**
     * @param tokenId Must be a minted token id.
     * @notice Returns the URL used to access the NFT metadata information.
     * @return tokenURI A MetaData IPFS connection that returns a Token.
     *  If the current block time < opening blind box timestamp,
     *  return the token metadata url, otherwise return the box metadata url
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721URIStorage)
        returns (string memory)
    {
        // require(_exists(tokenId), "WG: URI Query For Nonexistent Token");
        return
            string(
                abi.encodePacked(
                    baseTokenURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
    }



    function getAccountTokenIds(address account)    public
        view
        returns (uint256[] memory) {
            return tokenIds[account];
    }
}
