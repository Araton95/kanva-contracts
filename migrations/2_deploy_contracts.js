const StakingFactory = artifacts.require('StakingFactory')
const PaletteRewards = artifacts.require('PaletteRewards')
const KanvaToken = artifacts.require('KanvaToken')
const KanvaLtd = artifacts.require('KanvaLtd')

// Allocation values from whitepaper
// Addresses should be changed to Mainnet addresses
const liquidityTokens = {
  KnvEth: { address: '0x3399ce58b2cf10a21cbd362541ba2339470b2464', allocation: '435600000000' },
  UsdcEth: { address: '0xbc30AaA8e99d0f0e435FC938034850c2fC77f753', allocation: '64800000000' },
  UsdtEth: { address: '0x230c4C6De893F369920a94Bd354589EA1A8BcAfD', allocation: '64800000000' },
  DaiEth: { address: '0xE8c6d3d1612cfD65e3D8fcAB3bA90D100029a79C', allocation: '64800000000' },
}

// The staking mechanism start time
// On production it can be hardcoded (like 1 DEC 2020)
// Now we are using current time + provided seconds (means staking will start after provided seconds)
const genesisTimeblock = (secondsBeforeStart) => Math.round((new Date()).getTime() / 1000) + secondsBeforeStart

module.exports = (deployer, network, accounts) => {
  const kanvaLtdAddress = '0x68Db707d49F2737b32a507d4e28B9d1b31aC75E0'
  const kanvaTokenAddress = '0x376F52ab03014e0D300A816a6FABD7789e4D8E83'
  const stakingFactoryAddress = '0x2d3098BE41dA77ef3255fEA1b71592ECfB84B95C'

  // Owner of contracts
  // Receiver of KNV tokens (should be un commented later)
  // const clientAddr = '0xeb8a34733ae825Eb4c45a345D586071f390B6B6f'
  const clientAddr = accounts[0]

  // OpenSea Mainnet param.
  // Supported for Rinkeby and Mainnet only!
  // More info here: https://blog.ippon.tech/non-fungible-tokens-on-the-ethereum-blockchain/
  const proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'

  // Should be changed in the future
  const metaDataUri = 'https://api.kanva.org/tokenId/'
  const contractUri = 'https://api.kanva.org/contractUri/'


  deployer.then(async () => {
    if (!stakingFactoryAddress && !kanvaLtdAddress && !kanvaTokenAddress) {
      const kanvaTokenInstance = await deployer.deploy(KanvaToken, accounts[0])
      const kanvaLtdInstance = await deployer.deploy(KanvaLtd, contractUri, metaDataUri, proxyRegistryAddress)
      const stakingFactoryInstance = await deployer.deploy(StakingFactory, kanvaTokenInstance.address, genesisTimeblock(100))

      console.log("---------------")
      console.log("NFT =>", kanvaLtdInstance.address)
      console.log("Kanva =>", kanvaTokenInstance.address)
      console.log("FACTORY =>", stakingFactoryInstance.address)
    } else if (stakingFactoryAddress && kanvaLtdAddress && kanvaTokenAddress) {
      // Deploy KNV/ETH staking pool
      const stakingFactoryInstance = await StakingFactory.at(stakingFactoryAddress)
      const kanvaTokenInstance = await KanvaToken.at(kanvaTokenAddress)

      // Deploy all 4 pair pools
      const poolsLength = Object.keys(liquidityTokens).length
      for (let i = 0; i < poolsLength; i++) {
        const pair = Object.keys(liquidityTokens)[i]
        const { address, allocation } = liquidityTokens[pair]

        if (pair !== 'KnvEth') {
          await stakingFactoryInstance.deploy(address, allocation)
          await kanvaTokenInstance.transfer(stakingFactoryAddress, allocation, { from: accounts[0] })
          console.log(pair, "pool tokens sent!")
        } else {
          await stakingFactoryInstance.deployKnv(kanvaLtdAddress, address, allocation)
          await kanvaTokenInstance.transfer(stakingFactoryAddress, allocation, { from: accounts[0] })
          console.log("KnvEth pool tokens sent!")
        }
      }

      // Notify rewards amount
      await stakingFactoryInstance.notifyRewardAmounts({ from: accounts[0] })

      // Setup Kanva NFT contract
      const kanvaLtdInstance = await KanvaLtd.at(kanvaLtdAddress)

      // Need to fetch contract data about KNV/ETH pool and get its pool address
      const genesisPoolData = await stakingFactoryInstance.stakingRewardsInfoByStakingToken(liquidityTokens.KnvEth.address)
      const genesisPoolAddress = genesisPoolData.stakingRewards

      await kanvaLtdInstance.addMinter(genesisPoolAddress, { from: accounts[0] })
      console.log("NFT minter added!")

      await kanvaLtdInstance.addWhitelistAdmin(clientAddr, { from: accounts[0] })
      console.log("Whitelist admin added!")

      await kanvaLtdInstance.transferOwnership(clientAddr, { from: accounts[0] })
      console.log("NFT Owner changed!")

      const genesisPoolInstance = await PaletteRewards.at(genesisPoolAddress)
      await genesisPoolInstance.transferOwnership(clientAddr, { from: accounts[0] })
      console.log("Pool Owner changed!")
    }
  })
}