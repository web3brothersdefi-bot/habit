import { aptosClient, MODULE_ADDRESS, MODULE_ID } from '../config/aptos';
import { toast } from 'react-hot-toast';

/**
 * Comprehensive contract diagnostics
 */
export async function diagnoseContract() {
  console.log('🔍 Starting Contract Diagnostics...\n');
  
  const results = {
    moduleExists: false,
    isInitialized: false,
    accountExists: false,
    hasResources: false,
    errorDetails: null as any,
  };

  try {
    // Step 1: Check if account exists
    console.log(`📍 Step 1: Checking if account ${MODULE_ADDRESS} exists...`);
    try {
      const account = await aptosClient.getAccountInfo({
        accountAddress: MODULE_ADDRESS,
      });
      results.accountExists = true;
      console.log('✅ Account exists!');
      console.log(`   Sequence Number: ${account.sequence_number}`);
    } catch (error: any) {
      results.accountExists = false;
      console.error('❌ Account does not exist!');
      console.error(`   Error: ${error.message}`);
      results.errorDetails = error;
      return results;
    }

    // Step 2: Check account resources
    console.log('\n📍 Step 2: Checking account resources...');
    try {
      const resources = await aptosClient.getAccountResources({
        accountAddress: MODULE_ADDRESS,
      });
      results.hasResources = resources.length > 0;
      console.log(`✅ Found ${resources.length} resources`);
      
      resources.forEach((resource, idx) => {
        console.log(`   ${idx + 1}. ${resource.type}`);
      });
    } catch (error: any) {
      console.error('❌ Failed to fetch resources');
      console.error(`   Error: ${error.message}`);
    }

    // Step 3: Check if module exists
    console.log('\n📍 Step 3: Checking if module exists...');
    try {
      const modules = await aptosClient.getAccountModules({
        accountAddress: MODULE_ADDRESS,
      });
      
      const stakeMatchModule = modules.find(
        (mod) => mod.abi?.name === 'stake_match'
      );
      
      if (stakeMatchModule) {
        results.moduleExists = true;
        console.log('✅ Module stake_match found!');
        console.log(`   ABI Functions: ${stakeMatchModule.abi?.exposed_functions?.length || 0}`);
        
        // List functions
        if (stakeMatchModule.abi?.exposed_functions) {
          console.log('   📋 Available functions:');
          stakeMatchModule.abi.exposed_functions.forEach((fn: any) => {
            console.log(`      - ${fn.name}`);
          });
        }
      } else {
        results.moduleExists = false;
        console.error('❌ Module stake_match NOT found!');
        console.log(`   Found ${modules.length} modules:`);
        modules.forEach((mod, idx) => {
          console.log(`   ${idx + 1}. ${mod.abi?.name || 'unnamed'}`);
        });
      }
    } catch (error: any) {
      results.moduleExists = false;
      console.error('❌ Failed to fetch modules');
      console.error(`   Error: ${error.message}`);
      results.errorDetails = error;
    }

    // Step 4: Check if contract is initialized
    if (results.moduleExists) {
      console.log('\n📍 Step 4: Checking if contract is initialized...');
      try {
        const resources = await aptosClient.getAccountResources({
          accountAddress: MODULE_ADDRESS,
        });
        
        const registryResource = resources.find(
          (r) => r.type === `${MODULE_ID}::StakeRegistry`
        );
        
        if (registryResource) {
          results.isInitialized = true;
          console.log('✅ Contract is initialized!');
          console.log(`   Registry data:`, registryResource.data);
        } else {
          results.isInitialized = false;
          console.error('❌ Contract NOT initialized!');
          console.log('   💡 Need to call initialize() function');
        }
      } catch (error: any) {
        console.error('❌ Failed to check initialization');
        console.error(`   Error: ${error.message}`);
      }
    }

  } catch (error: any) {
    console.error('\n❌ Diagnostic failed with error:', error);
    results.errorDetails = error;
  }

  // Print summary
  console.log('\n📊 DIAGNOSTIC SUMMARY:');
  console.log(`   Account Exists: ${results.accountExists ? '✅' : '❌'}`);
  console.log(`   Has Resources: ${results.hasResources ? '✅' : '❌'}`);
  console.log(`   Module Exists: ${results.moduleExists ? '✅' : '❌'}`);
  console.log(`   Is Initialized: ${results.isInitialized ? '✅' : '❌'}`);

  // Provide recommendations
  console.log('\n💡 RECOMMENDATIONS:');
  if (!results.accountExists) {
    console.log('   1. ❌ The MODULE_ADDRESS account does not exist on Aptos Testnet');
    console.log('   2. 🔧 You need to deploy the contract with the correct account');
    console.log('   3. 📝 Update VITE_MODULE_ADDRESS in .env with your wallet address');
  } else if (!results.moduleExists) {
    console.log('   1. ❌ The stake_match module is not deployed');
    console.log('   2. 🔧 Run: cd move && aptos move publish --assume-yes');
    console.log('   3. 📝 Make sure Move.toml has the correct address');
  } else if (!results.isInitialized) {
    console.log('   1. ❌ Contract exists but not initialized');
    console.log('   2. 🔧 Call the initialize() function');
    console.log('   3. 📝 Use the initialization UI or run via CLI');
  } else {
    console.log('   ✅ Everything looks good! Contract is ready.');
  }

  console.log('\n');
  return results;
}

/**
 * Show diagnostic results in UI
 */
export async function showContractDiagnostics() {
  const loadingToast = toast.loading('Running contract diagnostics...');
  
  try {
    const results = await diagnoseContract();
    toast.dismiss(loadingToast);

    if (!results.accountExists) {
      toast.error(
        'Contract account does not exist! Check console for details.',
        { duration: 8000 }
      );
      return false;
    } else if (!results.moduleExists) {
      toast.error(
        'Module stake_match not found! Contract needs to be deployed. Check console.',
        { duration: 8000 }
      );
      return false;
    } else if (!results.isInitialized) {
      toast.error(
        'Contract found but not initialized! Click "Initialize Contract".',
        { duration: 6000 }
      );
      return false;
    } else {
      toast.success('Contract is ready! ✅');
      return true;
    }
  } catch (error: any) {
    toast.dismiss(loadingToast);
    toast.error(`Diagnostic failed: ${error.message}`);
    return false;
  }
}

/**
 * Quick check if contract is ready
 */
export async function isContractReady(): Promise<boolean> {
  try {
    const resources = await aptosClient.getAccountResources({
      accountAddress: MODULE_ADDRESS,
    });
    
    const registryExists = resources.some(
      (r) => r.type === `${MODULE_ID}::StakeRegistry`
    );
    
    return registryExists;
  } catch {
    return false;
  }
}
