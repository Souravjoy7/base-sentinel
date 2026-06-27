import { defineConfig } from "hardhat/config";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";

const DEPLOYER_KEY = process.env.DEPLOYER_PRIVATE_KEY || "0x" + "0".repeat(64);

export default defineConfig({
  plugins: [hardhatEthers],
  solidity: {
    version: "0.8.20",
    settings: { viaIR: true, optimizer: { enabled: true, runs: 200 } }
  },
  networks: {
    base_sepolia: { type: "http", url: "https://sepolia.base.org", accounts: [DEPLOYER_KEY], chainId: 84532 },
  },
});
