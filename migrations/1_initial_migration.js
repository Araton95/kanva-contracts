const GenesisPool = artifacts.require('GenesisPool')
const KanvaToken = artifacts.require('KanvaToken')
const KanvaLtd = artifacts.require('KanvaLtd')

module.exports = (deployer, network, accounts) => {
  let lpToken = ''
  let kanvaLtd = ''
  let kanvaToken = ''

  const [ owner, receiver, proxyRegistryAddress ] = accounts

  deployer.then(async () => {
    if (!lpToken && !kanvaLtd && !kanvaToken) {
      const kanvaTokenInstance = await deployer.deploy(KanvaToken, receiver)
      const kanvaLtdInstance = await deployer.deploy(KanvaLtd, "test.uri", "test.uri", proxyRegistryAddress)

      console.log("---------------")
      console.log("KNV Address =>", kanvaTokenInstance.address)
      console.log("KANVA Address =>", kanvaLtdInstance.address)
    } else if (lpToken && kanvaLtd && kanvaToken) {
      // Genesis pool contract should be deployed after KNV/ETH LP-V2 token creation
      const genesisPoolInstance = await deployer.deploy(GenesisPool, kanvaLtdInstance.address, lpToken)
      console.log("Pool address =>", genesisPoolInstance.address)

      const kanvaLtdInstance = await kanvaLtdInstance.at(kanvaLtd)
      await kanvaLtdInstance.addMinter(genesisPoolInstance.address, { from: owner })
      console.log("Minter added tx!")
    }
  })
}