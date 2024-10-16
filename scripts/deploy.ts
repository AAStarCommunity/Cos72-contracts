// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers, upgrades } from "hardhat";
import { Community__factory, CommunityManager__factory, CommunityNFT__factory, CommunityStore__factory, PointsToken__factory } from "../typechain-types/factories/contracts";
import { ERC1967Proxy__factory, ERC20__factory } from "../typechain-types";

async function main() {
    const [admin, player1] = await ethers.getSigners();
   
    let contractFactory = await ethers.getContractFactory("CommunityManager");
    let CommunityManagerContract = await contractFactory.deploy(admin.address);
    await CommunityManagerContract.waitForDeployment();
    const managerAddress =  await CommunityManagerContract.getAddress()
    console.log("CommunityManagerContract deployed to:", managerAddress);
    const communityManager =  CommunityManager__factory.connect(managerAddress, admin);
    const communityInterface =  Community__factory.createInterface()
    const data = communityInterface.encodeFunctionData("initialize", [admin.address, {
        name: "test",
        description: "test",
        logo: "test"
    }])
    const data2 = communityInterface.encodeFunctionData("initialize", [admin.address, {
        name: "test2",
        description: "test2",
        logo: "test2"

    }])
    let tx = await communityManager.createCommunity(data);
    await tx.wait();
    tx = await communityManager.createCommunity(data2);
    await tx.wait();
    const communityList = await communityManager.getCommunityList();

   
    for(let i = 0, l = communityList.length; i < l; i++) {
        const community = Community__factory.connect(communityList[i], admin);
        const setting = await community.setting();
        const address = await community.getAddress();
        let implAddress = await community.getImplementationAddress();
        console.log("community", address, implAddress, setting);
        const communityStoreInterface =  CommunityStore__factory.createInterface()
        const data = communityStoreInterface.encodeFunctionData("initialize", [admin.address, {
            name: "storeTest",
            description: "storeTest",
            logo: "storeTest"
        }])
        const data2 = communityStoreInterface.encodeFunctionData("initialize", [admin.address, {
            name: "storeTest2",
            description: "storeTest2",
            logo: "storeTest2"
        }])
        tx = await community.createStore(data);
        await tx.wait();
        tx = await community.createStore(data2);
        await tx.wait();

        const storeList = await community.getStoreList();
        tx = await community.createPointToken("pt", "pt");
        await tx.wait();
        for(let m = 0, n = storeList.length; m < n; m++) {
            const communityStore = CommunityStore__factory.connect(storeList[m], admin);
            const setting = await communityStore.setting();
            const address = await communityStore.getAddress();
            let implAddress = await communityStore.getImplementationAddress();
            const pointToken = await community.pointToken();
            tx = await communityStore.addGoods({
                id: 0,
                name: "goods1",
                description: "goods1",
                logo: "goods1",
                payToken: pointToken,
                receiver: admin.address,
                amount: ethers.MaxUint256,
                price: ethers.parseEther("1"),
                enabled: true,
            })
            await tx.wait();
            tx = await communityStore.addGoods({
                id: 0,
                name: "goods2",
                description: "goods2",
                logo: "goods2",
                payToken: pointToken,
                receiver: admin.address,
                amount: ethers.MaxUint256,
                price: ethers.parseEther("100"),
                enabled: true,
            })
            await tx.wait();
            const goodsList = await communityStore.getGoodsList()
            tx = await ERC20__factory.connect(pointToken, admin).approve(address, ethers.MaxUint256)

            await tx.wait()
            tx = await community.sendPointToken(admin.address, ethers.parseEther("1000"))
            await tx.wait();
            tx = await communityStore.buy(1, 1)
            await tx.wait()
            tx = await communityStore.buy(1, 2)
            await tx.wait()
            tx = await communityStore.buy(2, 5)
            await tx.wait()
            console.log("Community Store", address, implAddress, setting, goodsList);
            const purchaseHistory = await communityStore.getPurchaseHistory(admin.address);
            console.log("purchaseHistory", admin.address, purchaseHistory);

        }



        // test update impl
        const contractFactory = await ethers.getContractFactory("Community");
        const CommunityManagerContract = await contractFactory.deploy();
        const newAddress = await CommunityManagerContract.getAddress();
        const txUpgrade  = await community.upgrade(newAddress)
        await txUpgrade.wait();
        implAddress = await community.getImplementationAddress();
        console.log(address, implAddress, setting);
    }
  //  console.log(communityList);
    //community.createGoods()
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
