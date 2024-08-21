// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
import { Community__factory, CommunityManager__factory, CommunityNFT__factory, PointsToken__factory } from "../typechain-types/factories/contracts";
import { ERC20__factory } from "../typechain-types";

async function main() {
    const [admin, player1] = await ethers.getSigners();
   
    let contractFactory = await ethers.getContractFactory("CommunityManager");
    let CommunityManagerContract = await contractFactory.deploy(admin.address);
    await CommunityManagerContract.waitForDeployment();
    const managerAddress =  await CommunityManagerContract.getAddress()
    console.log("CommunityManagerContract deployed to:", managerAddress);
    const communityManager =  CommunityManager__factory.connect(managerAddress, admin);
    let tx = await communityManager.createCommunity({
        name: "test",
        desc: "test",
        logo: "test",
    })
    await tx.wait();
    const communityManagerOwner = await communityManager.owner();
    console.log(`admin address is ${admin.address}`  )
    console.log(`communityManager owner is ${communityManagerOwner}`  )
    const communityList = await communityManager.getCommunityList();
    console.log(communityList);
    const community  = Community__factory.connect(communityList[0], admin)
    tx = await community.createPointToken("TEST","TEST");
    await tx.wait()
    const communityOwner = await community.owner();
    console.log(`community owner is ${communityOwner}`  )
    const pointToken = await community.pointToken();
    console.log(pointToken);
   
    const tokenContract = await PointsToken__factory.connect(pointToken, player1);
    const pointTokenOwner = await tokenContract.owner();
    console.log(`point Token owner is ${pointTokenOwner}`  )
    let balanceOf = await tokenContract.balanceOf(player1.address);
 
    console.log(`${player1.address} balanceOf ${ethers.formatEther(balanceOf)}` );
    tx = await community.sendPointToken(player1.address, ethers.parseEther("100"));
    await tx.wait()
    balanceOf = await tokenContract.balanceOf(player1.address);
    console.log(`${player1.address} balanceOf ${ethers.formatEther(balanceOf)}` );

    tx = await community.createNFT("TEST","TEST", "TEST", ethers.parseEther("10"));
    await tx.wait()
    const NFTList = await community.getNFTList();
    console.log(NFTList);

    const nftContract = CommunityNFT__factory.connect(NFTList[0], player1);
    tx = await tokenContract.approve(NFTList[0], ethers.MaxUint256)
    await tx.wait();
    tx = await nftContract.mint(player1.address, 5)
    await tx.wait();
    balanceOf = await tokenContract.balanceOf(player1.address);
    console.log(`${player1.address} balanceOf ${ethers.formatEther(balanceOf)}` );
    const result = await nftContract.getAccountTokenIds(player1.address);
    console.log(`${player1.address} nft  ${result}` );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
