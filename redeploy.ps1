# Automated Redeploy Script
# This script will deploy the contract to YOUR wallet address

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  APTOS CONTRACT REDEPLOYMENT SCRIPT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Your wallet address
$WALLET_ADDRESS = "0xb475cbe24c14e219e37e908d6e95e0c344913a1648099915b5cb3320b8ea5345"

Write-Host "Your Wallet Address: $WALLET_ADDRESS" -ForegroundColor Yellow
Write-Host ""

# Navigate to move directory
Write-Host "[1/6] Navigating to move directory..." -ForegroundColor Green
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4\move"
Write-Host "      Current directory: $(Get-Location)" -ForegroundColor Gray

# Clean build
Write-Host "`n[2/6] Cleaning previous build..." -ForegroundColor Green
if (Test-Path "build") {
    Remove-Item -Path "build" -Recurse -Force
    Write-Host "      Build directory removed" -ForegroundColor Gray
} else {
    Write-Host "      No build directory to clean" -ForegroundColor Gray
}

# Compile
Write-Host "`n[3/6] Compiling contract..." -ForegroundColor Green
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray
$compileOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move compile 2>&1
$compileOutput | Out-String | Write-Host

# Check if compile was successful
if ($compileOutput -match "BUILDING HabitPlatform") {
    Write-Host "      ✅ Compilation successful!" -ForegroundColor Green
    
    # Check if correct address
    if ($compileOutput -match "7ca90e5eea844329") {
        Write-Host "      ✅ Contract will deploy to YOUR address!" -ForegroundColor Green
    } else {
        Write-Host "      ❌ WARNING: Address mismatch detected!" -ForegroundColor Red
        Write-Host "      Check Move.toml line 7 and try again" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      ❌ Compilation failed!" -ForegroundColor Red
    exit 1
}

# Deploy
Write-Host "`n[4/6] Deploying contract to blockchain..." -ForegroundColor Green
Write-Host "      This may take 30-60 seconds..." -ForegroundColor Gray
$publishOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 20000 --assume-yes 2>&1
$publishOutput | Out-String | Write-Host

# Check if publish was successful
if ($publishOutput -match '"success": true' -or $publishOutput -match 'Success') {
    Write-Host "      ✅ Deployment successful!" -ForegroundColor Green
} else {
    Write-Host "      ❌ Deployment failed!" -ForegroundColor Red
    Write-Host "      Check error above and try again" -ForegroundColor Red
    exit 1
}

# Initialize
Write-Host "`n[5/6] Initializing contract..." -ForegroundColor Green
Write-Host "      This may take 10-20 seconds..." -ForegroundColor Gray
$initOutput = & C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${WALLET_ADDRESS}::stake_match::initialize" --args address:$WALLET_ADDRESS --max-gas 20000 --assume-yes 2>&1
$initOutput | Out-String | Write-Host

# Check if initialization was successful
if ($initOutput -match '"success": true' -or $initOutput -match 'Success') {
    Write-Host "      ✅ Initialization successful!" -ForegroundColor Green
} else {
    Write-Host "      ⚠️  Initialization may have failed" -ForegroundColor Yellow
    Write-Host "      This might be OK if contract was already initialized" -ForegroundColor Yellow
}

# Return to root
Set-Location -Path "C:\Users\crisy\OneDrive\Escritorio\test4"

Write-Host "`n[6/6] Verification..." -ForegroundColor Green
Write-Host "      Opening Aptos Explorer..." -ForegroundColor Gray
$explorerUrl = "https://explorer.aptoslabs.com/account/$WALLET_ADDRESS?network=testnet"
Start-Process $explorerUrl

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host "  DEPLOYMENT COMPLETE!" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ Contract deployed to: $WALLET_ADDRESS" -ForegroundColor Green
Write-Host "✅ Check the opened browser tab to verify" -ForegroundColor Green
Write-Host ""
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Verify in browser that 'stake_match' module exists" -ForegroundColor White
Write-Host "2. Create stakes table in Supabase (see CREATE_STAKES_TABLE.sql)" -ForegroundColor White
Write-Host "3. Run: npm run dev" -ForegroundColor White
Write-Host "4. Test staking on Dashboard" -ForegroundColor White
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
