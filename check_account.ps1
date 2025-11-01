# Account Verification Script
# This checks if your private key matches your wallet address

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "  ACCOUNT VERIFICATION" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""

$WALLET_ADDRESS = "0xb475cbe24c14e219e37e908d6e95e0c344913a1648099915b5cb3320b8ea5345"
$PRIVATE_KEY = "ed25519-priv-0x343e218e26c91d702effa40de4c62c18f26f765ba75bb49ada4ab251c09c3407"

Write-Host "Expected Wallet Address: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host ""

# Initialize CLI with the private key
Write-Host "Initializing CLI with your private key..." -ForegroundColor Green
$initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key $PRIVATE_KEY --network testnet --skip-faucet --assume-yes 2>&1

# Extract the actual account from init output
$actualAccount = ""
if ($initOutput -match "account (0x[a-f0-9]+)") {
    $actualAccount = $matches[1]
}

Write-Host ""
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host "VERIFICATION RESULTS:" -ForegroundColor Cyan
Write-Host "===========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Expected Address: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host "Actual Address:   $actualAccount" -ForegroundColor Cyan
Write-Host ""

if ($actualAccount -eq $WALLET_ADDRESS) {
    Write-Host "MATCH! Private key corresponds to wallet address." -ForegroundColor Green
    Write-Host ""
    
    # Check balance of this account
    Write-Host "Checking balance of this account..." -ForegroundColor Green
    $balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json
    
    if ($balanceOutput.Result -and $balanceOutput.Result.Count -gt 0) {
        $aptBalance = [long]$balanceOutput.Result[0].balance
        $aptAmount = $aptBalance / 100000000.0
        Write-Host "Balance: $aptAmount APT" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Everything is correct! You can deploy." -ForegroundColor Green
    } else {
        Write-Host "Balance: 0 APT" -ForegroundColor Red
        Write-Host ""
        Write-Host "ACTION REQUIRED: Get APT from faucet" -ForegroundColor Yellow
        Write-Host "https://aptoslabs.com/testnet-faucet" -ForegroundColor Cyan
    }
} else {
    Write-Host "MISMATCH! Private key does NOT match wallet address!" -ForegroundColor Red
    Write-Host ""
    Write-Host "PROBLEM:" -ForegroundColor Red
    Write-Host "  Your private key belongs to: $actualAccount" -ForegroundColor Yellow
    Write-Host "  But you're trying to deploy to: $WALLET_ADDRESS" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "SOLUTION:" -ForegroundColor Green
    Write-Host "  Option 1: Get the correct private key for $WALLET_ADDRESS from Petra" -ForegroundColor White
    Write-Host "  Option 2: Update Move.toml and .env to use $actualAccount instead" -ForegroundColor White
    Write-Host ""
    
    # Check if the actual account has balance
    Write-Host "Checking balance of actual account ($actualAccount)..." -ForegroundColor Green
    $balanceOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe account balance 2>&1 | ConvertFrom-Json
    
    if ($balanceOutput.Result -and $balanceOutput.Result.Count -gt 0) {
        $aptBalance = [long]$balanceOutput.Result[0].balance
        $aptAmount = $aptBalance / 100000000.0
        Write-Host "Balance of $actualAccount : $aptAmount APT" -ForegroundColor Cyan
    } else {
        Write-Host "Balance of $actualAccount : 0 APT" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "RECOMMENDED: Update configuration to use $actualAccount" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
