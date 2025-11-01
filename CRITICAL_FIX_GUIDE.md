# 🚨 CRITICAL FIX - Module Not Found Error

## ⚠️ **THE REAL PROBLEM**

Your error **"Module name(stake_match) not found"** means the smart contract **is NOT deployed** at the address in your `.env` file.

**Even fresh accounts fail** → Contract deployment issue, NOT stake issue!

---

## 🔍 **ROOT CAUSE ANALYSIS**

### **Current Configuration:**
```
VITE_MODULE_ADDRESS=0x78be456e78ffec3148be7b55580d91adc963e6affdf5a77672d31e44c0baa84c
```

### **The Problem:**
1. This address is in your `.env` and `Move.toml`
2. BUT the contract is NOT deployed at this address
3. OR this address is not your wallet's address
4. OR the module name is different

### **Why Even Fresh Accounts Fail:**
- It's not about old stakes
- It's about the contract not existing at all
- Frontend tries to call a non-existent contract
- Blockchain returns "Module not found"

---

## ✅ **COMPLETE FIX (Step-by-Step)**

### **STEP 1: Find Your Wallet Address** (30 seconds)

1. Open Petra Wallet
2. Copy your wallet address
3. It should look like: `0x7ca8...301c` (short form)
4. Full form: `0x07ca8....(66 characters total)....0301c`

**Your wallet address MUST be the MODULE_ADDRESS!**

---

### **STEP 2: Update Configuration Files** (2 minutes)

#### **A. Update `.env` file:**

```env
# OLD (WRONG):
VITE_MODULE_ADDRESS=0x78be456e78ffec3148be7b55580d91adc963e6affdf5a77672d31e44c0baa84c

# NEW (YOUR WALLET):
VITE_MODULE_ADDRESS=<YOUR_WALLET_ADDRESS_HERE>
```

**Example:**
```env
VITE_MODULE_ADDRESS=0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c
```

#### **B. Update `move/Move.toml` file:**

```toml
[addresses]
habit = "<YOUR_WALLET_ADDRESS_HERE>"
```

**Example:**
```toml
[addresses]
habit = "0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c"
```

---

### **STEP 3: Deploy Smart Contract** (5 minutes)

#### **A. Open Terminal/PowerShell:**

```powershell
cd c:\Users\crisy\OneDrive\Escritorio\test4\move
```

#### **B. Compile the contract:**

```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move compile
```

**Expected output:**
```
Compiling, may take a little while to download git dependencies...
INCLUDING DEPENDENCY AptosFramework
BUILDING HabitPlatform
{
  "Result": [
    "Success"
  ]
}
```

#### **C. Deploy (publish) the contract:**

```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --assume-yes
```

**This will:**
1. Ask for gas approval (auto-approved with --assume-yes)
2. Deploy to YOUR wallet address
3. Return transaction hash

**Expected output:**
```
{
  "Result": {
    "transaction_hash": "0xabc123...",
    "gas_used": 1234,
    "gas_unit_price": 100,
    "sender": "0x07ca8...",
    "success": true,
    "version": 12345,
    "vm_status": "Executed successfully"
  }
}
```

**⚠️ IMPORTANT:** If this fails with "Insufficient balance", get test APT first:
```
https://aptoslabs.com/testnet-faucet
```

---

### **STEP 4: Initialize Contract** (1 minute)

After deployment, initialize:

```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id <YOUR_WALLET_ADDRESS>::stake_match::initialize --args address:<YOUR_WALLET_ADDRESS> --assume-yes
```

**Replace `<YOUR_WALLET_ADDRESS>` with your actual address!**

**Example:**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id 0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c::stake_match::initialize --args address:0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c --assume-yes
```

**Expected output:**
```
{
  "Result": {
    "transaction_hash": "0xdef456...",
    "success": true,
    "vm_status": "Executed successfully"
  }
}
```

---

### **STEP 5: Verify Deployment** (1 minute)

#### **A. Check on Aptos Explorer:**

```
https://explorer.aptoslabs.com/account/<YOUR_WALLET_ADDRESS>?network=testnet
```

**You should see:**
- ✅ Account exists
- ✅ Modules tab shows "stake_match"
- ✅ Resources tab shows "StakeRegistry"

#### **B. Or use diagnostic tool:**

Open browser console (F12) and run:
```javascript
import { diagnoseContract } from './src/utils/contractDiagnostics';
diagnoseContract();
```

---

### **STEP 6: Restart Dev Server** (30 seconds)

```powershell
# Stop current server (Ctrl+C)
npm run dev
```

---

### **STEP 7: Test Staking** (1 minute)

1. Open `http://localhost:3000/dashboard`
2. Swipe right on any user
3. Petra opens → Approve
4. **SUCCESS!** ✅

---

## 🎯 **IF YOU STILL GET ERRORS**

