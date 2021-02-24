// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

async function main() {
    const NFTLFarm = await ethers.getContractFactory("NFTLFarm");
    const NFTLToken = await ethers.getContractFactory("NFTLToken")
    const NFTLOwner = "0x9F8eD94408A90e8efa12D2450FC8061EFc3c161e"

    const nftlToken = await NFTLToken.deploy(NFTLOwner, "1000000000000000000")

    const devAddress = "0x9F8eD94408A90e8efa12D2450FC8061EFc3c161e"
    const teamRewardsReceiver = "0x9F8eD94408A90e8efa12D2450FC8061EFc3c161e"
    const nftlPerBlock = "8571400000000000000"
    const teamShare = "0"
    const startBlock = "6564155"
    const bonusEndBlock = "17077288"
    const NFTLTokenAddress = nftlToken.address
    const tokenAddress = "0x77Ad1Fd1C6f65041B4AC8ca7c1702bD1a7343eA0"


    const nftlFarm = await NFTLFarm.deploy(
        NFTLTokenAddress,
        devAddress,
        teamRewardsReceiver,
        nftlPerBlock,
        teamShare,
        startBlock,
        bonusEndBlock,
    )

    console.log("adding farming contract")
    await nftlToken.addFarmingContract(nftlFarm.address)

    console.log("adding farming pool")
    await nftlFarm.add("200", tokenAddress, false)

    console.log("🎉  Contracts Deployed")

    console.log({
        NFTLTokenAddress: nftlToken.address,
        NFTLFarmAddress: nftlFarm.address,
    })
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });