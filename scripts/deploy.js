import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  console.log(`Deploying to Base Sepolia (chainId: ${chainId})...`);
  console.log(`Deployer: ${deployer.address}`);
  const contracts = {};

  const BV = await hre.artifacts.readArtifact("BridgeValidator");
  const bvFactory = new ethers.ContractFactory(BV.abi, BV.bytecode, deployer);
  const bv = await bvFactory.deploy();
  await bv.waitForDeployment();
  contracts.BridgeValidator = await bv.getAddress();
  console.log(`  BridgeValidator: ${contracts.BridgeValidator}`);

  const SW = await hre.artifacts.readArtifact("SequencerWatchdog");
  const swFactory = new ethers.ContractFactory(SW.abi, SW.bytecode, deployer);
  const sw = await swFactory.deploy();
  await sw.waitForDeployment();
  contracts.SequencerWatchdog = await sw.getAddress();
  console.log(`  SequencerWatchdog: ${contracts.SequencerWatchdog}`);

  const baseUrl = "https://sepolia.basescan.org";
  console.log(`\nVerify on Base Explorer:`);
  for (const [name, addr] of Object.entries(contracts)) {
    console.log(`  ${name}: ${baseUrl}/address/${addr}`);
  }
  console.log(JSON.stringify({ network: "base_sepolia", chainId, deployer: deployer.address, contracts }, null, 2));
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });
