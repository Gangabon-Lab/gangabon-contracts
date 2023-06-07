import * as dotenv from "dotenv"

import "@nomiclabs/hardhat-etherscan"
import "@nomicfoundation/hardhat-toolbox"
import "hardhat-deploy"

dotenv.config()

const config = {
  solidity: {
    compilers: [
      {
        version: "0.7.5",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.18",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
            details: {
              yul: false,
            },
          },
        },
      },
    ],
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_URL,
      accounts: [process.env.PRIVATEKEY_DEPLOYER, process.env.PRIVATEKEY_DEV],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    dev: {
      default: 1,
    },
  },
  mocha: {
    timeout: 180e3,
  },
  typechain: {
    outDir: "typechain",
    target: "ethers-v5",
  },
  etherscan: {
    apiKey: process.env.MAINNET_API_KEY,
  },
}

export default config
