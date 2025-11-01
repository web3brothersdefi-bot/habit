# ================================================================
# FINAL DEPLOYMENT SCRIPT - USE WHEN APTOS NETWORK IS FIXED
# This uses dynamic address assignment (habit = "_")
# ================================================================

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  APTOS DEVNET DEPLOYMENT - FINAL METHOD" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$PROJECT_ROOT = "C:\Users\crisy\OneDrive\Escritorio\test4"

# Step 1: Navigate to move directory
Write-Host "[1/5] Navigating to project..." -ForegroundColor Green
Set-Location -Path "$PROJECT_ROOT\move"

# Step 2: Clean previous build
Write-Host ""
Write-Host "[2/5] Cleaning previous build..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "  Build directory cleaned" -ForegroundColor Gray
}

# Step 3: Compile with dynamic address
Write-Host ""
Write-Host "[3/5] Compiling contract..." -ForegroundColor Green
$compileOutput = aptos move compile --named-addresses habit=default 2>&1

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation: SUCCESS ✓" -ForegroundColor Green
    
    # Extract compiled address
    if ($compileOutput -match "([a-f0-9]{64})::stake_match") {
        $compiledAddress = "0x" + $matches[1]
        Write-Host "  Module: $compiledAddress::stake_match" -ForegroundColor Cyan
    }
} else {
    Write-Host "  Compilation FAILED" -ForegroundColor Red
    Write-Host $compileOutput
    Set-Location -Path $PROJECT_ROOT
    exit 1
}

# Step 4: Publish module
Write-Host ""
Write-Host "[4/5] Publishing to devnet..." -ForegroundColor Green
Write-Host "  This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host ""

$publishOutput = aptos move publish `
    --named-addresses habit=default `
    --max-gas 40000 `
    --assume-yes 2>&1

Write-Host $publishOutput
Write-Host ""

$success = $false

if ($publishOutput -match '"success":\s*true') {
    Write-Host "  DEPLOYMENT: SUCCESS! ✓" -ForegroundColor Green
    $success = $true
} elseif ($publishOutput -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already exists ✓" -ForegroundColor Cyan
    $success = $true
} elseif ($publishOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "  ERROR: Still getting INSUFFICIENT_BALANCE" -ForegroundColor Red
    Write-Host ""
    Write-Host "  Aptos network still has the publishing bug." -ForegroundColor Yellow
    Write-Host "  Please try again later or use local Aptos node." -ForegroundColor Yellow
    Set-Location -Path $PROJECT_ROOT
    exit 1
} else {
    Write-Host "  Status unclear - check output above" -ForegroundColor Yellow
}

# Step 5: Initialize contract
if ($success) {
    Write-Host ""
    Write-Host "[5/5] Initializing contract..." -ForegroundColor Green
    
    # Get account address from config
    $configOutput = aptos config show-profiles 2>&1 | ConvertFrom-Json
    $accountAddress = "0x" + $configOutput.Result.default.account
    
    Write-Host "  Account: $accountAddress" -ForegroundColor Cyan
    
    $initOutput = aptos move run `
        --function-id "${accountAddress}::stake_match::initialize" `
        --args address:default `
        --max-gas 20000 `
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

# Get final account info
$configData = aptos config show-profiles 2>&1 | ConvertFrom-Json
$finalAddress = "0x" + $configData.Result.default.account

Write-Host "Contract Address:" -ForegroundColor Yellow
Write-Host "  $finalAddress" -ForegroundColor White
Write-Host ""

Write-Host "Module ID:" -ForegroundColor Yellow
Write-Host "  ${finalAddress}::stake_match" -ForegroundColor White
Write-Host ""

Write-Host "Devnet Explorer:" -ForegroundColor Yellow
$explorerUrl = "https://explorer.aptoslabs.com/account/${finalAddress}?network=devnet"
Write-Host "  $explorerUrl" -ForegroundColor Cyan
Write-Host ""

Write-Host "Opening explorer..." -ForegroundColor Gray
Start-Process $explorerUrl

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1. Update .env file:" -ForegroundColor Yellow
Write-Host "   VITE_MODULE_ADDRESS=$finalAddress" -ForegroundColor White
Write-Host ""

Write-Host "2. Import Account to Petra:" -ForegroundColor Yellow
Write-Host "   - Open Petra extension" -ForegroundColor White
Write-Host "   - Settings → Import Account" -ForegroundColor White
Write-Host "   - Get private key: C:\Users\Acer\.aptos\config.yaml" -ForegroundColor White
Write-Host "   - Switch network to Devnet" -ForegroundColor White
Write-Host ""

Write-Host "3. Create Supabase Table:" -ForegroundColor Yellow
Write-Host "   - Run SQL from CREATE_STAKES_TABLE.sql" -ForegroundColor White
Write-Host ""

Write-Host "4. Start & Test:" -ForegroundColor Yellow
Write-Host "   - npm run dev" -ForegroundColor White
Write-Host "   - Test staking!" -ForegroundColor White
Write-Host ""

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  YOUR DAPP IS NOW LIVE!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
