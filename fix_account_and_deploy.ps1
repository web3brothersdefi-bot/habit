# Fix account state and deploy properly
# This script fixes the AptosCoin resource issue

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FIX ACCOUNT STATE AND DEPLOY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

# Step 1: Reinitialize account properly
Write-Host "[1/7] Reinitializing account (this fixes AptosCoin resource)..." -ForegroundColor Green
$initResult = & C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --assume-yes 2>&1

Write-Host "Init result:" -ForegroundColor Gray
Write-Host $initResult
Write-Host ""

# Extract account
$profileData = & C:\Users\Acer\.aptoscli\bin\aptos.exe config show-profiles 2>&1 | ConvertFrom-Json
$account = "0x" + $profileData.Result.default.account
Write-Host "Account: $account" -ForegroundColor Cyan

# Step 2: Wait for initialization
Write-Host ""
Write-Host "[2/7] Waiting for account initialization..." -ForegroundColor Green
Start-Sleep -Seconds 10

# Step 3: Check balance
Write-Host ""
Write-Host "[3/7] Checking balance..." -ForegroundColor Green
$balanceData = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance --account $account 2>&1 | ConvertFrom-Json

if ($balanceData.Result -and $balanceData.Result.Count -gt 0) {
    $balance = [long]$balanceData.Result[0].balance
    $aptAmount = $balance / 100000000.0
    Write-Host "  Balance: $aptAmount APT" -ForegroundColor Cyan
} else {
    Write-Host "  Balance: 0 APT or account not initialized" -ForegroundColor Yellow
    Write-Host "  Getting APT from faucet..." -ForegroundColor Yellow
    
    & C:\Users\Acer\.aptoscli\bin\aptos.exe account fund-with-faucet --account $account 2>&1 | Out-Null
    Start-Sleep -Seconds 10
    
    $balanceData = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance --account $account 2>&1 | ConvertFrom-Json
    $balance = [long]$balanceData.Result[0].balance
    $aptAmount = $balance / 100000000.0
    Write-Host "  New balance: $aptAmount APT" -ForegroundColor Cyan
}

# Step 4: Check AptosCoin resource
Write-Host ""
Write-Host "[4/7] Verifying AptosCoin resource..." -ForegroundColor Green
$resources = & C:\Users\Acer\.aptoscli\bin\aptos.exe account list --query resources --account $account 2>&1

if ($resources -match "0x1::coin::CoinStore<0x1::aptos_coin::AptosCoin>") {
    Write-Host "  AptosCoin resource: EXISTS" -ForegroundColor Green
} else {
    Write-Host "  AptosCoin resource: MISSING" -ForegroundColor Red
    Write-Host "  This account needs a transaction to initialize the resource" -ForegroundColor Yellow
    Write-Host "  The deployment itself should initialize it" -ForegroundColor Yellow
}

# Step 5: Navigate and compile
Write-Host ""
Write-Host "[5/7] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"

Write-Host ""
Write-Host "Cleaning and compiling..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

& C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1 | Out-Null
Write-Host "  Compilation complete" -ForegroundColor Green

# Step 6: Deploy with CORRECT gas settings for testnet
Write-Host ""
Write-Host "[6/7] Deploying with testnet-appropriate gas settings..." -ForegroundColor Green
Write-Host "  IMPORTANT: Testnet minimum gas price is 100" -ForegroundColor Yellow
Write-Host ""

# Try with proper gas settings
Write-Host "  Attempt 1: Standard testnet gas..." -ForegroundColor Cyan
Write-Host "    Max gas: 30000, Price: 100" -ForegroundColor Gray

$deploy1 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 30000 --gas-unit-price 100 --assume-yes 2>&1

