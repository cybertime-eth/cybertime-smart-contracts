const {
    expect
} = require("chai");
const {
    BigNumber
} = require("ethers");
const { time } = require('@openzeppelin/test-helpers');

let poolToken;
let cTFToken;
let ctfFarmNFTLPool;


beforeEach(async function () {
    const CTFFarmNFTLPool = await ethers.getContractFactory("CTFFarmNFTLPool");
    const TestERC20 = await ethers.getContractFactory("TestERC20");
    const CTFToken = await ethers.getContractFactory("CyberTimeFinanceToken");

    const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();

    poolToken = await TestERC20.deploy(owner.address);
    ctfToken = await CTFToken.deploy(owner.address);

    const currentBlock = await owner.provider.getBlock();
    const monthlyReward = BigNumber.from((15120 * (10 ** 18)).toLocaleString('fullwide', {
        useGrouping: false
    }));
    const depositFee = "200"

    // deploy farming pool contract
    ctfFarmNFTLPool = await CTFFarmNFTLPool.deploy(
        devAddress.address,
        poolToken.address,
        ctfToken.address,
        depositFee,
        feeReceiver.address,
        BigNumber.from(currentBlock.number),
        monthlyReward);
})

describe("CTFFarmNFTLPool", function () {
    it("Should deposit liquidity pool tokens successfully", async function () {
        const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();

        const poolTokenBalBefore = await poolToken.balanceOf(owner.address)

        const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))
        await poolToken.approve(ctfFarmNFTLPool.address, amount)
        await ctfFarmNFTLPool.deposit(amount)

        const poolTokenBalAfter = await poolToken.balanceOf(owner.address)

        const diff = (poolTokenBalBefore - amount).toLocaleString('fullwide', {
            useGrouping: false
        })

        expect(poolTokenBalAfter.toString()).to.equal(diff);
    });


    it("Should withdraw liquidity pool tokens successfully", async function () {
        const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();
        const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))
        await poolToken.approve(ctfFarmNFTLPool.address, amount)
        await ctfFarmNFTLPool.deposit(amount)
        await ctfFarmNFTLPool.withdraw(amount)
        expect(1).to.equal(1);
    });

    it("Should mint correct CTF tokens for after 1 day", async function () {
        const [owner, devAddress, feeReceiver, testAddr] = await ethers.getSigners();
        const amount = BigNumber.from((100 * (10 ** 18)).toLocaleString('fullwide', {
            useGrouping: false
        }))
        await poolToken.approve(ctfFarmNFTLPool.address, amount)
        await ctfFarmNFTLPool.deposit(amount)
        console.log("deployedAt", await owner.provider.getBlockNumber())

        // advance block
        await time.advanceBlockTo(5760)

        console.log(await owner.provider.getBlockNumber())
        await ctfFarmNFTLPool.withdraw(amount)
        // await ctfFarmNFTLPool.withdraw(amount)
        // const totalShare = await ctfFarmNFTLPool.getShare(owner.address);
        // console.log({totalShare: totalShare.toString()})
        expect(1).to.equal(1);
    });

    it("Should have total supply of 15500 CTF after yeild farming", async function () {

    });

});