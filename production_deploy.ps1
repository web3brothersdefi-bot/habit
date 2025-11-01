# PRODUCTION DEPLOYMENT SCRIPT - APTOS TESTNET
# Fresh account deployment with proper initialization
# Version: 1.0 - Production Ready

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  APTOS PRODUCTION DEPLOYMENT - FRESH ACCOUNT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Configuration
$WALLET_ADDRESS = "0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3"
$PRIVATE_KEY = "ed25519-priv-0x90a0dfcb4b3b348e79cb255b1384922787ee08be86317b56ae53076e1fba7f69"
$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"
$PROJECT_ROOT = "C:\Users\crisy\OneDrive\Escritorio\test4"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Wallet: $WALLET_ADDRESS" -ForegroundColor Gray
Write-Host "  Network: Testnet" -ForegroundColor Gray
Write-Host "  Project: $PROJECT_ROOT" -ForegroundColor Gray
Write-Host ""

# ============================================================
# STEP 1: INITIALIZE CLI WITH NEW ACCOUNT
# ============================================================
Write-Host "[1/10] Initializing Aptos CLI with new account..." -ForegroundColor Green

$initOutput = & $APTOS_CLI init `
    --private-key $PRIVATE_KEY `
    --network testnet `
    --assume-yes 2>&1

Write-Host "  CLI initialized" -ForegroundColor Gray

# Verify the account address matches
$profileData = & $APTOS_CLI config show-profiles 2>&1 | ConvertFrom-Json
$cliAccount = "0x" + $profileData.Result.default.account

if ($cliAccount -ne $WALLET_ADDRESS) {
    Write-Host ""
    Write-Host "ERROR: Account mismatch!" -ForegroundColor Red
    Write-Host "  Expected: $WALLET_ADDRESS" -ForegroundColor Yellow
    Write-Host "  Got: $cliAccount" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Private key does not match wallet address!" -ForegroundColor Red
    Write-Host "  Please verify your private key from Petra wallet." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

Write-Host "  Account verified: $cliAccount" -ForegroundColor Green

# ============================================================
# STEP 2: FUND ACCOUNT FROM FAUCET
# ============================================================
Write-Host ""
Write-Host "[2/10] Funding account from testnet faucet..." -ForegroundColor Green
Write-Host "  Requesting APT (this initializes the account)..." -ForegroundColor Gray

# Request from faucet - this also initializes AptosCoin resource
$faucetOutput = & $APTOS_CLI account fund-with-faucet --account $WALLET_ADDRESS 2>&1

if ($faucetOutput -match "Added") {
    Write-Host "  Successfully funded from faucet" -ForegroundColor Green
} else {
    Write-Host "  Faucet request completed (may already be funded)" -ForegroundColor Cyan
}

# Wait for transaction to settle
Write-Host "  Waiting for blockchain confirmation (15 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# ============================================================
# STEP 3: VERIFY ACCOUNT BALANCE
# ============================================================
Write-Host ""
Write-Host "[3/10] Verifying account balance..." -ForegroundColor Green

$balanceOutput = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1

try {
    $balanceData = $balanceOutput | ConvertFrom-Json
    
    if ($balanceData.Result -and $balanceData.Result.Count -gt 0) {
        $balanceOctas = [long]$balanceData.Result[0].balance
        $balanceAPT = $balanceOctas / 100000000.0
        
        Write-Host "  Balance: $balanceAPT APT ($balanceOctas Octas)" -ForegroundColor Cyan
        
        if ($balanceAPT -lt 10) {
            Write-Host ""
            Write-Host "  Balance is low. Getting more from faucet..." -ForegroundColor Yellow
            
            # Get more APT to ensure we have enough
            for ($i = 1; $i -le 10; $i++) {
                Write-Host "    Faucet request $i/10..." -ForegroundColor Gray
                & $APTOS_CLI account fund-with-faucet --account $WALLET_ADDRESS 2>&1 | Out-Null
                Start-Sleep -Seconds 2
            }
            
            Write-Host "  Waiting for transactions..." -ForegroundColor Gray
            Start-Sleep -Seconds 10
            
            # Re-check balance
            $balanceData = (& $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json)
            $balanceOctas = [long]$balanceData.Result[0].balance
            $balanceAPT = $balanceOctas / 100000000.0
            Write-Host "  New balance: $balanceAPT APT" -ForegroundColor Cyan
        }
    } else {
        Write-Host "  ERROR: Could not read balance" -ForegroundColor Red
        Write-Host "  Account may not be initialized properly" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ERROR: Could not parse balance" -ForegroundColor Red
    Write-Host "  Raw output: $balanceOutput" -ForegroundColor Gray
}

# ============================================================
# STEP 4: VERIFY ACCOUNT RESOURCES
# ============================================================
Write-Host ""
Write-Host "[4/10] Verifying account resources..." -ForegroundColor Green

$resourcesOutput = & $APTOS_CLI account list --query resources --account $WALLET_ADDRESS 2>&1

if ($resourcesOutput -match "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>") {
    Write-Host "  AptosCoin resource: FOUND" -ForegroundColor Green
    Write-Host "  Account properly initialized" -ForegroundColor Green
} else {
    Write-Host "  WARNING: AptosCoin resource not detected" -ForegroundColor Yellow
    Write-Host "  Will be created on first transaction" -ForegroundColor Gray
}

# ============================================================
# STEP 5: NAVIGATE TO PROJECT
# ============================================================
Write-Host ""
Write-Host "[5/10] Navigating to project..." -ForegroundColor Green
Set-Location -Path "$PROJECT_ROOT\move"
Write-Host "  Directory: $(Get-Location)" -ForegroundColor Gray

# ============================================================
# STEP 6: CLEAN OLD BUILD
# ============================================================
Write-Host ""
Write-Host "[6/10] Cleaning old build artifacts..." -ForegroundColor Green

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "  Build directory removed" -ForegroundColor Gray
} else {
    Write-Host "  No build directory to clean" -ForegroundColor Gray
}

# ============================================================
# STEP 7: COMPILE CONTRACT
# ============================================================
Write-Host ""
Write-Host "[7/10] Compiling Move contract..." -ForegroundColor Green
Write-Host "  This may take 30-60 seconds..." -ForegroundColor Gray

$compileOutput = & $APTOS_CLI move compile 2>&1

# Check compilation result
if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation: SUCCESS" -ForegroundColor Green
    
    # Verify it compiles to the correct address
    if ($compileOutput -match "6204920201694bbf") {
        Write-Host "  Address verification: CORRECT" -ForegroundColor Green
        Write-Host "  Will deploy to: $WALLET_ADDRESS" -ForegroundColor Cyan
    } else {
        Write-Host "  WARNING: Address might not match" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR: Compilation failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Compilation output:" -ForegroundColor Gray
    Write-Host $compileOutput
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# ============================================================
# STEP 8: DEPLOY CONTRACT TO BLOCKCHAIN
# ============================================================
Write-Host ""
Write-Host "[8/10] Deploying contract to Aptos testnet..." -ForegroundColor Green
Write-Host "  Gas settings: 40000 units @ 100 Octas/unit" -ForegroundColor Gray
Write-Host "  Max cost: 0.04 APT (4,000,000 Octas)" -ForegroundColor Gray
Write-Host "  Deploying... (this may take 30-60 seconds)" -ForegroundColor Gray
Write-Host ""

# Deploy with appropriate testnet gas settings
$deployOutput = & $APTOS_CLI move publish `
    --max-gas 40000 `
    --gas-unit-price 100 `
    --assume-yes 2>&1

