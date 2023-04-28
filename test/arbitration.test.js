const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('Процесс сделки без участия арбитра', () => {
  let contract;
  let deployer, buyer, seller, arbitrator;
  let participantAddresses;
  before(async () => {
    const _contract = await ethers.getContractFactory('Arbitration');
    [deployer, buyer, seller, arbitrator] = await ethers.getSigners();
    participantAddresses = [
      buyer.address, seller.address, arbitrator.address
    ]
    contract = await _contract.deploy(
      buyer.address, seller.address, arbitrator.address);
    await contract.deployed();
  })
  it("Должен записывать участников контракта", async () => {
    const participants = [
      await contract.buyer(),
      await contract.seller(), 
      await contract.arbitrator(), 
    ]
    expect(participants).to.have.members(participantAddresses);
  })
  it("Должен запрещать вносить неверный депозит", async () => {
    expect(
      contract.connect(buyer).sendDepositAsBuyer({value: ethers.utils.parseEther('0.1')})
    ).to.be.reverted;
    expect(
      contract.connect(seller).sendDepositAsSeller({value: ethers.utils.parseEther('0.1')})
    ).to.be.reverted;
  })
  it("Должен позволить сторонам внести депозит", async () => {
    await contract.connect(buyer).sendDepositAsBuyer({value: ethers.utils.parseEther('0.5')});
    await contract.connect(seller).sendDepositAsSeller({value: ethers.utils.parseEther('0.5')});
    const balance = await ethers.provider.getBalance(contract.address);
    expect(balance).to.equal(ethers.utils.parseEther('1.0'));
  })
  it("Должен запретить вносить покупателю неверную сумму товара", async () => {
    expect(
      contract.connect(buyer).sendProductPrice({value: ethers.utils.parseEther('0.9')})
    ).to.be.reverted
  })
  it("Должен позволить покупателю оплатить товар", async () => {
    await contract.connect(buyer).sendProductPrice({value: ethers.utils.parseEther('1.0')});
    const balance = await ethers.provider.getBalance(contract.address);
    expect(balance).to.equal(ethers.utils.parseEther('2.0'));
  })
  it("Должен позволить покупателю закрыть контракт", async () => {
    await contract.connect(buyer).closeContract()
  })
});

describe('Процесс сделки с участием арбитра', () => {
  let contract;
  let deployer, buyer, seller, arbitrator;
  let participantAddresses;
  before(async () => {
    const _contract = await ethers.getContractFactory('Arbitration');
    [deployer, buyer, seller, arbitrator] = await ethers.getSigners();
    participantAddresses = [
      buyer.address, seller.address, arbitrator.address
    ]
    contract = await _contract.deploy(
      buyer.address, seller.address, arbitrator.address);
    await contract.deployed();
  })
  it("Должен записывать участников контракта", async () => {
    const participants = [
      await contract.buyer(),
      await contract.seller(), 
      await contract.arbitrator(), 
    ]
    expect(participants).to.have.members(participantAddresses);
  })
  it("Должен позволить сторонам внести депозит", async () => {
    await contract.connect(buyer).sendDepositAsBuyer({value: ethers.utils.parseEther('0.5')});
    await contract.connect(seller).sendDepositAsSeller({value: ethers.utils.parseEther('0.5')});
    const balance = await ethers.provider.getBalance(contract.address);
    expect(balance).to.equal(ethers.utils.parseEther('1.0'));
  })
  it("Должен позволить покупателю оплатить товар", async () => {
    await contract.connect(buyer).sendProductPrice({value: ethers.utils.parseEther('1.0')});
    const balance = await ethers.provider.getBalance(contract.address);
    expect(balance).to.equal(ethers.utils.parseEther('2.0'));
  })
  it("Должна быть возможность призвать арбитра к разрешению спора", async () => {
    await contract.connect(seller).callArbiter('Buyer is REDISKA!');
    const messages = await contract.connect(seller).getArbitrationMessages();
    expect(await contract.arbitrationCalled()).to.equal(true);
    expect(await contract.arbitrationCalledBy()).to.equal(seller.address);
  })
  it("Должна быть возможность разрешить спор в пользу продавца", async () => {
    expect(await contract.connect(arbitrator).resolveTheDisputeInFavorOfTheSeller())
      .to.changeEtherBalances([seller], [2])
  })
})