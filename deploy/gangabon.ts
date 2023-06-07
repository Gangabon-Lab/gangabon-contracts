import { HardhatRuntimeEnvironment } from "hardhat/types"
import { Gangabon__factory } from "../typechain"
import { ethers } from "hardhat"

const applications = [
  {
    cid: "bafybeiarutptrdonfhgbgaefejkz7deodrr6vcdpehnvnzitdz6bgfqeja",
    companyName: "Energy Auditor Company",
  },
  {
    cid: "bafybeid46rt5c7abpr7xda6r22l6irojcksirmnotbe5n3gn6bm6lypr2i",
    companyName: "ESG Checker Corporation",
  },
  {
    cid: "bafybeibi672hyzwfywx2xhrly3pkjpx7axdwuueybybh6qmfrinjlxdj7m",
    companyName: "MRV Company",
  },
  {
    cid: "bafybeiagcfl7seie3tnp7upupf3cawtdcozoxnm4ypzeb3iohcbumjnplu",
    companyName: "ESG Checker Corporation",
  },
  {
    cid: "bafybeihx2ovb27pxmoaxrijiptxx34ub7dyf3viy435mk5lcf75h5eiu3i",
    companyName: "MRV Company",
  },
]

module.exports = async ({
  getNamedAccounts,
  deployments,
  network,
}: HardhatRuntimeEnvironment) => {
  const { deploy } = deployments

  const { deployer, dev } = await getNamedAccounts()

  const deadlinePeriod = 10000
  const passAmount = 2
  const uri = ""
  const voteRequired = 3

  const gangabonDeployment = "Gangabon"
  const gangabonResult = await deploy(gangabonDeployment, {
    contract: "Gangabon",
    from: deployer,
    args: [deadlinePeriod, passAmount, uri],
    log: true,
    deterministicDeployment: false,
  })

  console.log(`${gangabonDeployment} was deployed`)

  const gangabonContract = Gangabon__factory.connect(
    gangabonResult.address,
    (await ethers.getSigners())[0]
  )

  for (const application of applications) {
    const tx = await gangabonContract.createApplication(
      application.cid,
      application.companyName,
      voteRequired
    )

    await tx.wait()

    console.log(`Application ${application.companyName} was created`)
    console.log(`On transaction ${tx.hash}`)
  }

  // await hre.run("verify:verify", {
  // 	address: gangabonResult.address,
  // 	constructorArguments: [deadlinePeriod, passAmount, uri],
  // })
}

module.exports.tags = ["GangabonContract"]
