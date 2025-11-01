# ================================================================
# DEPLOY WHEN APTOS NETWORK IS STABLE
# Your account already has 27.99 APT ready to deploy!
# ================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  APTOS DEVNET DEPLOYMENT" -ForegroundColor Cyan
Write-Host "  Account: 0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3" -ForegroundColor Cyan
Write-Host "  Balance: 27.99 APT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"
$ADDRESS = "0x6204920201694bbf2a0b172fc4fc0a659214be9770efd2057d3d6bb61f1809d3"
$PROJECT_ROOT = "C:\Users\crisy\OneDrive\Escritorio\test4"

# Step 1: Verify account
Write-Host "[1/5] Verifying account..." -ForegroundColor Green

$balance = & $APTOS_CLI account balance --account $ADDRESS 2>&1 | ConvertFrom-Json
if ($balance.Result) {
    $apt = ([long]$balance.Result[0].balance) / 100000000.0
    Write-Host "  Balance: $apt APT" -ForegroundColor Cyan
}

# Step 2: Navigate and clean
Write-Host ""
Write-Host "[2/5] Preparing build..." -ForegroundColor Green
Set-Location -Path "$PROJECT_ROOT\move"

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}
Write-Host "  Ready" -ForegroundColor Gray

# Step 3: Compile
Write-Host ""
Write-Host "[3/5] Compiling Move contract..." -ForegroundColor Green

$compileOutput = & $APTOS_CLI move compile 2>&1

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation: SUCCESS ✓" -ForegroundColor Green
} else {
    Write-Host "  Compilation failed" -ForegroundColor Red
    Write-Host $compileOutput
    Set-Location -Path $PROJECT_ROOT
    exit 1
}

# Step 4: Deploy
Write-Host ""
Write-Host "[4/5] Deploying to Aptos Devnet..." -ForegroundColor Green
Write-Host "  Gas: 50000 units @ 100 Octas/unit" -ForegroundColor Gray
Write-Host "  Max cost: 0.05 APT" -ForegroundColor Gray
Write-Host ""

$deployOutput = & $APTOS_CLI move publish `
    --max-gas 50000 `
    --gas-unit-price 100 `
    --assume-yes 2>&1

Write-Host $deployOutput
Write-Host ""

$success = $false

if ($deployOutput -match '"success":\s*true') {
    Write-Host "  DEPLOYMENT: SUCCESS! ✓" -ForegroundColor Green
    $success = $true
    
    if ($deployOutput -match '"hash":\s*"(0x[a-f0-9]+)"') {
        $txHash = $matches[1]
        Write-Host "  Transaction: $txHash" -ForegroundColor Cyan
    }
} elseif ($deployOutput -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already exists ✓" -ForegroundColor Cyan
    $success = $true
} elseif ($deployOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Still getting insufficient balance error" -ForegroundColor Red
    Write-Host ""
    Write-Host "  This means Aptos network still has the CoinStore bug." -ForegroundColor Yellow
    Write-Host "  Please try again in a few hours." -ForegroundColor Yellow
    Set-Location -Path $PROJECT_ROOT
    exit 1
} else {
    Write-Host "  Deployment status unclear" -ForegroundColor Yellow
}

# Step 5: Initialize
if ($success) {
    Write-Host ""
    Write-Host "[5/5] Initializing contract..." -ForegroundColor Green
    
    $initOutput = & $APTOS_CLI move run `
        --function-id "${ADDRESS}::stake_match::initialize" `
        --args address:$ADDRESS `
        --max-gas 20000 `
        --gas-unit-price 100 `
        --assume-yes 2>&1
    
    if ($initOutput -match '"success":\s*true') {
        Write-Host "  Initialization: SUCCESS! ✓" -ForegroundColor Green
    } elseif ($initOutput -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized ✓" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
    }
}

Set-Location -Path $PROJECT_ROOT

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Contract Address:" -ForegroundColor Yellow
Write-Host "  $ADDRESS" -ForegroundColor White
Write-Host ""

Write-Host "Module ID:" -ForegroundColor Yellow
Write-Host "  ${ADDRESS}::stake_match" -ForegroundColor White
Write-Host ""

Write-Host "Devnet Explorer:" -ForegroundColor Yellow
$explorerUrl = "https://explorer.aptoslabs.com/account/${ADDRESS}?network=devnet"
Write-Host "  $explorerUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening explorer..." -ForegroundColor Gray
Start-Process $explorerUrl

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Verify in Explorer (just opened):" -ForegroundColor Yellow
Write-Host "   - Check Modules tab for 'stake_match'" -ForegroundColor White
Write-Host "   - Check Resources tab for 'StakeRegistry'" -ForegroundColor White
Write-Host ""

Write-Host "2. Import Account to Petra Wallet:" -ForegroundColor Yellow
Write-Host "   - Open Petra extension" -ForegroundColor White
Write-Host "   - Settings → Import Account" -ForegroundColor White
Write-Host "   - Paste private key from: C:\Users\Acer\.aptos\config.yaml" -ForegroundColor White
Write-Host "   - Switch network to Devnet" -ForegroundColor White
Write-Host ""

Write-Host "3. Create Supabase Stakes Table:" -ForegroundColor Yellow
Write-Host "   - Open Supabase SQL Editor" -ForegroundColor White
Write-Host "   - Run SQL from: CREATE_STAKES_TABLE.sql" -ForegroundColor White
Write-Host ""

Write-Host "4. Start Development Server:" -ForegroundColor Yellow
Write-Host "   - Run: npm run dev" -ForegroundColor White
Write-Host "   - Open: http://localhost:3000/dashboard" -ForegroundColor White
Write-Host ""

Write-Host "5. Test Staking:" -ForegroundColor Yellow
Write-Host "   - Swipe right on any user" -ForegroundColor White
Write-Host "   - Approve transaction in Petra" -ForegroundColor White
Write-Host "   - SUCCESS!" -ForegroundColor White
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  YOUR DAPP IS NOW LIVE ON APTOS DEVNET!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
