// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

async function main() {
    const CTFFarm = await ethers.getContractFactory("CTFFarm");
    const CTFToken = await ethers.getContractFactory("CyberTimeFinanceToken")

    const CTFTokenAddress = ""
    const devAddress = ""
    const lpFeeReceiver = ""
    const ctfPerBlock = ""
    const startBlock = ""
    const CTFOwner = ""

    const lpTokenAddress = "0x77Ad1Fd1C6f65041B4AC8ca7c1702bD1a7343eA0"

    // deploy CTF token, move it to different file later
    const ctfToken = await CTFToken.deploy(CTFOwner, "1000000000000000000")

    const ctfFarm = await CTFFarm.deploy(
        ctfToken.address,
        devAddress,
        lpFeeReceiver,
        ctfPerBlock,
        startBlock,
        startBlock,
    )
    
    console.log("adding farming contract")
    await ctfToken.addFarmingContract(ctfFarm.address)

    console.log("adding farming pool")
    await ctfFarm.add("200", lpTokenAddress, false)

    console.log("🎉  Contracts Deployed")
    console.log({
        CTFTokenAddress: ctfToken.address,
        CTFFarmAddress: ctfFarm.address,
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

  