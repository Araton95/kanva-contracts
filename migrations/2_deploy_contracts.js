const StakingFactory = artifacts.require('StakingFactory')
const PaletteRewards = artifacts.require('PaletteRewards')
const KanvaToken = artifacts.require('KanvaToken')
const KanvaLtd = artifacts.require('KanvaLtd')

// Allocation values from whitepaper
// Addresses should be changed to Mainnet addresses
const liquidityTokens = {
  KnvEth: { address: '0xceba66d50248d182cce9ce2ee0f6d004a3c4b200', allocation: '435600000000' },
  UsdcEth: { address: '0xbc30AaA8e99d0f0e435FC938034850c2fC77f753', allocation: '64800000000' },
  UsdtEth: { address: '0x230c4C6De893F369920a94Bd354589EA1A8BcAfD', allocation: '64800000000' },
  DaiEth: { address: '0xE8c6d3d1612cfD65e3D8fcAB3bA90D100029a79C', allocation: '64800000000' },
}

// The staking mechanism start time
// On production it can be hardcoded (like 1 DEC 2020)
// Now we are using current time + 100 seconds (means staking will start after 100 seconds)
const genesisTimeblock = () => Math.round((new Date()).getTime() / 1000) + 100

module.exports = (deployer, network, accounts) => {
  const stakingFactory = '' // TODO
  const kanvaLtd = '0x965132C8a37d778ad08Dc6a8188AfA472A8Bc12c'
  const kanvaToken = '0x02aBAa1122B22D27b381996ef1D04a95fF738366'

  // Owner of contracts
  // Receiver of KNV tokens
  const clientAddr = '0xeb8a34733ae825Eb4c45a345D586071f390B6B6f'

  // OpenSea Mainnet param.
  // Supported for Rinkeby and Mainnet only!
  // More info here: https://blog.ippon.tech/non-fungible-tokens-on-the-ethereum-blockchain/
  const proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'

  // Should be changed in the future
  const metaDataUri = 'https://api.kanva.org/tokenId/'
  const contractUri = 'https://api.kanva.org/contractUri/'


  deployer.then(async () => {
    if (!stakingFactory && !kanvaLtd && !kanvaToken) {
      const kanvaTokenInstance = await deployer.deploy(KanvaToken, clientAddr)
      const kanvaLtdInstance = await deployer.deploy(KanvaLtd, contractUri, metaDataUri, proxyRegistryAddress)
      const stakingFactoryInstance = await deployer.deploy(StakingRewardsFactory, kanvaTokenInstance.address, genesisTimeblock())

      console.log("---------------")
      console.log("KNV =>", kanvaTokenInstance.address)
      console.log("KANVA =>", kanvaLtdInstance.address)
      console.log("FACTORY =>", stakingFactoryInstance.address)
    } else if (stakingFactory && kanvaLtd && kanvaToken) {
      // Deploy KNV/ETH staking pool
      const stakingFactoryInstance = await StakingRewardsFactory.at(stakingFactory)

      const a = await stakingFactoryInstance.methods.deploy(liquidityTokens['UsdcEth']['address'], liquidityTokens['UsdcEth']['allocation'])
      const b = await stakingFactoryInstance.methods.deploy(liquidityTokens['UsdtEth']['address'], liquidityTokens['UsdtEth']['allocation'])
      const c = await stakingFactoryInstance.methods.deploy(liquidityTokens['DaiEth']['address'], liquidityTokens['DaiEth']['allocation'])
      const d = await stakingFactoryInstance.methods.deployKnv(kanvaLtd, liquidityTokens['KnvEth']['address'], liquidityTokens['KnvEth']['allocation'])

      const genesisPoolAddress = await stakingFactory.methods.stakingTokens(3).call()
      const genesisPoolInstance = await PaletteRewards.at(genesisPoolAddress)

      await kanvaLtdInstance.addMinter(genesisPoolInstance.address, { from: accounts[0] })
      console.log("Minter added!")

      await kanvaLtdInstance.addWhitelistAdmin(clientAddr, { from: accounts[0] })
      console.log("Whitelist admin added!")

      await kanvaLtdInstance.transferOwnership(clientAddr, { from: accounts[0] })
      console.log("NFT Owner changed!")

      await genesisPoolInstance.transferOwnership(clientAddr, { from: accounts[0] })
      console.log("Pool Owner changed!")
    }
  })
}