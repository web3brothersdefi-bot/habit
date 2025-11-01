# FIXED DEPLOYMENT SCRIPT - Proper balance checking and deployment

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  APTOS CONTRACT DEPLOYMENT - FIXED VERSION" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0xb475cbe24c14e219e37e908d6e95e0c344913a1648099915b5cb3320b8ea5345"
$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

Write-Host "Wallet Address: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host ""

# Step 1: Initialize CLI
Write-Host "[1/8] Initializing Aptos CLI..." -ForegroundColor Green
$initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --skip-faucet --assume-yes 2>&1
if ($initOutput -match "Success") {
    Write-Host "      CLI initialized successfully!" -ForegroundColor Green
} else {
    Write-Host "      CLI initialization completed" -ForegroundColor Yellow
}

# Step 2: Check balance properly
Write-Host ""
Write-Host "[2/8] Checking wallet balance..." -ForegroundColor Green
$balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json

if ($balanceOutput.Result -and $balanceOutput.Result.Count -gt 0) {
    $aptBalance = [long]$balanceOutput.Result[0].balance
    $aptAmount = $aptBalance / 100000000.0
    Write-Host "      Current balance: $aptAmount APT ($aptBalance Octas)" -ForegroundColor Cyan
    
    if ($aptBalance -lt 1000000000) {
        Write-Host ""
        Write-Host "WARNING: You need at least 10 APT for deployment!" -ForegroundColor Red
        Write-Host "Current balance: $aptAmount APT" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "ACTION REQUIRED:" -ForegroundColor Yellow
        Write-Host "1. Open: https://aptoslabs.com/testnet-faucet" -ForegroundColor White
        Write-Host "2. Paste: $WALLET_ADDRESS" -ForegroundColor White
        Write-Host "3. Click 'Faucet' button 10 times (1 APT each time)" -ForegroundColor White
        Write-Host "4. Wait 10 seconds between each click" -ForegroundColor White
        Write-Host "5. Press Enter here when done" -ForegroundColor White
        Write-Host ""
        Read-Host "Press Enter after getting more APT"
        
        # Re-check balance
        Write-Host ""
        Write-Host "Re-checking balance..." -ForegroundColor Green
        $balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json
        $aptBalance = [long]$balanceOutput.Result[0].balance
        $aptAmount = $aptBalance / 100000000.0
        Write-Host "      New balance: $aptAmount APT" -ForegroundColor Cyan
        
        if ($aptBalance -lt 1000000000) {
            Write-Host ""
            Write-Host "ERROR: Still insufficient balance. Need at least 10 APT." -ForegroundColor Red
            Write-Host "Press any key to exit..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    }
} else {
    Write-Host "      WARNING: Could not read balance" -ForegroundColor Yellow
}

# Step 3: Navigate to move directory
Write-Host ""
Write-Host "[3/8] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
Write-Host "      Current directory: $(Get-Location)" -ForegroundColor Gray

# Step 4: Clean build
Write-Host ""
Write-Host "[4/8] Cleaning previous build..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "      Build directory cleaned" -ForegroundColor Gray
}

# Step 5: Compile
Write-Host ""
Write-Host "[5/8] Compiling contract..." -ForegroundColor Green
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray
$compileOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1

if ($compileOutput -match "b475cbe24c14e219") {
    Write-Host "      Compilation successful!" -ForegroundColor Green
    Write-Host "      Contract will deploy to: $WALLET_ADDRESS" -ForegroundColor Cyan
} else {
    Write-Host "      WARNING: Compilation may have issues" -ForegroundColor Yellow
    Write-Host $compileOutput
}

# Step 6: Deploy with higher gas limit
Write-Host ""
Write-Host "[6/8] Deploying contract with high gas limit..." -ForegroundColor Green
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray
Write-Host "      Using gas: 50000 units" -ForegroundColor Gray

$publishOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 50000 --gas-unit-price 150 --assume-yes 2>&1

if ($publishOutput -match '"success": true') {
    Write-Host ""
    Write-Host "      SUCCESS! Contract deployed!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($publishOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host ""
    Write-Host "ERROR: Still insufficient balance!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Your balance should be at least 15 APT for safe deployment." -ForegroundColor Yellow
    Write-Host "Get more APT from: https://aptoslabs.com/testnet-faucet" -ForegroundColor Yellow
    Write-Host "Click Faucet button multiple times (wait 10s between clicks)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host $publishOutput
    Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
} elseif ($publishOutput -match "ALREADY_EXISTS" -or $publishOutput -match "already published") {
    Write-Host ""
    Write-Host "      Contract already deployed (this is OK)" -ForegroundColor Cyan
    $deploySuccess = $true
} else {
    Write-Host ""
    Write-Host "      Deployment status unclear" -ForegroundColor Yellow
    Write-Host $publishOutput
}

# Step 7: Initialize contract
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[7/8] Initializing contract..." -ForegroundColor Green
    Write-Host "      This may take 10-20 seconds..." -ForegroundColor Gray
    
    $initContractOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${WALLET_ADDRESS}::stake_match::initialize" --args address:$WALLET_ADDRESS --max-gas 50000 --gas-unit-price 150 --assume-yes 2>&1
    
    if ($initContractOutput -match '"success": true') {
        Write-Host "      Contract initialized successfully!" -ForegroundColor Green
    } elseif ($initContractOutput -match "ALREADY_EXISTS") {
        Write-Host "      Contract already initialized (this is OK)" -ForegroundColor Cyan
    } else {
        Write-Host "      Initialization status unclear" -ForegroundColor Yellow
        Write-Host $initContractOutput
    }
}

# Step 8: Final balance check
Write-Host ""
Write-Host "[8/8] Checking final balance..." -ForegroundColor Green
$finalBalanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json
if ($finalBalanceOutput.Result) {
    $finalBalance = [long]$finalBalanceOutput.Result[0].balance
    $finalApt = $finalBalance / 100000000.0
    Write-Host "      Final balance: $finalApt APT" -ForegroundColor Cyan
}

# Return to root
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Final summary
Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Contract Address: $WALLET_ADDRESS" -ForegroundColor Green
Write-Host ""
Write-Host "VERIFICATION:" -ForegroundColor Yellow
Write-Host "Open this link to verify deployment:" -ForegroundColor White
Write-Host "https://explorer.aptoslabs.com/account/$WALLET_ADDRESS`?network=testnet" -ForegroundColor Cyan
Write-Host ""
Write-Host "Look for:" -ForegroundColor White
Write-Host "  - Modules tab: stake_match module" -ForegroundColor White
Write-Host "  - Resources tab: StakeRegistry resource" -ForegroundColor White
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Verify on explorer (link above)" -ForegroundColor White
Write-Host "2. Create stakes table in Supabase" -ForegroundColor White
Write-Host "   - Open Supabase SQL Editor" -ForegroundColor White
Write-Host "   - Run SQL from: CREATE_STAKES_TABLE.sql" -ForegroundColor White
Write-Host "3. Start dev server: npm run dev" -ForegroundColor White
Write-Host "4. Test staking on Dashboard" -ForegroundColor White
Write-Host ""

# Open explorer
Write-Host "Opening Aptos Explorer..." -ForegroundColor Gray
$explorerUrl = "https://explorer.aptoslabs.com/account/$WALLET_ADDRESS`?network=testnet"
Start-Process $explorerUrl

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
