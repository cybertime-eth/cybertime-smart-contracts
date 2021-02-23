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
    const CTFFarm = await ethers.getContractFactory("CTFFarm");
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const CTFToken = await ethers.getContractFactory("CyberTimeFinanceToken");

    const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();

    poolToken = await TestERC20.deploy(owner.address);
    ctfToken = await CTFToken.deploy(owner.address, BigNumber.from("1000000000000000000"));

    const currentBlock = await owner.provider.getBlock();
    const blockReward = BigNumber.from("10000000000000000000");
    const endBlock = currentBlock.number + 2102667

    const depositFee = "200"

    // deploy farming pool contract
    ctfFarm = await CTFFarm.deploy(
        ctfToken.address,
        owner.address,
        blockReward,
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

        const pendingCTF = await ctfFarm.pendingCTF("0", owner.address)

        console.log("pending sushi", pendingCTF.toString())

               
        const ctfBalBefore = await ctfToken.balanceOf(owner.address);
        console.log(ctfBalBefore.toString() / 1e18)

        await ctfFarm.massUpdatePools()

        await ctfFarm.withdraw("0", amount)
        console.log("current block", await owner.provider.getBlockNumber());
        
        const ctfBalAfter = await ctfToken.balanceOf(owner.address);
        console.log(ctfBalAfter.toString() / 1e18)

        const poolTokenBalAfter = await poolToken.balanceOf(owner.address)

        const diff = (poolTokenBalBefore - amount).toLocaleString('fullwide', {
            useGrouping: false
        })

        expect("1").to.equal("1");
    });


    // it("Should withdraw liquidity pool tokens successfully", async function () {
    //     const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();
    //     const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
    //         useGrouping: false
    //     }))
    //     await poolToken.approve(ctfFarmNFTLPool.address, amount)
    //     await ctfFarmNFTLPool.deposit(amount)
    //     await ctfFarmNFTLPool.withdraw(amount)
    //     expect(1).to.equal(1);
    // });

    // it("Should mint correct CTF tokens after 1 day", async function () {
    //     const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();
    //     const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
    //         useGrouping: false
    //     }))
    //     await poolToken.approve(ctfFarmNFTLPool.address, amount)
    //     await ctfFarmNFTLPool.deposit(amount)
    //     const currentBlock = await owner.provider.getBlockNumber()
    //     // advance block
    //     await time.advanceBlockTo(currentBlock + 5760)
    //     await ctfFarmNFTLPool.withdraw(amount)
    //     expect(1).to.equal(1);
    // });

    // it("Should mint correct CTF tokens for multiple users", async function () {
    //     const [owner, userA, userB, userC, userD] = await ethers.getSigners();
    //     const amount = formatAmt(100)
    //     const currentBlock = await owner.provider.getBlockNumber()

    //     // userA deposits
    //     await poolToken.connect(userA).mint(userA.address, amount);
    //     await poolToken.connect(userA).approve(ctfFarmNFTLPool.address, amount)
    //     console.log("userA Block Number", await owner.provider.getBlockNumber())
    //     await ctfFarmNFTLPool.connect(userA).deposit(amount)

    //     // userB deposits
    //     await poolToken.connect(userB).mint(userB.address, amount);
    //     await poolToken.connect(userB).approve(ctfFarmNFTLPool.address, amount)
    //     // await time.advanceBlockTo(currentBlock + 50)
    //     console.log("userB Block Number", await owner.provider.getBlockNumber())
    //     await ctfFarmNFTLPool.connect(userB).deposit(amount)

    //     // await time.advanceBlockTo(currentBlock + 50)

    //     // userC deposits
    //     await poolToken.connect(userC).mint(userC.address, amount);
    //     await poolToken.connect(userC).approve(ctfFarmNFTLPool.address, amount)
    //     console.log("userC Block Number", await owner.provider.getBlockNumber())
    //     await ctfFarmNFTLPool.connect(userC).deposit(amount)


    //     // userD Deposit
    //     await poolToken.connect(userD).mint(userD.address, amount);
    //     await poolToken.connect(userD).approve(ctfFarmNFTLPool.address, amount)
    //     console.log("userD Block Number", await owner.provider.getBlockNumber())
    //     await ctfFarmNFTLPool.connect(userD).deposit(amount)

    //     // wait for the day
    //     await time.advanceBlockTo(currentBlock + 5760)

    //     // get shares
    //     const userAShare = await ctfFarmNFTLPool.getShare(userA.address)
    //     const userBShare = await ctfFarmNFTLPool.getShare(userB.address)
    //     const userCShare = await ctfFarmNFTLPool.getShare(userC.address)
    //     const userDShare = await ctfFarmNFTLPool.getShare(userD.address)

    //     // both removes tokens 
    //     await ctfFarmNFTLPool.connect(userA).withdraw(amount)
    //     await ctfFarmNFTLPool.connect(userB).withdraw(amount)
    //     await ctfFarmNFTLPool.connect(userC).withdraw(amount)
    //     await ctfFarmNFTLPool.connect(userD).withdraw(amount)

    //     // check CTF balances
    //     const userABal = await ctfToken.balanceOf(userA.address);
    //     const userBBal = await ctfToken.balanceOf(userB.address);
    //     const userCBal = await ctfToken.balanceOf(userC.address);
    //     const userDBal = await ctfToken.balanceOf(userD.address);

    //     console.log({
    //         userAShare: userAShare.toString() / 10000,
    //         userBShare: userBShare.toString() / 10000,
    //         userCShare: userCShare.toString() / 10000,
    //         userDShare: userDShare.toString() / 10000,
    //         userABal: userABal.toString() / 1e18,
    //         userBBal: userBBal.toString() / 1e18,
    //         userCBal: userCBal.toString() / 1e18,
    //         userDBal: userDBal.toString() / 1e18
    //     })

    //     expect(1).to.equal(1);
    // });


    function formatAmt(_amount) {
        return BigNumber.from((_amount * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))
    }

});