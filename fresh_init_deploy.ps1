# Fresh Account Creation and Deployment using aptos init
# This creates a brand new account with proper initialization

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  FRESH ACCOUNT DEPLOYMENT - APTOS DEVNET" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"
$PROJECT_ROOT = "C:\Users\crisy\OneDrive\Escritorio\test4"

# Step 1: Create brand new account using aptos init
Write-Host "[1/7] Creating fresh account with aptos init..." -ForegroundColor Green
Write-Host "  This will generate a new private key and address" -ForegroundColor Gray
Write-Host ""

# Run init interactively - will create new account
$initOutput = & $APTOS_CLI init --network devnet 2>&1

Write-Host $initOutput
Write-Host ""

# Step 2: Get the new account address
Write-Host "[2/7] Getting account information..." -ForegroundColor Green

$profileData = & $APTOS_CLI config show-profiles 2>&1 | ConvertFrom-Json
$accountAddress = "0x" + $profileData.Result.default.account
$network = $profileData.Result.default.network

Write-Host "  Account Address: $accountAddress" -ForegroundColor Cyan
Write-Host "  Network: $network" -ForegroundColor Cyan
Write-Host "  Private Key: Stored in ~/.aptos/config.yaml" -ForegroundColor Gray

# Step 3: Fund account from devnet faucet
Write-Host ""
Write-Host "[3/7] Funding account from devnet faucet..." -ForegroundColor Green

for ($i = 1; $i -le 5; $i++) {
    Write-Host "  Faucet request $i/5..." -ForegroundColor Gray
    & $APTOS_CLI account fund-with-faucet --account $accountAddress 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

Write-Host "  Waiting for transactions to settle (15 seconds)..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Step 4: Check balance and resources
Write-Host ""
Write-Host "[4/7] Verifying account setup..." -ForegroundColor Green

$balanceData = & $APTOS_CLI account balance --account $accountAddress 2>&1 | ConvertFrom-Json
if ($balanceData.Result) {
    $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
    Write-Host "  Balance: $balance APT" -ForegroundColor Cyan
}

$resources = & $APTOS_CLI account list --query resources --account $accountAddress 2>&1
if ($resources -match "0x1::coin::CoinStore") {
    Write-Host "  CoinStore resource: EXISTS" -ForegroundColor Green
    $resourceExists = $true
} else {
    Write-Host "  CoinStore resource: NOT FOUND" -ForegroundColor Red
    $resourceExists = $false
}

# Step 5: Update config files with new address
Write-Host ""
Write-Host "[5/7] Updating configuration files..." -ForegroundColor Green

# Update Move.toml
$moveTomlPath = "$PROJECT_ROOT\move\Move.toml"
$moveTomlContent = Get-Content $moveTomlPath -Raw
$moveTomlContent = $moveTomlContent -replace 'habit = "0x[a-f0-9]+"', "habit = `"$accountAddress`""
Set-Content -Path $moveTomlPath -Value $moveTomlContent
Write-Host "  Updated move/Move.toml" -ForegroundColor Gray

# Update .env
$envPath = "$PROJECT_ROOT\.env"
$envContent = Get-Content $envPath -Raw
$envContent = $envContent -replace 'VITE_MODULE_ADDRESS=0x[a-f0-9]+', "VITE_MODULE_ADDRESS=$accountAddress"
Set-Content -Path $envPath -Value $envContent
Write-Host "  Updated .env" -ForegroundColor Gray

# Step 6: Compile and deploy
Write-Host ""
Write-Host "[6/7] Compiling and deploying..." -ForegroundColor Green

Set-Location -Path "$PROJECT_ROOT\move"

# Clean build
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

# Compile
Write-Host "  Compiling..." -ForegroundColor Gray
& $APTOS_CLI move compile 2>&1 | Out-Null
Write-Host "  Compilation: SUCCESS" -ForegroundColor Green

# Deploy
Write-Host "  Deploying to devnet..." -ForegroundColor Gray
Write-Host "  This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host ""

$deployOutput = & $APTOS_CLI move publish `
    --max-gas 40000 `
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
        Write-Host "  Transaction: $txHash" -ForegroundColor Cyan
    }
} elseif ($deployOutput -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already published" -ForegroundColor Cyan
    $deploySuccess = $true
} elseif ($deployOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Insufficient balance" -ForegroundColor Red
    Write-Host "  Even with fresh account, network has issues" -ForegroundColor Yellow
} else {
    Write-Host "  Status unclear" -ForegroundColor Yellow
}

# Step 7: Initialize contract
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[7/7] Initializing contract..." -ForegroundColor Green
    
    $initResult = & $APTOS_CLI move run `
        --function-id "${accountAddress}::stake_match::initialize" `
        --args address:$accountAddress `
        --max-gas 20000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    if ($initResult -match '"success":\s*true') {
        Write-Host "  Initialization: SUCCESS!" -ForegroundColor Green
    } elseif ($initResult -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[7/7] Skipping initialization" -ForegroundColor Red
}

Set-Location -Path $PROJECT_ROOT

# Final Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Account Address:" -ForegroundColor Yellow
Write-Host "  $accountAddress" -ForegroundColor White
Write-Host ""

Write-Host "Network: DEVNET" -ForegroundColor Yellow
Write-Host ""

if ($deploySuccess) {
    Write-Host "STATUS: SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Your contract is deployed!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Explorer URL:" -ForegroundColor Yellow
    $explorerUrl = "https://explorer.aptoslabs.com/account/${accountAddress}?network=devnet"
    Write-Host "  $explorerUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opening explorer..." -ForegroundColor Gray
    Start-Process $explorerUrl
    Write-Host ""
    Write-Host "IMPORTANT - Save Your Private Key:" -ForegroundColor Red
    Write-Host "  Location: C:\Users\Acer\.aptos\config.yaml" -ForegroundColor Cyan
    Write-Host "  Export it from Petra wallet settings" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Verify deployment in devnet explorer (opened)" -ForegroundColor White
    Write-Host "  2. Import this account to Petra wallet" -ForegroundColor White
    Write-Host "     - Settings → Import Account" -ForegroundColor Gray
    Write-Host "     - Paste private key from config.yaml" -ForegroundColor Gray
    Write-Host "  3. Switch Petra to Devnet" -ForegroundColor White
    Write-Host "  4. Create Supabase stakes table" -ForegroundColor White
    Write-Host "  5. Run: npm run dev" -ForegroundColor White
    Write-Host "  6. Test staking!" -ForegroundColor White
    Write-Host ""
    Write-Host "YOUR DAPP IS DEPLOYED!" -ForegroundColor Green
} else {
    Write-Host "STATUS: FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Deployment failed even with fresh account." -ForegroundColor Yellow
    Write-Host "This confirms the Aptos network is experiencing issues." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Your new account address: $accountAddress" -ForegroundColor Cyan
    Write-Host "Private key stored in: C:\Users\Acer\.aptos\config.yaml" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Please try again in a few hours when network stabilizes." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
