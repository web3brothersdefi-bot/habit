# Comprehensive diagnosis and deployment script
# Finds and fixes account issues

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  APTOS ACCOUNT DIAGNOSIS AND DEPLOYMENT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

# Step 1: Initialize and get account
Write-Host "[1/9] Initializing CLI..." -ForegroundColor Green
& C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --skip-faucet --assume-yes | Out-Null

$profileData = & C:\Users\Acer\.aptoscli\bin\aptos.exe config show-profiles 2>&1 | ConvertFrom-Json
$account = "0x" + $profileData.Result.default.account
Write-Host "  Account: $account" -ForegroundColor Cyan

# Step 2: Check account on-chain
Write-Host ""
Write-Host "[2/9] Checking account on blockchain..." -ForegroundColor Green
$accountInfo = & C:\Users\Acer\.aptoscli\bin\aptos.exe account lookup-address --account $account 2>&1

if ($accountInfo -match "Account does not exist") {
    Write-Host "  Account NOT FOUND on chain!" -ForegroundColor Red
    Write-Host "  This means account needs initialization" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Getting APT from faucet to initialize account..." -ForegroundColor Green
    
    $faucetResult = & C:\Users\Acer\.aptoscli\bin\aptos.exe account fund-with-faucet --account $account 2>&1
    Write-Host "  Faucet result: $faucetResult" -ForegroundColor Gray
    
    Start-Sleep -Seconds 5
} else {
    Write-Host "  Account EXISTS on chain" -ForegroundColor Green
}

# Step 3: Check balance
Write-Host ""
Write-Host "[3/9] Checking balance..." -ForegroundColor Green
$balanceData = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance --account $account 2>&1 | ConvertFrom-Json

if ($balanceData.Result) {
    $balance = [long]$balanceData.Result[0].balance
    $aptAmount = $balance / 100000000.0
    Write-Host "  Balance: $aptAmount APT ($balance Octas)" -ForegroundColor Cyan
    
    if ($aptAmount -lt 50) {
        Write-Host ""
        Write-Host "  Balance is low. Getting more from faucet..." -ForegroundColor Yellow
        
        for ($i = 1; $i -le 15; $i++) {
            Write-Host "  Faucet request $i/15..." -ForegroundColor Gray
            & C:\Users\Acer\.aptoscli\bin\aptos.exe account fund-with-faucet --account $account 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        }
        
        Write-Host "  Waiting for transactions to settle..." -ForegroundColor Gray
        Start-Sleep -Seconds 10
        
        $balanceData = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance --account $account 2>&1 | ConvertFrom-Json
        $balance = [long]$balanceData.Result[0].balance
        $aptAmount = $balance / 100000000.0
        Write-Host "  New balance: $aptAmount APT" -ForegroundColor Cyan
    }
} else {
    Write-Host "  Could not read balance" -ForegroundColor Red
}

# Step 4: Check account resources
Write-Host ""
Write-Host "[4/9] Checking account resources..." -ForegroundColor Green
$resources = & C:\Users\Acer\.aptoscli\bin\aptos.exe account list --query resources --account $account 2>&1
Write-Host "  Resources found: $(if ($resources -match 'AptosCoin') {'AptosCoin resource exists'} else {'No AptosCoin resource'})" -ForegroundColor Gray

# Step 5: Navigate to move directory
Write-Host ""
Write-Host "[5/9] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"

# Step 6: Clean and compile
Write-Host ""
Write-Host "[6/9] Cleaning and compiling..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
}

$compileResult = & C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1
if ($compileResult -match "BUILDING HabitPlatform") {
    Write-Host "  Compilation successful!" -ForegroundColor Green
} else {
    Write-Host "  Compilation unclear" -ForegroundColor Yellow
}

# Step 7: Try deployment with different gas strategies
Write-Host ""
Write-Host "[7/9] Attempting deployment (Strategy 1: Standard gas)..." -ForegroundColor Green
Write-Host "  Gas: 20000 units, price: 100" -ForegroundColor Gray

$deploy1 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 20000 --gas-unit-price 100 --assume-yes 2>&1