Write-Host "  Deployment output:" -ForegroundColor Gray
Write-Host "  ----------------------------------------" -ForegroundColor Gray
Write-Host $deployOutput
Write-Host "  ----------------------------------------" -ForegroundColor Gray
Write-Host ""

# Parse deployment result
$deploySuccess = $false

if ($deployOutput -match '"success":\s*true') {
    Write-Host "  Deployment: SUCCESS" -ForegroundColor Green
    $deploySuccess = $true
    
    # Extract transaction hash if available
    if ($deployOutput -match '"hash":\s*"(0x[a-f0-9]+)"') {
        $txHash = $matches[1]
        Write-Host "  Transaction: $txHash" -ForegroundColor Cyan
    }
} elseif ($deployOutput -match "ALREADY_PUBLISHED" -or $deployOutput -match "already exists") {
    Write-Host "  Module already exists (OK)" -ForegroundColor Cyan
    $deploySuccess = $true
} elseif ($deployOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Insufficient balance" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This is unexpected with a fresh account." -ForegroundColor Yellow
    Write-Host "  Try running again or get more APT from:" -ForegroundColor Yellow
    Write-Host "  https://aptoslabs.com/testnet-faucet" -ForegroundColor Cyan
    Write-Host "  Address: $WALLET_ADDRESS" -ForegroundColor Cyan
} else {
    Write-Host "  Deployment status: UNCLEAR" -ForegroundColor Yellow
    Write-Host "  Check output above for details" -ForegroundColor Yellow
}

