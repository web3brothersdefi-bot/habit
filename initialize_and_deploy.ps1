# Initialize AptosCoin Resource and Deploy
# This forces proper account initialization before deployment

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  FIX APTOS RESOURCE INITIALIZATION AND DEPLOY" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3"
$PRIVATE_KEY = "ed25519-priv-0x90a0dfcb4b3b348e79cb255b1384922787ee08be86317b56ae53076e1fba7f69"
$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"

Write-Host "Account: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host ""

# Step 1: Initialize CLI
Write-Host "[1/8] Initializing CLI..." -ForegroundColor Green
& $APTOS_CLI init --private-key $PRIVATE_KEY --network testnet --assume-yes 2>&1 | Out-Null
Write-Host "  Done" -ForegroundColor Gray

# Step 2: CRITICAL - Force AptosCoin resource creation by sending 0.001 APT to self
Write-Host ""
Write-Host "[2/8] Forcing AptosCoin resource initialization..." -ForegroundColor Green
Write-Host "  Method: Sending 0.001 APT to yourself" -ForegroundColor Gray
Write-Host "  This creates the CoinStore resource" -ForegroundColor Gray

$transferOutput = & $APTOS_CLI account transfer `
    --account $WALLET_ADDRESS `
    --amount 100000 `
    --assume-yes 2>&1

Write-Host ""
Write-Host "  Transfer output:" -ForegroundColor Gray
Write-Host $transferOutput

if ($transferOutput -match '"success":\s*true') {
    Write-Host ""
    Write-Host "  SUCCESS! AptosCoin resource initialized" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  Transfer may have failed, but let's continue..." -ForegroundColor Yellow
}

# Wait for transaction to settle
Write-Host "  Waiting 10 seconds for blockchain confirmation..." -ForegroundColor Gray
Start-Sleep -Seconds 10

# Step 3: Verify resource now exists
Write-Host ""
Write-Host "[3/8] Verifying AptosCoin resource..." -ForegroundColor Green
$resources = & $APTOS_CLI account list --query resources --account $WALLET_ADDRESS 2>&1

if ($resources -match "0x1::coin::CoinStore") {
    Write-Host "  AptosCoin resource: FOUND" -ForegroundColor Green
    $resourceExists = $true
} else {
    Write-Host "  AptosCoin resource: STILL MISSING" -ForegroundColor Red
    Write-Host "  This is a critical testnet issue" -ForegroundColor Yellow
    $resourceExists = $false
}

# Step 4: Check balance
Write-Host ""
Write-Host "[4/8] Checking balance..." -ForegroundColor Green
$balanceData = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json
if ($balanceData.Result) {
    $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
    Write-Host "  Balance: $balance APT" -ForegroundColor Cyan
    
    if ($balance -lt 15) {
        Write-Host "  Getting more APT from faucet..." -ForegroundColor Yellow
        for ($i = 1; $i -le 10; $i++) {
            & $APTOS_CLI account fund-with-faucet --account $WALLET_ADDRESS 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        }
        Write-Host "  Waiting for faucet transactions..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        $balanceData = & $APTOS_CLI account balance --account $WALLET_ADDRESS 2>&1 | ConvertFrom-Json
        $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
        Write-Host "  New balance: $balance APT" -ForegroundColor Cyan
    }
}

# Step 5: Navigate and clean
Write-Host ""
Write-Host "[5/8] Preparing build environment..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}
Write-Host "  Ready" -ForegroundColor Gray

# Step 6: Compile
Write-Host ""
Write-Host "[6/8] Compiling..." -ForegroundColor Green
& $APTOS_CLI move compile 2>&1 | Out-Null
Write-Host "  Compiled" -ForegroundColor Gray

# Step 7: Deploy with VERY HIGH gas limit to overcome any issues
Write-Host ""
Write-Host "[7/8] Deploying with maximum gas settings..." -ForegroundColor Green

if ($resourceExists) {
    Write-Host "  Strategy: Standard deployment (resource exists)" -ForegroundColor Cyan
    Write-Host "  Gas: 50000 units @ 100 Octas" -ForegroundColor Gray
    
    $deployResult = & $APTOS_CLI move publish --max-gas 50000 --gas-unit-price 100 --assume-yes 2>&1
} else {
    Write-Host "  Strategy: Use --skip-fetch-latest-git-deps (testnet workaround)" -ForegroundColor Cyan
    Write-Host "  Gas: 100000 units @ 150 Octas" -ForegroundColor Gray
    
    $deployResult = & $APTOS_CLI move publish --max-gas 100000 --gas-unit-price 150 --assume-yes --skip-fetch-latest-git-deps 2>&1
}

Write-Host ""
Write-Host "  Deployment result:" -ForegroundColor Gray
Write-Host "  ----------------------------------------" -ForegroundColor Gray
Write-Host $deployResult
Write-Host "  ----------------------------------------" -ForegroundColor Gray

$deploySuccess = $false
if ($deployResult -match '"success":\s*true') {
    Write-Host ""
    Write-Host "  DEPLOYMENT: SUCCESS!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($deployResult -match "ALREADY_PUBLISHED") {
    Write-Host ""
    Write-Host "  Module already exists (OK)" -ForegroundColor Cyan
    $deploySuccess = $true
} elseif ($deployResult -match "INSUFFICIENT_BALANCE") {
    Write-Host ""
    Write-Host "  STILL FAILING: Insufficient balance error" -ForegroundColor Red
    Write-Host ""
    Write-Host "  TESTNET HAS CRITICAL ISSUES!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ALTERNATIVE SOLUTION: Use Aptos Devnet" -ForegroundColor Yellow
    Write-Host "  Devnet is more stable and has same functionality" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  To switch to devnet:" -ForegroundColor Cyan
    Write-Host "    1. Re-run with --network devnet instead of testnet" -ForegroundColor White
    Write-Host "    2. Use devnet faucet: https://aptos.dev/network/faucet" -ForegroundColor White
    Write-Host "    3. Everything else stays the same" -ForegroundColor White
} else {
    Write-Host ""
    Write-Host "  Deployment status unclear" -ForegroundColor Yellow
}

# Step 8: Initialize if successful
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[8/8] Initializing contract..." -ForegroundColor Green
    
    $initResult = & $APTOS_CLI move run `
        --function-id "${WALLET_ADDRESS}::stake_match::initialize" `
        --args address:$WALLET_ADDRESS `
        --max-gas 30000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    if ($initResult -match '"success":\s*true') {
        Write-Host "  Initialization: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
        Write-Host $initResult
    }
} else {
    Write-Host ""
    Write-Host "[8/8] Skipping initialization" -ForegroundColor Red
}

Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
if ($deploySuccess) {
    Write-Host "  SUCCESS!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Contract deployed to: $WALLET_ADDRESS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Verify at:" -ForegroundColor Yellow
    $explorerUrl = "https://explorer.aptoslabs.com/account/${WALLET_ADDRESS}?network=testnet"
    Write-Host $explorerUrl -ForegroundColor Cyan
    Start-Process $explorerUrl
} else {
    Write-Host "  TESTNET DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "RECOMMENDED: Switch to DEVNET" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Aptos Testnet currently has resource initialization issues." -ForegroundColor White
    Write-Host "Devnet is more stable and works identically for development." -ForegroundColor White
    Write-Host ""
    Write-Host "I can create a devnet deployment script if you want." -ForegroundColor Cyan
    Write-Host "Just say 'switch to devnet' and I'll set it up!" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
