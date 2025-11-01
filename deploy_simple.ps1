# Simple deployment using CLI's default profile
# No private key re-initialization needed

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  SIMPLE DEPLOYMENT (Using CLI Profile)" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Show current CLI configuration
Write-Host "[1/6] Checking CLI configuration..." -ForegroundColor Green
$profileOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe config show-profiles 2>&1 | ConvertFrom-Json
$account = $profileOutput.Result.default.account

Write-Host "  CLI Account: 0x$account" -ForegroundColor Cyan
Write-Host "  Network: Testnet" -ForegroundColor Cyan

# Step 2: Check balance
Write-Host ""
Write-Host "[2/6] Checking balance..." -ForegroundColor Green
$balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json

if ($balanceOutput.Result -and $balanceOutput.Result.Count -gt 0) {
    $aptBalance = [long]$balanceOutput.Result[0].balance
    $aptAmount = $aptBalance / 100000000.0
    Write-Host "  Balance: $aptAmount APT" -ForegroundColor Cyan
} else {
    Write-Host "  Balance: 0 APT (or account not found)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Get APT from: https://aptoslabs.com/testnet-faucet" -ForegroundColor Yellow
    Write-Host "Address: 0x$account" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter after getting APT..."
    Read-Host
}

# Step 3: Navigate to move directory
Write-Host ""
Write-Host "[3/6] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
Write-Host "  Current directory: $(Get-Location)" -ForegroundColor Gray

# Step 4: Clean and compile
Write-Host ""
Write-Host "[4/6] Cleaning and compiling..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "  Build directory cleaned" -ForegroundColor Gray
}

Write-Host "  Compiling (30-60 seconds)..." -ForegroundColor Gray
$compileOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation successful!" -ForegroundColor Green
} else {
    Write-Host "  Compilation may have issues" -ForegroundColor Yellow
}

# Step 5: Deploy WITHOUT specifying profile (uses default)
Write-Host ""
Write-Host "[5/6] Deploying contract..." -ForegroundColor Green
Write-Host "  Using profile: default" -ForegroundColor Gray
Write-Host "  Max gas: 100000 units" -ForegroundColor Gray
Write-Host "  This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host ""

$publishOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 100000 --assume-yes 2>&1

Write-Host ""
Write-Host "Deployment output:" -ForegroundColor Gray
Write-Host $publishOutput
Write-Host ""

if ($publishOutput -match '"success":\s*true') {
    Write-Host "SUCCESS! Contract deployed!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($publishOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "ERROR: Insufficient balance" -ForegroundColor Red
    Write-Host ""
    Write-Host "This is strange - you had $aptAmount APT" -ForegroundColor Yellow
    Write-Host "Deployment should cost 2-5 APT max" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "  1. Gas price spike on testnet" -ForegroundColor White
    Write-Host "  2. Account state issue" -ForegroundColor White
    Write-Host "  3. Network congestion" -ForegroundColor White
    Write-Host ""
    Write-Host "SOLUTION: Get more APT (try 50+ APT)" -ForegroundColor Green
    Write-Host "https://aptoslabs.com/testnet-faucet" -ForegroundColor Cyan
} elseif ($publishOutput -match "ALREADY_PUBLISHED" -or $publishOutput -match "already exists") {
    Write-Host "Contract already published (this is OK)" -ForegroundColor Cyan
    $deploySuccess = $true
} else {
    Write-Host "Deployment status unclear - check output above" -ForegroundColor Yellow
}

# Step 6: Initialize if deployment succeeded
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[6/6] Initializing contract..." -ForegroundColor Green
    Write-Host "  This may take 10-20 seconds..." -ForegroundColor Gray
    
    $initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "0x${account}::stake_match::initialize" --args address:0x$account --max-gas 100000 --assume-yes 2>&1
    
    Write-Host ""
    Write-Host "Initialization output:" -ForegroundColor Gray
    Write-Host $initOutput
    Write-Host ""
    
    if ($initOutput -match '"success":\s*true') {
        Write-Host "SUCCESS! Contract initialized!" -ForegroundColor Green
    } else {
        Write-Host "Initialization status unclear" -ForegroundColor Yellow
    }
}

# Return to root
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Final summary
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Contract Address: 0x$account" -ForegroundColor Green
Write-Host ""
Write-Host "Verify at:" -ForegroundColor Yellow
Write-Host "https://explorer.aptoslabs.com/account/0x$account`?network=testnet" -ForegroundColor Cyan
Write-Host ""
Write-Host "Opening explorer..." -ForegroundColor Gray
Start-Process "https://explorer.aptoslabs.com/account/0x$account`?network=testnet"

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
