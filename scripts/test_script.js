// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

async function main() {

    const owner = "0x9F8eD94408A90e8efa12D2450FC8061EFc3c161e"

    const NFTLFarm = await ethers.getContractAt("CTFFarm", "0x88A1747915274CF7CC677683e88b18ba60424A79")
    const NFTLToken = await ethers.getContractAt("NFTLToken", "0x11c11406fAC967B0498e6264791F715C3649a703")
    const poolToken =  await ethers.getContractAt("TestERC20", "0x77Ad1Fd1C6f65041B4AC8ca7c1702bD1a7343eA0")

    // await poolToken.approve(NFTLFarm.address, "10000000000000000000")

    // const allowance = await poolToken.allowance(owner, NFTLFarm.address)
    // console.log(allowance.toString())


    const deposit = await NFTLFarm.deposit(0, "1000000000000000000")
    console.log(deposit)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

  