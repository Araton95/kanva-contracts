const GenesisPool = artifacts.require('GenesisPool')
const KanvaToken = artifacts.require('KanvaToken')
const KanvaLtd = artifacts.require('KanvaLtd')

module.exports = (deployer, network, accounts) => {
  const lpToken = '0xceba66d50248d182cce9ce2ee0f6d004a3c4b200'
  const kanvaLtd = '0x965132C8a37d778ad08Dc6a8188AfA472A8Bc12c'
  const kanvaToken = '0x02aBAa1122B22D27b381996ef1D04a95fF738366'
  const [ deployerAddress ] = accounts
  const receiver = '0xeb8a34733ae825Eb4c45a345D586071f390B6B6f'

  // Should be changed in the future
  const metaDataUri = 'https://api.kanva.org/tokenId/'
  const contractUri = 'https://api.kanva.org/contractUri/'

  // OpenSea Mainnet param.
  // Supported for Rinkeby and Mainnet only!
  // More info here: https://blog.ippon.tech/non-fungible-tokens-on-the-ethereum-blockchain/
  const proxyRegistryAddress = '0xa5409ec958c83c3f309868babaca7c86dcb077c1'

  deployer.then(async () => {
    if (!lpToken && !kanvaLtd && !kanvaToken) {
      const kanvaTokenInstance = await deployer.deploy(KanvaToken, receiver)
      const kanvaLtdInstance = await deployer.deploy(KanvaLtd, contractUri, metaDataUri, proxyRegistryAddress)

      console.log("---------------")
      console.log("KNV =>", kanvaTokenInstance.address)
      console.log("KANVA =>", kanvaLtdInstance.address)
    } else if (lpToken && kanvaLtd && kanvaToken) {
      // Genesis pool contract should be deployed after KNV/ETH LP-V2 token creation
      const genesisPoolInstance = await deployer.deploy(GenesisPool, kanvaLtd, lpToken)
      console.log("Pool address =>", genesisPoolInstance.address)

      const kanvaLtdInstance = await KanvaLtd.at(kanvaLtd)

      await kanvaLtdInstance.addMinter(genesisPoolInstance.address, { from: deployerAddress })
      console.log("Minter added!")

      await kanvaLtdInstance.addWhitelistAdmin(receiver, { from: deployerAddress })
      console.log("Whitelist admin added!")

      await kanvaLtdInstance.transferOwnership(receiver, { from: deployerAddress })
      console.log("NFT Owner changed!")

      await genesisPoolInstance.transferOwnership(receiver, { from: deployerAddress })
      console.log("Pool Owner changed!")
    }
  })
}