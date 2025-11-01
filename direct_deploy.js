// Direct deployment using Aptos TypeScript SDK
// This bypasses CLI issues and deploys directly

import { Aptos, AptosConfig, Network, Account, Ed25519PrivateKey } from "@aptos-labs/ts-sdk";
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// ES module __dirname equivalent
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration
const PRIVATE_KEY_HEX = "0x90a0dfcb4b3b348e79cb255b1384922787ee08be86317b56ae53076e1fba7f69";
const NETWORK = Network.DEVNET;

console.log("\n================================================================");
console.log("  DIRECT DEPLOYMENT USING APTOS TYPESCRIPT SDK");
console.log("================================================================\n");

async function deploy() {
  try {
    // Step 1: Initialize Aptos client
    console.log("[1/8] Initializing Aptos client...");
    const config = new AptosConfig({ network: NETWORK });
    const aptos = new Aptos(config);
    console.log("  Network: DEVNET");
    
    // Step 2: Create account from private key
    console.log("\n[2/8] Loading account from private key...");
    const privateKey = new Ed25519PrivateKey(PRIVATE_KEY_HEX);
    const account = Account.fromPrivateKey({ privateKey });
    console.log(`  Address: ${account.accountAddress.toString()}`);
    
    // Step 3: Check balance
    console.log("\n[3/8] Checking balance...");
    const resources = await aptos.getAccountResources({
      accountAddress: account.accountAddress
    });
    
    const coinResource = resources.find(r => 
      r.type === "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
    );
    
    if (coinResource) {
      const balance = coinResource.data.coin.value;
      const aptBalance = Number(balance) / 100000000;
      console.log(`  Balance: ${aptBalance} APT`);
      console.log(`  CoinStore resource: EXISTS`);
    } else {
      console.log(`  WARNING: No CoinStore resource!`);
      console.log(`  Account needs initialization transaction first`);
      
      // Try to fund from faucet to initialize
      console.log(`\n  Attempting to initialize with faucet...`);
      try {
        await aptos.fundAccount({
          accountAddress: account.accountAddress,
          amount: 100000000 // 1 APT
        });
        console.log(`  Faucet request sent, waiting 10 seconds...`);
        await new Promise(resolve => setTimeout(resolve, 10000));
      } catch (e) {
        console.log(`  Faucet error: ${e.message}`);
      }
    }
    
    // Step 4: Read compiled module
    console.log("\n[4/8] Reading compiled Move bytecode...");
    const buildPath = path.join(__dirname, 'move', 'build', 'HabitPlatform', 'bytecode_modules');
    
    if (!fs.existsSync(buildPath)) {
      console.error(`  ERROR: Bytecode not found at ${buildPath}`);
      console.error(`  Run 'aptos move compile' first!`);
      process.exit(1);
    }
    
    const moduleFile = path.join(buildPath, 'stake_match.mv');
    if (!fs.existsSync(moduleFile)) {
      console.error(`  ERROR: stake_match.mv not found!`);
      console.error(`  Run 'aptos move compile' first!`);
      process.exit(1);
    }
    
    const moduleBytes = fs.readFileSync(moduleFile);
    console.log(`  Module size: ${moduleBytes.length} bytes`);
    console.log(`  File: ${moduleFile}`);
    
    // Step 5: Publish module using simple transaction
    console.log("\n[5/8] Publishing module to devnet...");
    console.log("  This may take 30-60 seconds...");
    
    // Create raw transaction for module publication
    // package_metadata should be serialized empty vector
    // code should be vector of module bytecode
    const transaction = await aptos.transaction.build.simple({
      sender: account.accountAddress,
      data: {
        function: "0x1::code::publish_package_txn",
        functionArguments: [
          // Empty metadata serialized as BCS
          new Uint8Array([0]), // BCS encoding of empty vector
          // Module bytecode as vector
          [moduleBytes]
        ]
      }
    });
    
    console.log("  Transaction built, signing and submitting...");
    
    const pendingTxn = await aptos.signAndSubmitTransaction({
      signer: account,
      transaction
    });
    
    console.log(`  Transaction hash: ${pendingTxn.hash}`);
    console.log(`  Waiting for confirmation...`);
    
    // Wait for transaction
    const committedTxn = await aptos.waitForTransaction({
      transactionHash: pendingTxn.hash
    });
    
    console.log(`  Transaction confirmed!`);
    console.log(`  Success: ${committedTxn.success}`);
    console.log(`  VM Status: ${committedTxn.vm_status}`);
    console.log(`  Gas used: ${committedTxn.gas_used}`);
    
    if (!committedTxn.success) {
      console.error(`\n  ERROR: Transaction failed!`);
      console.error(`  VM Status: ${committedTxn.vm_status}`);
      process.exit(1);
    }
    
    console.log("\n  DEPLOYMENT: SUCCESS!");
    
    // Step 6: Initialize contract
    console.log("\n[6/8] Initializing contract...");
    
    const initTxn = await aptos.transaction.build.simple({
      sender: account.accountAddress,
      data: {
        function: `${account.accountAddress.toString()}::stake_match::initialize`,
        functionArguments: [account.accountAddress.toString()]
      }
    });
    
    const initPending = await aptos.signAndSubmitTransaction({
      signer: account,
      transaction: initTxn
    });
    
    console.log(`  Transaction hash: ${initPending.hash}`);
    
    const initCommitted = await aptos.waitForTransaction({
      transactionHash: initPending.hash
    });
    
    console.log(`  Initialization: ${initCommitted.success ? 'SUCCESS' : 'FAILED'}`);
    
    if (initCommitted.success) {
      console.log(`  VM Status: ${initCommitted.vm_status}`);
    }
    
    // Step 7: Verify deployment
    console.log("\n[7/8] Verifying deployment...");
    
    const modules = await aptos.getAccountModules({
      accountAddress: account.accountAddress
    });
    
    const stakeModule = modules.find(m => m.abi.name === 'stake_match');
    
    if (stakeModule) {
      console.log(`  Module 'stake_match': FOUND`);
      console.log(`  Functions: ${stakeModule.abi.exposed_functions.length}`);
    } else {
      console.log(`  ERROR: Module not found!`);
    }
    
    // Check for StakeRegistry resource
    const accountResources = await aptos.getAccountResources({
      accountAddress: account.accountAddress
    });
    
    const stakeRegistry = accountResources.find(r => 
      r.type.includes('StakeRegistry')
    );
    
    if (stakeRegistry) {
      console.log(`  StakeRegistry resource: FOUND`);
      console.log(`  Admin: ${stakeRegistry.data.admin}`);
    } else {
      console.log(`  WARNING: StakeRegistry not found`);
    }
    
    // Step 8: Final summary
    console.log("\n[8/8] Final verification...");
    const finalResources = await aptos.getAccountResources({
      accountAddress: account.accountAddress
    });
    
    const finalCoin = finalResources.find(r => 
      r.type === "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>"
    );
    
    if (finalCoin) {
      const finalBalance = Number(finalCoin.data.coin.value) / 100000000;
      console.log(`  Final balance: ${finalBalance} APT`);
    }
    
    console.log("\n================================================================");
    console.log("  DEPLOYMENT COMPLETE!");
    console.log("================================================================\n");
    
    console.log("SUCCESS! Contract deployed to:");
    console.log(`  ${account.accountAddress.toString()}\n`);
    
    console.log("Verify at:");
    console.log(`  https://explorer.aptoslabs.com/account/${account.accountAddress.toString()}?network=devnet\n`);
    
    console.log("NEXT STEPS:");
    console.log("  1. Verify deployment in devnet explorer");
    console.log("  2. Switch Petra wallet to Devnet");
    console.log("  3. Create Supabase stakes table");
    console.log("  4. Run: npm run dev");
    console.log("  5. Test staking!\n");
    
  } catch (error) {
    console.error("\n================================================================");
    console.error("  DEPLOYMENT FAILED");
    console.error("================================================================\n");
    console.error("Error:", error.message);
    if (error.stack) {
      console.error("\nStack trace:");
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run deployment
deploy();