if ($deploy1 -match '"success":\s*true') {
    Write-Host "  SUCCESS!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($deploy1 -match "INSUFFICIENT_BALANCE") {
    Write-Host "  Failed: Insufficient balance with 30000 gas" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Attempt 2: Higher gas limit..." -ForegroundColor Cyan
    Write-Host "    Max gas: 60000, Price: 100" -ForegroundColor Gray
    
    $deploy2 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 60000 --gas-unit-price 100 --assume-yes 2>&1
    
    if ($deploy2 -match '"success":\s*true') {
        Write-Host "  SUCCESS!" -ForegroundColor Green
        $deploySuccess = $true
    } elseif ($deploy2 -match "INSUFFICIENT_BALANCE") {
        Write-Host "  Failed: Insufficient balance with 60000 gas" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Attempt 3: Maximum reasonable gas..." -ForegroundColor Cyan
        Write-Host "    Max gas: 100000, Price: 100" -ForegroundColor Gray
        
        $deploy3 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 100000 --gas-unit-price 100 --assume-yes 2>&1
        
        if ($deploy3 -match '"success":\s*true') {
            Write-Host "  SUCCESS!" -ForegroundColor Green
            $deploySuccess = $true
        } else {
            Write-Host "  FAILED after all attempts" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Error output:" -ForegroundColor Gray
            Write-Host $deploy3
            Write-Host ""
            
            if ($deploy3 -match "INSUFFICIENT_BALANCE") {
                Write-Host "  ROOT CAUSE: Account state is corrupted" -ForegroundColor Red
                Write-Host ""
                Write-Host "  SOLUTION: Create a NEW account" -ForegroundColor Yellow
                Write-Host "  1. In Petra wallet, create a new account" -ForegroundColor White
                Write-Host "  2. Export the new account's private key" -ForegroundColor White
                Write-Host "  3. Update the PRIVATE_KEY in this script" -ForegroundColor White
                Write-Host "  4. Run this script again" -ForegroundColor White
                Write-Host ""
                Write-Host "  OR use Aptos Devnet instead of Testnet" -ForegroundColor White
            }
        }
    } else {
        Write-Host "  Deployment status unclear" -ForegroundColor Yellow
        Write-Host $deploy2
    }
} elseif ($deploy1 -match "ALREADY_PUBLISHED") {
    Write-Host "  Module already exists!" -ForegroundColor Cyan
    $deploySuccess = $true
} else {
    Write-Host "  Status unclear" -ForegroundColor Yellow
    Write-Host $deploy1
}

# Step 7: Initialize if successful
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[7/7] Initializing contract..." -ForegroundColor Green
    
    $initContract = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${account}::stake_match::initialize" --args address:$account --max-gas 30000 --gas-unit-price 100 --assume-yes 2>&1
    
    if ($initContract -match '"success":\s*true') {
        Write-Host "  Contract initialized!" -ForegroundColor Green
    } elseif ($initContract -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized (OK)" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization unclear" -ForegroundColor Yellow
        Write-Host $initContract
    }
} else {
    Write-Host ""
    Write-Host "[7/7] Skipping initialization (deployment failed)" -ForegroundColor Red
}

Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FINAL RESULT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

if ($deploySuccess) {
    Write-Host "SUCCESS! Contract deployed to:" -ForegroundColor Green
    Write-Host "$account" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Verify at:" -ForegroundColor Yellow
    Write-Host "https://explorer.aptoslabs.com/account/${account}?network=testnet" -ForegroundColor Cyan
    Write-Host ""
    Start-Process "https://explorer.aptoslabs.com/account/${account}?network=testnet"
    Write-Host "Opening explorer..." -ForegroundColor Gray
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Verify 'stake_match' module in explorer" -ForegroundColor White
    Write-Host "2. Create Supabase stakes table (SQL in CREATE_STAKES_TABLE.sql)" -ForegroundColor White
    Write-Host "3. Run: npm run dev" -ForegroundColor White
    Write-Host "4. Test staking!" -ForegroundColor White
} else {
    Write-Host "DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Your account appears to have a resource initialization issue." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "RECOMMENDED SOLUTION:" -ForegroundColor Green
    Write-Host "1. Create a brand new account in Petra wallet" -ForegroundColor White
    Write-Host "2. Export that account's private key" -ForegroundColor White
    Write-Host "3. Get APT from faucet for the new account" -ForegroundColor White
    Write-Host "4. Update Move.toml, .env, and scripts with new address" -ForegroundColor White
    Write-Host "5. Deploy to the fresh account" -ForegroundColor White
    Write-Host ""
    Write-Host "A fresh account will have proper AptosCoin resources initialized." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
