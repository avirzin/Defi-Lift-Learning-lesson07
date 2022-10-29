// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  // We get the contract to deploy
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account:, ${deployer.address}`);
  console.log(`Account balance:, ${(await deployer.getBalance()).toString()}`);

  const Token = await hre.ethers.getContractFactory("LiftAMMX");
  console.log("Start the deployment of the contract...");
  
  // For the regular tokens
  const token = await Token.deploy("0x0eAd6724eb25dA8D8D408B4B2eA4e905e490D9f2","0x32fE6311D4BCf42b7Be745645Cf9f6E2Cfb65449");

  //await token.deployed();
  console.log("Token deployed to:", token.address); 

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});