if ($deploy1 -match '"success":\s*true') {
    Write-Host "  SUCCESS with standard gas!" -ForegroundColor Green
    $deploySuccess = $true
} elseif ($deploy1 -match "INSUFFICIENT_BALANCE") {
    Write-Host "  Failed: Insufficient balance" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Trying Strategy 2: Higher gas limit..." -ForegroundColor Green
    Write-Host "  Gas: 50000 units, price: 100" -ForegroundColor Gray
    
    $deploy2 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 50000 --gas-unit-price 100 --assume-yes 2>&1
    
    if ($deploy2 -match '"success":\s*true') {
        Write-Host "  SUCCESS with higher gas!" -ForegroundColor Green
        $deploySuccess = $true
    } elseif ($deploy2 -match "INSUFFICIENT_BALANCE") {
        Write-Host "  Still insufficient. Trying Strategy 3..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Strategy 3: Lower gas price..." -ForegroundColor Green
        Write-Host "  Gas: 100000 units, price: 50" -ForegroundColor Gray
        
        $deploy3 = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 100000 --gas-unit-price 50 --assume-yes 2>&1
        
        if ($deploy3 -match '"success":\s*true') {
            Write-Host "  SUCCESS with optimized gas!" -ForegroundColor Green
            $deploySuccess = $true
        } else {
            Write-Host "  All strategies failed" -ForegroundColor Red
            Write-Host ""
            Write-Host "  Last deployment output:" -ForegroundColor Gray
            Write-Host $deploy3
        }
    } else {
        Write-Host "  Deployment status unclear" -ForegroundColor Yellow
        Write-Host $deploy2
    }
} elseif ($deploy1 -match "ALREADY_PUBLISHED") {
    Write-Host "  Contract already published!" -ForegroundColor Cyan
    $deploySuccess = $true
} else {
    Write-Host "  Deployment status unclear" -ForegroundColor Yellow
    Write-Host $deploy1
}

# Step 8: Initialize if deployment succeeded
if ($deploySuccess) {
    Write-Host ""
    Write-Host "[8/9] Initializing contract..." -ForegroundColor Green
    
    $initResult = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${account}::stake_match::initialize" --args address:$account --max-gas 50000 --assume-yes 2>&1
    
    if ($initResult -match '"success":\s*true') {
        Write-Host "  Contract initialized!" -ForegroundColor Green
    } elseif ($initResult -match "ALREADY_EXISTS") {
        Write-Host "  Already initialized" -ForegroundColor Cyan
    } else {
        Write-Host "  Initialization status unclear" -ForegroundColor Yellow
        Write-Host $initResult
    }
} else {
    Write-Host ""
    Write-Host "[8/9] Skipping initialization (deployment failed)" -ForegroundColor Yellow
}

# Step 9: Final verification
Write-Host ""
Write-Host "[9/9] Final verification..." -ForegroundColor Green
$finalBalance = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance --account $account 2>&1 | ConvertFrom-Json
if ($finalBalance.Result) {
    $finalApt = ([long]$finalBalance.Result[0].balance) / 100000000.0
    Write-Host "  Final balance: $finalApt APT" -ForegroundColor Cyan
}

Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Account: $account" -ForegroundColor Green
Write-Host ""

if ($deploySuccess) {
    Write-Host "STATUS: DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Verify at:" -ForegroundColor Yellow
    Write-Host "https://explorer.aptoslabs.com/account/${account}?network=testnet" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Opening explorer..." -ForegroundColor Gray
    Start-Process "https://explorer.aptoslabs.com/account/${account}?network=testnet"
    Write-Host ""
    Write-Host "NEXT STEPS:" -ForegroundColor Yellow
    Write-Host "1. Check explorer for 'stake_match' module" -ForegroundColor White
    Write-Host "2. Create Supabase stakes table" -ForegroundColor White
    Write-Host "3. Run: npm run dev" -ForegroundColor White
    Write-Host "4. Test staking!" -ForegroundColor White
} else {
    Write-Host "STATUS: DEPLOYMENT FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Possible issues:" -ForegroundColor Yellow
    Write-Host "1. Testnet congestion" -ForegroundColor White
    Write-Host "2. Account state issue" -ForegroundColor White
    Write-Host "3. Gas estimation problem" -ForegroundColor White
    Write-Host ""
    Write-Host "SOLUTION:" -ForegroundColor Yellow
    Write-Host "Try again in 5 minutes or use Aptos Devnet instead" -ForegroundColor White
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