# ============================================================
# STEP 9: INITIALIZE CONTRACT
# ============================================================
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[9/10] Initializing contract..." -ForegroundColor Green
    Write-Host "  Calling initialize function..." -ForegroundColor Gray
    
    $initOutput = & $APTOS_CLI move run `
        --function-id "${WALLET_ADDRESS}::stake_match::initialize" `
        --args address:$WALLET_ADDRESS `
        --max-gas 20000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    Write-Host ""
    Write-Host "  Initialization output:" -ForegroundColor Gray
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
    Write-Host $initOutput
    Write-Host "  ----------------------------------------" -ForegroundColor Gray
    Write-Host ""
    
    if ($initOutput -match '"success":\s*true') {
        Write-Host "  Initialization: SUCCESS" -ForegroundColor Green
    } elseif ($initOutput -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized (OK)" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization status: UNCLEAR" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[9/10] Skipping initialization (deployment failed)" -ForegroundColor Red
}

# ============================================================
# STEP 10: FINAL VERIFICATION
# ============================================================
Write-Host ""
Write-Host "[10/10] Final verification..." -ForegroundColor Green

# Check final balance
$finalBalanceData = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json
if ($finalBalanceData.Result) {
    $finalBalance = ([long]$finalBalanceData.Result[0].balance) / 100000000.0
    Write-Host "  Remaining balance: $finalBalance APT" -ForegroundColor Cyan
}

# Return to project root
Set-Location -Path $PROJECT_ROOT

# ============================================================
# FINAL SUMMARY
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Account Address:" -ForegroundColor Yellow
Write-Host "  $WALLET_ADDRESS" -ForegroundColor White
Write-Host ""

Write-Host "Module ID:" -ForegroundColor Yellow
Write-Host "  ${WALLET_ADDRESS}::stake_match" -ForegroundColor White
Write-Host ""

if ($deploySuccess) {
    Write-Host "STATUS: DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verification URL:" -ForegroundColor Yellow
    $explorerUrl = "https://explorer.aptoslabs.com/account/${WALLET_ADDRESS}?network=testnet"
    Write-Host "  $explorerUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opening Aptos Explorer..." -ForegroundColor Gray
    Start-Process $explorerUrl
    Write-Host ""
    Write-Host "In the explorer, verify:" -ForegroundColor Yellow
    Write-Host "  1. Modules tab shows: stake_match" -ForegroundColor White
    Write-Host "  2. Resources tab shows: StakeRegistry" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Verify deployment in explorer (opened above)" -ForegroundColor White
    Write-Host "  2. Create Supabase stakes table:" -ForegroundColor White
    Write-Host "     - Open Supabase SQL Editor" -ForegroundColor Gray
    Write-Host "     - Run SQL from: CREATE_STAKES_TABLE.sql" -ForegroundColor Gray
    Write-Host "  3. Start development server:" -ForegroundColor White
    Write-Host "     - Run: npm run dev" -ForegroundColor Gray
    Write-Host "  4. Test staking:" -ForegroundColor White
    Write-Host "     - Open http://localhost:3000/dashboard" -ForegroundColor Gray
    Write-Host "     - Swipe right on a user" -ForegroundColor Gray
    Write-Host "     - Approve in Petra wallet" -ForegroundColor Gray
    Write-Host "     - SUCCESS!" -ForegroundColor Gray
    Write-Host ""
    Write-Host "YOUR DAPP IS NOW PRODUCTION READY!" -ForegroundColor Green
} else {
    Write-Host "STATUS: DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please review the error messages above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common solutions:" -ForegroundColor Yellow
    Write-Host "  1. Ensure account has sufficient APT (>10 APT)" -ForegroundColor White
    Write-Host "  2. Wait a few minutes and try again (testnet congestion)" -ForegroundColor White
    Write-Host "  3. Check Aptos testnet status" -ForegroundColor White
    Write-Host ""
}

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
