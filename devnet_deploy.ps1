# APTOS DEVNET DEPLOYMENT SCRIPT
# Devnet is more stable than testnet for development
# Same functionality, better reliability

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  APTOS DEVNET DEPLOYMENT - PRODUCTION READY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3"
$PRIVATE_KEY = "ed25519-priv-0x90a0dfcb4b3b348e79cb255b1384922787ee08be86317b56ae53076e1fba7f69"
$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"
$NETWORK = "devnet"

Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Wallet: $WALLET_ADDRESS" -ForegroundColor Gray
Write-Host "  Network: DEVNET (stable)" -ForegroundColor Gray
Write-Host "  Same address works on all networks" -ForegroundColor Gray
Write-Host ""

# ============================================================
# STEP 1: INITIALIZE CLI FOR DEVNET
# ============================================================
Write-Host "[1/9] Initializing CLI for Aptos Devnet..." -ForegroundColor Green

$initOutput = & $APTOS_CLI init `
    --private-key $PRIVATE_KEY `
    --network $NETWORK `
    --assume-yes 2>&1

Write-Host "  CLI configured for devnet" -ForegroundColor Gray

# Verify account
$profileData = & $APTOS_CLI config show-profiles 2>&1 | ConvertFrom-Json
$cliAccount = "0x" + $profileData.Result.default.account
$cliNetwork = $profileData.Result.default.network

Write-Host "  Account: $cliAccount" -ForegroundColor Cyan
Write-Host "  Network: $cliNetwork" -ForegroundColor Cyan

if ($cliAccount -ne $WALLET_ADDRESS) {
    Write-Host ""
    Write-Host "  ERROR: Account mismatch!" -ForegroundColor Red
    exit 1
}

if ($cliNetwork -ne "Devnet") {
    Write-Host ""
    Write-Host "  ERROR: Network not set to devnet!" -ForegroundColor Red
    exit 1
}

Write-Host "  Configuration verified" -ForegroundColor Green

# ============================================================
# STEP 2: FUND ACCOUNT FROM DEVNET FAUCET
# ============================================================
Write-Host ""
Write-Host "[2/9] Funding account from devnet faucet..." -ForegroundColor Green
Write-Host "  Devnet faucet is more reliable than testnet" -ForegroundColor Gray

$faucetOutput = & $APTOS_CLI account fund-with-faucet --account $WALLET_ADDRESS 2>&1

Write-Host "  Faucet request sent" -ForegroundColor Gray
Write-Host "  Waiting 10 seconds for confirmation..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# ============================================================
# STEP 3: VERIFY BALANCE
# ============================================================
Write-Host ""
Write-Host "[3/9] Verifying balance..." -ForegroundColor Green

$balanceData = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json

if ($balanceData.Result -and $balanceData.Result.Count -gt 0) {
    $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
    Write-Host "  Balance: $balance APT" -ForegroundColor Cyan
    
    if ($balance -lt 5) {
        Write-Host "  Getting more APT..." -ForegroundColor Yellow
        for ($i = 1; $i -le 10; $i++) {
            Write-Host "    Request $i/10..." -ForegroundColor Gray
            & $APTOS_CLI account fund-with-faucet --account $WALLET_ADDRESS 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        }
        Start-Sleep -Seconds 10
        $balanceData = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json
        $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
        Write-Host "  New balance: $balance APT" -ForegroundColor Cyan
    }
} else {
    Write-Host "  Could not read balance" -ForegroundColor Red
    Write-Host "  Continuing anyway..." -ForegroundColor Yellow
}

# ============================================================
# STEP 4: VERIFY RESOURCES
# ============================================================
Write-Host ""
Write-Host "[4/9] Checking account resources..." -ForegroundColor Green

$resources = & $APTOS_CLI account list --query resources --account $WALLET_ADDRESS 2>&1

if ($resources -match "0x1::coin::CoinStore") {
    Write-Host "  AptosCoin resource: EXISTS" -ForegroundColor Green
} else {
    Write-Host "  AptosCoin resource: Will be created on first transaction" -ForegroundColor Yellow
}

# ============================================================
# STEP 5: NAVIGATE TO PROJECT
# ============================================================
Write-Host ""
Write-Host "[5/9] Navigating to project..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
Write-Host "  Directory: $(Get-Location)" -ForegroundColor Gray

# ============================================================
# STEP 6: CLEAN BUILD
# ============================================================
Write-Host ""
Write-Host "[6/9] Cleaning build..." -ForegroundColor Green

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "  Build cleaned" -ForegroundColor Gray
} else {
    Write-Host "  No build to clean" -ForegroundColor Gray
}

# ============================================================
# STEP 7: COMPILE
# ============================================================
Write-Host ""
Write-Host "[7/9] Compiling Move contract..." -ForegroundColor Green
Write-Host "  This may take 30-60 seconds..." -ForegroundColor Gray

$compileOutput = & $APTOS_CLI move compile 2>&1

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation: SUCCESS" -ForegroundColor Green
    
    if ($compileOutput -match "6204920201694bbf") {
        Write-Host "  Address verified: CORRECT" -ForegroundColor Green
    }
} else {
    Write-Host "  ERROR: Compilation failed" -ForegroundColor Red
    Write-Host $compileOutput
    Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# ============================================================
# STEP 8: DEPLOY TO DEVNET
# ============================================================
Write-Host ""
Write-Host "[8/9] Deploying to Aptos Devnet..." -ForegroundColor Green
Write-Host "  Devnet has better stability than testnet" -ForegroundColor Gray
Write-Host "  Gas: 30000 units @ 100 Octas/unit" -ForegroundColor Gray
Write-Host "  Deploying... (30-60 seconds)" -ForegroundColor Gray
Write-Host ""

$deployOutput = & $APTOS_CLI move publish `
    --max-gas 30000 `
    --gas-unit-price 100 `
    --assume-yes 2>&1