### **Error: "E_NOT_INITIALIZED"**
**Fix:** Run Step 4 again (initialize contract)

### **Error: "Module not found"**
**Fix:** 
1. Verify .env has YOUR wallet address
2. Verify Move.toml has YOUR wallet address
3. Redeploy (Steps 3-4)
4. Restart server

### **Error: "E_STAKE_ALREADY_EXISTS"**
**Fix:** This is expected if you tested before
1. Go to `http://localhost:3000/manage-stakes`
2. Refund old stakes
3. Try again

### **Error: "Insufficient balance"**
**Fix:** Get test APT from faucet:
```
https://aptoslabs.com/testnet-faucet
Paste your wallet address
Click "Faucet"
Wait 10 seconds
```

---

## 📋 **COMPLETE CHECKLIST**

Before testing:

- [ ] Petra wallet installed and funded (> 1 APT)
- [ ] Copied your wallet address
- [ ] Updated `.env` with YOUR address
- [ ] Updated `Move.toml` with YOUR address
- [ ] Compiled contract successfully
- [ ] Deployed contract successfully
- [ ] Initialized contract successfully
- [ ] Verified on Aptos Explorer
- [ ] Restarted dev server
- [ ] Tested staking

---

## 🎨 **PROPER CONFIGURATION EXAMPLE**

### **Your Wallet:** `0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c`

### **`.env`:**
```env
VITE_SUPABASE_URL=https://kwrkiubutllfcnhgkgpo.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
VITE_MODULE_ADDRESS=0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c
```

### **`move/Move.toml`:**
```toml
[package]
name = "HabitPlatform"
version = "1.0.0"

[addresses]
habit = "0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c"
```

---

## 🚀 **QUICK FIX SCRIPT**

Save this as `redeploy.ps1`:

```powershell
# Replace with YOUR wallet address
$WALLET = "0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c"

Write-Host "🔧 Fixing configuration..." -ForegroundColor Yellow

# Update .env
(Get-Content .env) -replace 'VITE_MODULE_ADDRESS=.*', "VITE_MODULE_ADDRESS=$WALLET" | Set-Content .env

# Update Move.toml
(Get-Content move/Move.toml) -replace 'habit = ".*"', "habit = `"$WALLET`"" | Set-Content move/Move.toml

Write-Host "✅ Configuration updated!" -ForegroundColor Green

# Compile
Write-Host "📦 Compiling contract..." -ForegroundColor Yellow
cd move
C:\Users\Acer\.aptoscli\bin\aptos.exe move compile

# Deploy
Write-Host "🚀 Deploying contract..." -ForegroundColor Yellow
C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --assume-yes

# Initialize
Write-Host "🎬 Initializing contract..." -ForegroundColor Yellow
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id "${WALLET}::stake_match::initialize" --args address:$WALLET --assume-yes

cd ..

Write-Host "✅ Done! Restart your dev server." -ForegroundColor Green
```

**Run:**
```powershell
.\redeploy.ps1
```

---

## 🎯 **WHY THIS FIXES EVERYTHING**

### **Old Issue (E_STAKE_ALREADY_EXISTS):**
- Was caused by old stakes
- Fixed by refunding on /manage-stakes

### **New Issue (Module not found):**
- Caused by wrong MODULE_ADDRESS
- Contract deployed to different address
- Frontend looking at wrong address
- **FIX:** Deploy to YOUR wallet address

### **After This Fix:**
- ✅ Contract deployed to YOUR address
- ✅ Frontend uses YOUR address
- ✅ All calls go to correct module
- ✅ Staking works for everyone
- ✅ No more "module not found"

---

## 🎊 **SUCCESS CRITERIA**

You'll know it's fixed when:

1. ✅ No "Module not found" errors
2. ✅ Petra opens when you stake
3. ✅ Transaction succeeds
4. ✅ No blockchain errors
5. ✅ Both old and new users can stake

---

## 📞 **STILL STUCK?**

### **Check These:**

1. **Wallet has APT?**
   - Open Petra → Should show > 1 APT
   - If not: https://aptoslabs.com/testnet-faucet

2. **Addresses match?**
   - `.env` = `Move.toml` = Your Wallet Address
   - All three must be identical

3. **Contract deployed?**
   - Check: https://explorer.aptoslabs.com/account/YOUR_ADDRESS?network=testnet
   - Should see modules

4. **Server restarted?**
   - Ctrl+C → `npm run dev`

---

## 🎉 **TOTAL TIME**

- **Configuration:** 2 minutes
- **Deployment:** 5 minutes
- **Testing:** 2 minutes
- **TOTAL:** 10 minutes

---

**FOLLOW THESE STEPS EXACTLY AND YOUR DAPP WILL WORK!** 🚀

**Start with STEP 1: Find your wallet address!**
