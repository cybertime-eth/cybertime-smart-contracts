// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

async function main() {
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const token1 = await TestERC20.deploy("TestPoolToken", "TPT", "0x9F8eD94408A90e8efa12D2450FC8061EFc3c161e");
    console.log(token1)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });