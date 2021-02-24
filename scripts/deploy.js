// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { BigNumber, utils } = require("ethers");
const { ethers } = require("hardhat");

async function main() {

  const CTFFarmNFTLPool = await ethers.getContractFactory("CTFFarmNFTLPool");
  const TestERC20 = await ethers.getContractFactory("TestERC20");

  const [owner, devAddress, feeReceiver] = await ethers.getSigners();

  const currentBlock = await owner.provider.getBlock()
  const depositFee = "200"

  // deploy sample ERC20
  const poolToken = await TestERC20.deploy(owner.address);
  const CTF = await TestERC20.deploy("0xEfcc1e5322Afa4ccc2Aba8E818E0CcaC0a6BE6d1");

  const poolTokenBalBefore = await poolToken.balanceOf(owner.address)
  console.log("User Pool Token Balance Before Deposit", poolTokenBalBefore.toString())

  let monthlyReward = (15120 * (10 ** 18)).toLocaleString('fullwide', {useGrouping:false})
  monthlyReward = BigNumber.from(monthlyReward)

  console.log(monthlyReward)

  // deploy farming contract
  const ctfFarmNFTLPool = await CTFFarmNFTLPool.deploy(devAddress.address, poolToken.address, CTF.address, depositFee, feeReceiver.address, BigNumber.from(currentBlock.timestamp - 10000), monthlyReward);

  let depositAmt = (100).toLocaleString('fullwide', {useGrouping:false})

  console.log(depositAmt)
  depositAmt = BigNumber.from(depositAmt)

  await poolToken.approve(ctfFarmNFTLPool.address, depositAmt.toString())
  // depositAmt = BigNumber(depositAmt)
  // deposit tokens
  await ctfFarmNFTLPool.deposit(depositAmt)


  const getShare = await ctfFarmNFTLPool.getShare(owner.address)


  console.log({
    share: getShare.toString()
  })


  // increase the EVM time 
  ethers.provider.send("evm_increaseTime", [86400])   // add 60 seconds
  ethers.provider.send("evm_mine")      // mine the next block

  console.log("withdrawing")

  await ctfFarmNFTLPool.withdraw(depositAmt)



  // withdraw tokens wait for 10 blocks


  const poolTokenBalAfter = await poolToken.balanceOf(owner.address)
  console.log("User Pool Token Balance After Deposit", poolTokenBalAfter.toString())
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });