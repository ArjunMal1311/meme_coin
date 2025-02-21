const { loadFixture } = require("@nomicfoundation/hardhat-toolbox/network-helpers")
const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("Factory", function () {
    const FEE = ethers.parseUnits("0.01", 18); // 0.01 ether

    async function deployFactoryFixture() {
        const [deployer, creator, buyer] = await ethers.getSigners();
        const Factory = await ethers.getContractFactory("Factory");
        const factory = await Factory.deploy(FEE); // constructor for the Factory.sol thing

        // Creating a new token
        const transaction = await factory.connect(creator).create("DAPP Token", "DAPP", { value: FEE });
        await transaction.wait();


        // Getting token address
        const tokenAddress = await factory.tokens(0);
        const token = await ethers.getContractAt("Token", tokenAddress);

        return { factory, token, deployer, creator, buyer };
    }

    async function buyTokenFixture() {
        const { factory, token, creator, buyer } = await deployFactoryFixture();

        const AMOUNT = ethers.parseUnits("10000", 18); // 10000 tokens
        const COST = ethers.parseUnits("1", 18); // 1 ether per token

        const transaction = await factory.connect(buyer).buy(await token.getAddress(), AMOUNT, { value: COST });
        await transaction.wait();

        return { factory, token, creator, buyer, AMOUNT, COST };
    }

    describe("Deployment", function () {
        it("Should se the fee", async function () {
            const { factory } = await loadFixture(deployFactoryFixture);
            expect(await factory.fee()).to.equal(FEE);
        })

        it("Should set the owner", async function () {
            const { factory, deployer } = await loadFixture(deployFactoryFixture);
            expect(await factory.owner()).to.equal(deployer.address);
        })
    })

    describe("Creating", function () {
        it("Should set the owner", async function () {
            const { factory, token } = await loadFixture(deployFactoryFixture);
            expect(await token.owner()).to.equal(await factory.getAddress()); // owner of the token is the factory
        })

        it("Should set the creator", async function () {
            const { token, creator } = await loadFixture(deployFactoryFixture);
            expect(await token.creator()).to.equal(creator.address);
        })

        it("Should set the total supply", async function () {
            const { factory, token } = await loadFixture(deployFactoryFixture);

            const totalSupply = ethers.parseUnits("1000000", 18);
            expect(await token.balanceOf(await factory.getAddress())).to.equal(totalSupply);
        })

        it("Should update ETH Balance", async function () {
            const { factory } = await loadFixture(deployFactoryFixture);
            const balance = await ethers.provider.getBalance(await factory.getAddress());
            expect(balance).to.equal(FEE);
        })

        it("Should create the sale", async function () {
            const { factory, token, creator } = await loadFixture(deployFactoryFixture);

            const count = await factory.totalTokens();
            expect(count).to.equal(1);

            const sale = await factory.getTokenSale(0);
            expect(sale.token).to.equal(await token.getAddress());
            expect(sale.name).to.equal("DAPP Token");
            expect(sale.creator).to.equal(creator.address);
            expect(sale.sold).to.equal(0);
            expect(sale.raised).to.equal(0);
            expect(sale.isOpen).to.equal(true);
        })
    })

    describe("Buying", function () {
        const AMOUNT = ethers.parseUnits("10000", 18);
        const COST = ethers.parseUnits("1", 18);

        it("Should update ETH Balance", async function () {
            const { factory } = await loadFixture(buyTokenFixture);
            const balance = await ethers.provider.getBalance(await factory.getAddress());

            expect(balance).to.equal(FEE + COST);
        })

        it("Should update Token Balance", async function () {
            const { token, buyer, AMOUNT } = await loadFixture(buyTokenFixture);
            expect(await token.balanceOf(buyer.address)).to.equal(AMOUNT);
        })

        it("Should update Token Sale", async function () {
            const { factory, token } = await loadFixture(buyTokenFixture);

            const sale = await factory.getTokenSale(await token.getAddress());
            
            expect(sale.sold).to.equal(AMOUNT);
            expect(sale.raised).to.equal(COST);
            expect(sale.isOpen).to.equal(true);
        })

        it("Should increase base cost", async function() {
            const { factory, token } = await loadFixture(buyTokenFixture);

            const sale = await factory.getTokenSale(await token.getAddress());
            const cost = await token.getCost(sale.sold);

            expect(cost).to.be.equal(ethers.parseUnits("0.0002"));
            
        })

    })
});