Write-Host "  Deployment output:" -ForegroundColor Gray
Write-Host "  ========================================" -ForegroundColor Gray
$deployOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host "  ========================================" -ForegroundColor Gray
Write-Host ""

$deploySuccess = $false

if ($deployOutput -match '"success":\s*true') {
    Write-Host "  DEPLOYMENT: SUCCESS!" -ForegroundColor Green
    $deploySuccess = $true
    
    if ($deployOutput -match '"hash":\s*"(0x[a-f0-9]+)"') {
        $txHash = $matches[1]
        Write-Host "  Transaction hash: $txHash" -ForegroundColor Cyan
    }
} elseif ($deployOutput -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already published" -ForegroundColor Cyan
    $deploySuccess = $true
} elseif ($deployOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Insufficient balance" -ForegroundColor Red
    Write-Host "  Get more APT from devnet faucet" -ForegroundColor Yellow
} else {
    Write-Host "  Deployment status unclear" -ForegroundColor Yellow
}

# ============================================================
# STEP 9: INITIALIZE CONTRACT
# ============================================================
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[9/9] Initializing contract..." -ForegroundColor Green
    
    $initOutput = & $APTOS_CLI move run `
        --function-id "${WALLET_ADDRESS}::stake_match::initialize" `
        --args address:$WALLET_ADDRESS `
        --max-gas 20000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    Write-Host ""
    Write-Host "  Initialization output:" -ForegroundColor Gray
    Write-Host "  ========================================" -ForegroundColor Gray
    $initOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    Write-Host "  ========================================" -ForegroundColor Gray
    Write-Host ""
    
    if ($initOutput -match '"success":\s*true') {
        Write-Host "  INITIALIZATION: SUCCESS!" -ForegroundColor Green
    } elseif ($initOutput -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[9/9] Skipping initialization" -ForegroundColor Red
}

# Return to root
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# ============================================================
# FINAL SUMMARY
# ============================================================
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Network: DEVNET" -ForegroundColor Yellow
Write-Host "Account: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host "Module: ${WALLET_ADDRESS}::stake_match" -ForegroundColor Yellow
Write-Host ""

if ($deploySuccess) {
    Write-Host "STATUS: SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Devnet Explorer:" -ForegroundColor Yellow
    $explorerUrl = "https://explorer.aptoslabs.com/account/${WALLET_ADDRESS}?network=devnet"
    Write-Host $explorerUrl -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opening explorer..." -ForegroundColor Gray
    Start-Process $explorerUrl
    Write-Host ""
    Write-Host "Verify in explorer:" -ForegroundColor Yellow
    Write-Host "  - Modules tab: stake_match module" -ForegroundColor White
    Write-Host "  - Resources tab: StakeRegistry resource" -ForegroundColor White
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Verify deployment in explorer (just opened)" -ForegroundColor White
    Write-Host "  2. Create Supabase stakes table (SQL in CREATE_STAKES_TABLE.sql)" -ForegroundColor White
    Write-Host "  3. Run: npm run dev" -ForegroundColor White
    Write-Host "  4. Test staking!" -ForegroundColor White
    Write-Host ""
    Write-Host "YOUR DAPP IS NOW DEPLOYED ON DEVNET!" -ForegroundColor Green
} else {
    Write-Host "STATUS: FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Review errors above and try again" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
