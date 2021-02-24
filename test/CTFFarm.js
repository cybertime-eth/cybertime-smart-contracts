const {
    expect
} = require("chai");
const {
    BigNumber
} = require("ethers");
const {
    time
} = require('@openzeppelin/test-helpers');

let poolToken;
let ctfToken;
let ctfFarm;


beforeEach(async function () {
    const CTFFarm = await ethers.getContractFactory("NFTLFarm");
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const CTFToken = await ethers.getContractFactory("CyberTimeFinanceToken");

    const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();

    poolToken = await TestERC20.deploy("TestPoolToken", "TPT", owner.address);
    ctfToken = await CTFToken.deploy(owner.address, BigNumber.from("1000000000000000000"));

    const currentBlock = await owner.provider.getBlock();
    const blockReward = BigNumber.from("10000000000000000000");
    const endBlock = currentBlock.number + 2102667

    const depositFee = "200"

    // deploy farming pool contract
    ctfFarm = await CTFFarm.deploy(
        ctfToken.address,
        owner.address,
        feeReceiver.address,
        blockReward,
        BigNumber.from("9000"),
        BigNumber.from(currentBlock.number),
        BigNumber.from(currentBlock.number),
    );

    await ctfToken.addFarmingContract(ctfFarm.address)
})

describe("CTFFarmNFTLPool", function () {
    it("Should recieve the reward tokens successfully", async function () {
        const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();

        const poolTokenBalBefore = await poolToken.balanceOf(owner.address)

        const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))

        await ctfFarm.add(
            "10",
            poolToken.address,
            false
        )
        await poolToken.approve(ctfFarm.address, amount)
        await ctfFarm.deposit("0", amount)


        console.log("current block", await owner.provider.getBlockNumber());

        await time.advanceBlockTo(await owner.provider.getBlockNumber() + 100)

        const pendingCTF = await ctfFarm.pendingNFTL("0", owner.address)

        console.log("pending sushi", pendingCTF.toString())

               
        const ctfBalBefore = await ctfToken.balanceOf(owner.address);
        console.log(ctfBalBefore.toString() / 1e18)

        await ctfFarm.massUpdatePools()

        const withdrawAmt = BigNumber.from((3 * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))

        await ctfFarm.withdraw("0", withdrawAmt)
        console.log("current block", await owner.provider.getBlockNumber());
        
        const ts = await ctfToken.totalSupply()
        console.log(ts.toString())
        const ctfBalAfter = await ctfToken.balanceOf(feeReceiver.address);
        console.log(ctfBalAfter.toString() / 1e18)

        const poolTokenBalAfter = await poolToken.balanceOf(feeReceiver.address)

        console.log(poolTokenBalAfter.toString())

        const diff = (poolTokenBalBefore - amount).toLocaleString('fullwide', {
            useGrouping: false
        })

        expect("1").to.equal("1");
    });



    function formatAmt(_amount) {
        return BigNumber.from((_amount * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))
    }

});