require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config({path:__dirname+'/.env'})
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");

const { INFURA_URL, WALLET_PRIVATE_KEY,  POLYGONSCAN_API_KEY} = process.env
const gwei = 1000000000;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_URL}`,
      accounts: [`${WALLET_PRIVATE_KEY}`],
      gasPrice: 75*gwei
    },
  },
  etherscan: {
    apiKey: POLYGONSCAN_API_KEY
  }
};