# Find correct account and update all configuration files

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  FINDING CORRECT ACCOUNT AND FIXING CONFIGURATION" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

# Step 1: Initialize CLI with the private key
Write-Host "[1/4] Initializing CLI with your private key..." -ForegroundColor Green
$initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --skip-faucet --assume-yes 2>&1
Write-Host "Done" -ForegroundColor Gray

# Step 2: Get the account list
Write-Host ""
Write-Host "[2/4] Getting account address from CLI..." -ForegroundColor Green
$accountOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe config show-profiles 2>&1

Write-Host "CLI Output:" -ForegroundColor Gray
Write-Host $accountOutput
Write-Host ""

# Try to extract account from config
$configPath = "C:\Users\Acer\.aptos\config.yaml"
if (Test-Path $configPath) {
    $configContent = Get-Content $configPath -Raw
    Write-Host "Config file content:" -ForegroundColor Gray
    Write-Host $configContent
    Write-Host ""
    
    # Extract account from YAML
    if ($configContent -match 'account:\s*(0x[a-f0-9]+)') {
        $ACTUAL_ACCOUNT = $matches[1]
        Write-Host "Found account in config: $ACTUAL_ACCOUNT" -ForegroundColor Green
    } else {
        Write-Host "Could not extract account from config" -ForegroundColor Red
    }
} else {
    Write-Host "Config file not found at: $configPath" -ForegroundColor Red
}

# Alternative: Parse from account info
if (-not $ACTUAL_ACCOUNT) {
    Write-Host "Trying alternative method..." -ForegroundColor Yellow
    $accountInfo = & C:\Users\Acer\.aptoscli\bin\aptos.exe account list 2>&1
    Write-Host "Account list output:" -ForegroundColor Gray
    Write-Host $accountInfo
    Write-Host ""
}

if ($ACTUAL_ACCOUNT) {
    # Step 3: Verify balance
    Write-Host ""
    Write-Host "[3/4] Verifying balance of $ACTUAL_ACCOUNT..." -ForegroundColor Green
    $balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json
    
    if ($balanceOutput.Result -and $balanceOutput.Result.Count -gt 0) {
        $aptBalance = [long]$balanceOutput.Result[0].balance
        $aptAmount = $aptBalance / 100000000.0
        Write-Host "Balance: $aptAmount APT" -ForegroundColor Cyan
        Write-Host ""
        
        if ($aptAmount -lt 10) {
            Write-Host "WARNING: Balance is low. Get more APT from:" -ForegroundColor Yellow
            Write-Host "https://aptoslabs.com/testnet-faucet" -ForegroundColor Cyan
            Write-Host "Address: $ACTUAL_ACCOUNT" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Press Enter after getting APT to continue..."
            Read-Host
        }
    }
    
    # Step 4: Update all configuration files
    Write-Host ""
    Write-Host "[4/4] Updating configuration files..." -ForegroundColor Green
    
    # Update Move.toml
    $moveTomlPath = "C:\Users\crisy\OneDrive\Escritorio\test4\move\Move.toml"
    $moveTomlContent = Get-Content $moveTomlPath -Raw
    $moveTomlContent = $moveTomlContent -replace 'habit = "0x[a-f0-9]+"', "habit = `"$ACTUAL_ACCOUNT`""
    Set-Content -Path $moveTomlPath -Value $moveTomlContent
    Write-Host "  Updated: move/Move.toml" -ForegroundColor Gray
    
    # Update .env
    $envPath = "C:\Users\crisy\OneDrive\Escritorio\test4\.env"
    $envContent = Get-Content $envPath -Raw
    $envContent = $envContent -replace 'VITE_MODULE_ADDRESS=0x[a-f0-9]+', "VITE_MODULE_ADDRESS=$ACTUAL_ACCOUNT"
    Set-Content -Path $envPath -Value $envContent
    Write-Host "  Updated: .env" -ForegroundColor Gray
    
    # Update deploy scripts
    $deployFixedPath = "C:\Users\crisy\OneDrive\Escritorio\test4\deploy_fixed.ps1"
    if (Test-Path $deployFixedPath) {
        $deployContent = Get-Content $deployFixedPath -Raw
        $deployContent = $deployContent -replace '\$WALLET_ADDRESS = "0x[a-f0-9]+"', "`$WALLET_ADDRESS = `"$ACTUAL_ACCOUNT`""
        Set-Content -Path $deployFixedPath -Value $deployContent
        Write-Host "  Updated: deploy_fixed.ps1" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host "  CONFIGURATION UPDATED!" -ForegroundColor Cyan
    Write-Host "===========================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Correct Account: $ACTUAL_ACCOUNT" -ForegroundColor Green
    Write-Host "Balance: $aptAmount APT" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "All configuration files have been updated to use the correct account!" -ForegroundColor Green
    Write-Host ""
    Write-Host "NEXT STEP:" -ForegroundColor Yellow
    Write-Host "Run: .\deploy_fixed.ps1" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "ERROR: Could not determine account address" -ForegroundColor Red
    Write-Host ""
    Write-Host "MANUAL SOLUTION:" -ForegroundColor Yellow
    Write-Host "1. Run: C:\Users\Acer\.aptoscli\bin\aptos.exe account list" -ForegroundColor White
    Write-Host "2. Copy the account address shown" -ForegroundColor White
    Write-Host "3. Update Move.toml, .env, and deploy_fixed.ps1 with that address" -ForegroundColor White
    Write-Host ""
}

Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
