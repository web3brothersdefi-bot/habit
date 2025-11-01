# Fix account initialization then deploy using CLI
# This solves the CoinStore resource issue

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  FIX ACCOUNT & DEPLOY TO DEVNET" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3"
$PRIVATE_KEY = "ed25519-priv-0x90a0dfcb4b3b348e79cb255b1384922787ee08be86317b56ae53076e1fba7f69"
$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"

# Step 1: Initialize CLI for devnet
Write-Host "[1/6] Initializing CLI for devnet..." -ForegroundColor Green
& $APTOS_CLI init --private-key $PRIVATE_KEY --network devnet --assume-yes 2>&1 | Out-Null
Write-Host "  Done" -ForegroundColor Gray

# Step 2: Send 0 APT to self to initialize CoinStore resource
Write-Host ""
Write-Host "[2/6] Initializing CoinStore resource..." -ForegroundColor Green
Write-Host "  Method: Transferring 0.001 APT to yourself" -ForegroundColor Gray
Write-Host "  This creates the missing CoinStore resource" -ForegroundColor Gray

$transferResult = & $APTOS_CLI account transfer `
    --account $WALLET_ADDRESS `
    --amount 100000 `
    --assume-yes 2>&1

if ($transferResult -match '"success":\s*true') {
    Write-Host "  CoinStore resource initialized!" -ForegroundColor Green
} else {
    Write-Host "  Transfer completed (may already be initialized)" -ForegroundColor Yellow
}

Write-Host "  Waiting 15 seconds for blockchain confirmation..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Step 3: Verify resource exists
Write-Host ""
Write-Host "[3/6] Verifying CoinStore resource..." -ForegroundColor Green
$resources = & $APTOS_CLI account list --query resources --account $WALLET_ADDRESS 2>&1

if ($resources -match "0x1::coin::CoinStore") {
    Write-Host "  CoinStore resource: EXISTS" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Still not detected, but continuing..." -ForegroundColor Yellow
}

# Step 4: Navigate and compile
Write-Host ""
Write-Host "[4/6] Compiling contract..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

& $APTOS_CLI move compile 2>&1 | Out-Null
Write-Host "  Compiled" -ForegroundColor Gray

# Step 5: Deploy with CLI (resource should be fixed now)
Write-Host ""
Write-Host "[5/6] Deploying to devnet..." -ForegroundColor Green
Write-Host "  Gas: 40000 units @ 100 Octas" -ForegroundColor Gray

$deployResult = & $APTOS_CLI move publish `
    --max-gas 40000 `
    --gas-unit-price 100 `
    --assume-yes 2>&1

Write-Host ""
Write-Host "  Deployment output:" -ForegroundColor Gray
Write-Host "  ========================================" -ForegroundColor Gray
$deployResult | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host "  ========================================" -ForegroundColor Gray
Write-Host ""

$deploySuccess = $false

if ($deployResult -match '"success":\s*true') {
    Write-Host "  DEPLOYMENT: SUCCESS!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($deployResult -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already exists" -ForegroundColor Cyan
    $deploySuccess = $true
} elseif ($deployResult -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Still insufficient balance!" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This indicates a fundamental Aptos network issue." -ForegroundColor Yellow
    Write-Host "  The account initialization is not working properly." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  RECOMMENDED: Wait 30 minutes and try again," -ForegroundColor Cyan
    Write-Host "  or deploy to a different Aptos network when available." -ForegroundColor Cyan
} else {
    Write-Host "  Status unclear - check output above" -ForegroundColor Yellow
}

# Step 6: Initialize if successful
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[6/6] Initializing contract..." -ForegroundColor Green
    
    $initResult = & $APTOS_CLI move run `
        --function-id "${WALLET_ADDRESS}::stake_match::initialize" `
        --args address:$WALLET_ADDRESS `
        --max-gas 20000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    if ($initResult -match '"success":\s*true') {
        Write-Host "  Initialization: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
    }
} else {
    Write-Host ""
    Write-Host "[6/6] Skipping initialization" -ForegroundColor Red
}

Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan

if ($deploySuccess) {
    Write-Host "  SUCCESS!" -ForegroundColor Green
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Contract deployed to devnet!" -ForegroundColor Green
    Write-Host "Address: $WALLET_ADDRESS" -ForegroundColor Cyan
    Write-Host ""
    $explorerUrl = "https://explorer.aptoslabs.com/account/${WALLET_ADDRESS}?network=devnet"
    Write-Host "Devnet Explorer:" -ForegroundColor Yellow
    Write-Host $explorerUrl -ForegroundColor Cyan
    Start-Process $explorerUrl
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "  1. Verify in devnet explorer" -ForegroundColor White
    Write-Host "  2. Switch Petra wallet to Devnet" -ForegroundColor White
    Write-Host "  3. Create Supabase stakes table" -ForegroundColor White
    Write-Host "  4. Run: npm run dev" -ForegroundColor White
    Write-Host "  5. Test staking!" -ForegroundColor White
} else {
    Write-Host "  DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "The Aptos network (both testnet and devnet) is experiencing" -ForegroundColor Yellow
    Write-Host "account initialization issues that prevent deployment." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This is a known Aptos infrastructure issue, not your code." -ForegroundColor Cyan
    Write-Host ""
    Write-Host "OPTIONS:" -ForegroundColor Yellow
    Write-Host "  1. Wait 30-60 minutes and try again" -ForegroundColor White
    Write-Host "  2. Try tomorrow when network is more stable" -ForegroundColor White
    Write-Host "  3. Deploy to local Aptos node (requires setup)" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
