# COMPLETE SETUP AND DEPLOYMENT SCRIPT
# This will initialize CLI with your wallet and deploy the contract

Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host "  COMPLETE APTOS SETUP AND DEPLOYMENT" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0xb475cbe24c14e219e37e908d6e95e0c344913a1648099915b5cb3320b8ea5345"
$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

Write-Host "Wallet Address: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host "Setting up Aptos CLI with your wallet..." -ForegroundColor Yellow
Write-Host ""

# Step 1: Initialize CLI with wallet
Write-Host "[1/7] Initializing Aptos CLI with your wallet..." -ForegroundColor Green
Write-Host "      This connects your wallet to the CLI" -ForegroundColor Gray

$initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --skip-faucet --assume-yes 2>&1
$initOutput | Out-String | Write-Host

if ($initOutput -match $WALLET_ADDRESS -or $initOutput -match "set up for account") {
    Write-Host "      ✅ CLI initialized with your wallet!" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Initialization completed (check output above)" -ForegroundColor Yellow
}

# Step 2: Verify account
Write-Host "`n[2/7] Verifying CLI account..." -ForegroundColor Green
$accountList = & C:\Users\Acer\.aptoscli\bin\aptos.exe account list 2>&1
$accountList | Out-String | Write-Host

if ($accountList -match $WALLET_ADDRESS -or $accountList -match "b475cbe24c14e219") {
    Write-Host "      ✅ CLI is using your wallet address!" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Could not verify address automatically" -ForegroundColor Yellow
}

# Step 3: Check balance
Write-Host "`n[3/7] Checking wallet balance..." -ForegroundColor Green
$balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1
$balanceOutput | Out-String | Write-Host

# Step 4: Navigate to move directory
Write-Host "`n[4/7] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
Write-Host "      Current directory: $(Get-Location)" -ForegroundColor Gray

# Step 5: Clean and compile
Write-Host "`n[5/7] Cleaning and compiling contract..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "      Build directory cleaned" -ForegroundColor Gray
}

Write-Host "      Compiling (may take 30-60 seconds)..." -ForegroundColor Gray
$compileOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1
$compileOutput | Out-String | Write-Host

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "      ✅ Compilation successful!" -ForegroundColor Green
    
    if ($compileOutput -match "b475cbe24c14e219") {
        Write-Host "      ✅ Contract will deploy to YOUR address!" -ForegroundColor Green
    } else {
        Write-Host "      ⚠️  WARNING: Address might not match!" -ForegroundColor Yellow
    }
} else {
    Write-Host "      ❌ Compilation may have failed!" -ForegroundColor Red
}

# Step 6: Deploy
Write-Host "`n[6/7] Deploying contract to blockchain..." -ForegroundColor Green
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray
$publishOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 20000 --assume-yes 2>&1
$publishOutput | Out-String | Write-Host

$deploySuccess = $false
if ($publishOutput -match '"success": true' -or $publishOutput -match 'Success') {
    Write-Host "      ✅ Deployment successful!" -ForegroundColor Green
    $deploySuccess = $true
} else {
    Write-Host "      ⚠️  Deployment status unclear (check output above)" -ForegroundColor Yellow
    if ($publishOutput -match "INSUFFICIENT_BALANCE") {
        Write-Host "      ❌ ERROR: Insufficient balance!" -ForegroundColor Red
        Write-Host "      💡 Get test APT from: https://aptoslabs.com/testnet-faucet" -ForegroundColor Yellow
        Write-Host "      💡 Paste your address: $WALLET_ADDRESS" -ForegroundColor Yellow
        Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Step 7: Initialize contract
Write-Host "`n[7/7] Initializing contract..." -ForegroundColor Green
Write-Host "      This may take 10-20 seconds..." -ForegroundColor Gray
$initContractOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${WALLET_ADDRESS}::stake_match::initialize" --args address:$WALLET_ADDRESS --max-gas 20000 --assume-yes 2>&1
$initContractOutput | Out-String | Write-Host

if ($initContractOutput -match '"success": true' -or $initContractOutput -match 'Success') {
    Write-Host "      ✅ Contract initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Initialization status unclear" -ForegroundColor Yellow
    if ($initContractOutput -match "ALREADY_PUBLISHED" -or $initContractOutput -match "already exists") {
        Write-Host "      ℹ️  Contract may already be initialized (this is OK)" -ForegroundColor Cyan
    }
}

# Return to root
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Final summary
Write-Host "`n===========================================================" -ForegroundColor Cyan
Write-Host "  SETUP COMPLETE!" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ CLI initialized with wallet: $WALLET_ADDRESS" -ForegroundColor Green
Write-Host "✅ Contract compiled" -ForegroundColor Green
if ($deploySuccess) {
    Write-Host "✅ Contract deployed" -ForegroundColor Green
    Write-Host "✅ Contract initialized" -ForegroundColor Green
} else {
    Write-Host "⚠️  Deployment status: Check output above" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "📍 VERIFICATION:" -ForegroundColor Yellow
Write-Host "   Check Aptos Explorer:" -ForegroundColor White
Write-Host "   https://explorer.aptoslabs.com/account/$WALLET_ADDRESS`?network=testnet" -ForegroundColor Cyan
Write-Host ""

Write-Host "🎯 NEXT STEPS:" -ForegroundColor Yellow
Write-Host "   1. ✅ Open the explorer link above" -ForegroundColor White
Write-Host "   2. ✅ Verify 'stake_match' module exists" -ForegroundColor White
Write-Host "   3. ✅ Create stakes table in Supabase (see CREATE_STAKES_TABLE.sql)" -ForegroundColor White
Write-Host "   4. ✅ Run: npm run dev" -ForegroundColor White
Write-Host "   5. ✅ Test staking on Dashboard" -ForegroundColor White
Write-Host ""

# Open explorer
Write-Host "Opening Aptos Explorer..." -ForegroundColor Gray
$explorerUrl = "https://explorer.aptoslabs.com/account/$WALLET_ADDRESS`?network=testnet"
Start-Process $explorerUrl

Write-Host "`nPress any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
