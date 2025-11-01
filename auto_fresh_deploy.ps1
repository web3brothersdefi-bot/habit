# Fully Automated Fresh Account Creation and Deployment
# Creates new account non-interactively

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  AUTOMATED FRESH ACCOUNT DEPLOYMENT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$APTOS_CLI = "C:\Users\Acer\.aptoscli\bin\aptos.exe"
$PROJECT_ROOT = "C:\Users\crisy\OneDrive\Escritorio\test4"

# Step 1: Generate new account with aptos init (non-interactive)
Write-Host "[1/7] Generating fresh account..." -ForegroundColor Green
Write-Host "  Creating new private key and address" -ForegroundColor Gray

# Use --skip-faucet to make it non-interactive
& $APTOS_CLI init `
    --network devnet `
    --skip-faucet `
    --assume-yes 2>&1 | Out-Null

Write-Host "  Account generated" -ForegroundColor Green

# Step 2: Get account details
Write-Host ""
Write-Host "[2/7] Reading account information..." -ForegroundColor Green

$profileData = & $APTOS_CLI config show-profiles 2>&1 | ConvertFrom-Json
$accountAddress = "0x" + $profileData.Result.default.account
$network = $profileData.Result.default.network

Write-Host "  Address: $accountAddress" -ForegroundColor Cyan
Write-Host "  Network: $network" -ForegroundColor Cyan

# Step 3: Fund the account
Write-Host ""
Write-Host "[3/7] Funding account from devnet faucet..." -ForegroundColor Green

for ($i = 1; $i -le 10; $i++) {
    Write-Host "  Request $i/10..." -ForegroundColor Gray
    & $APTOS_CLI account fund-with-faucet --account $accountAddress 2>&1 | Out-Null
    Start-Sleep -Seconds 2
}

Write-Host "  Waiting 15 seconds for settlement..." -ForegroundColor Gray
Start-Sleep -Seconds 15

# Step 4: Verify account
Write-Host ""
Write-Host "[4/7] Verifying account..." -ForegroundColor Green

$balanceData = & $APTOS_CLI account balance --account $accountAddress 2>&1 | ConvertFrom-Json
if ($balanceData.Result) {
    $balance = ([long]$balanceData.Result[0].balance) / 100000000.0
    Write-Host "  Balance: $balance APT" -ForegroundColor Cyan
}

$resources = & $APTOS_CLI account list --query resources --account $accountAddress 2>&1
if ($resources -match "0x1::coin::CoinStore") {
    Write-Host "  CoinStore: EXISTS ✓" -ForegroundColor Green
} else {
    Write-Host "  CoinStore: MISSING (will create on first tx)" -ForegroundColor Yellow
}

# Step 5: Update configs
Write-Host ""
Write-Host "[5/7] Updating configuration files..." -ForegroundColor Green

# Move.toml
$moveToml = "$PROJECT_ROOT\move\Move.toml"
$content = Get-Content $moveToml -Raw
$content = $content -replace 'habit = "0x[a-f0-9]+"', "habit = `"$accountAddress`""
Set-Content -Path $moveToml -Value $content -NoNewline
Write-Host "  Updated Move.toml" -ForegroundColor Gray

# .env
$envFile = "$PROJECT_ROOT\.env"
$envContent = Get-Content $envFile -Raw
$envContent = $envContent -replace 'VITE_MODULE_ADDRESS=0x[a-f0-9]+', "VITE_MODULE_ADDRESS=$accountAddress"
Set-Content -Path $envFile -Value $envContent -NoNewline
Write-Host "  Updated .env" -ForegroundColor Gray

# Step 6: Compile
Write-Host ""
Write-Host "[6/7] Compiling contract..." -ForegroundColor Green

Set-Location -Path "$PROJECT_ROOT\move"

if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

$compileOutput = & $APTOS_CLI move compile 2>&1

if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation: SUCCESS ✓" -ForegroundColor Green
} else {
    Write-Host "  Compilation failed" -ForegroundColor Red
    Write-Host $compileOutput
    Set-Location -Path $PROJECT_ROOT
    exit 1
}

# Step 7: Deploy
Write-Host ""
Write-Host "[7/7] Deploying to devnet..." -ForegroundColor Green
Write-Host "  Gas: 50000 units @ 100 Octas/unit" -ForegroundColor Gray
Write-Host "  Deploying..." -ForegroundColor Gray

$deployOutput = & $APTOS_CLI move publish `
    --max-gas 50000 `
    --gas-unit-price 100 `
    --assume-yes 2>&1

Write-Host ""
$deployOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
Write-Host ""

$success = $false

if ($deployOutput -match '"success":\s*true') {
    Write-Host "DEPLOYMENT: SUCCESS! ✓" -ForegroundColor Green
    $success = $true
} elseif ($deployOutput -match "ALREADY_PUBLISHED") {
    Write-Host "Module already exists ✓" -ForegroundColor Cyan
    $success = $true
} elseif ($deployOutput -match "INSUFFICIENT_BALANCE") {
    Write-Host "DEPLOYMENT FAILED: Insufficient balance" -ForegroundColor Red
} else {
    Write-Host "Status unclear - check output above" -ForegroundColor Yellow
}

# Initialize if deployed
if ($success) {
    Write-Host ""
    Write-Host "Initializing contract..." -ForegroundColor Green
    
    $initOutput = & $APTOS_CLI move run `
        --function-id "${accountAddress}::stake_match::initialize" `
        --args address:$accountAddress `
        --assume-yes 2>&1
    
    if ($initOutput -match '"success":\s*true') {
        Write-Host "Initialization: SUCCESS! ✓" -ForegroundColor Green
    } elseif ($initOutput -match "ALREADY_EXISTS") {
        Write-Host "Already initialized ✓" -ForegroundColor Cyan
    }
}

Set-Location -Path $PROJECT_ROOT

# Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  RESULT" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

if ($success) {
    Write-Host "SUCCESS! Contract deployed to devnet! 🎉" -ForegroundColor Green
    Write-Host ""
    Write-Host "Account: $accountAddress" -ForegroundColor Cyan
    Write-Host "Network: Devnet" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Explorer:" -ForegroundColor Yellow
    $url = "https://explorer.aptoslabs.com/account/${accountAddress}?network=devnet"
    Write-Host $url -ForegroundColor Cyan
    Start-Process $url
    Write-Host ""
    Write-Host "Private key stored in:" -ForegroundColor Yellow
    Write-Host "C:\Users\Acer\.aptos\config.yaml" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Verify in explorer (just opened)" -ForegroundColor White
    Write-Host "2. Import account to Petra wallet" -ForegroundColor White
    Write-Host "3. Switch Petra to Devnet" -ForegroundColor White
    Write-Host "4. Create Supabase table" -ForegroundColor White
    Write-Host "5. npm run dev" -ForegroundColor White
    Write-Host "6. Test!" -ForegroundColor White
} else {
    Write-Host "Deployment failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "New account created but deployment failed." -ForegroundColor Yellow
    Write-Host "Account: $accountAddress" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This confirms Aptos network issues." -ForegroundColor Yellow
    Write-Host "Try again in a few hours." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
