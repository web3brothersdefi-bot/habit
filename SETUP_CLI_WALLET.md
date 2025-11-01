# 🔑 Setup CLI with Your Petra Wallet

## 🎯 **THE REAL ISSUE**

The Aptos CLI is trying to deploy from a **different account** (not your Petra wallet).

**Error:** `INSUFFICIENT_BALANCE_FOR_TRANSACTION_FEE`

**Why:** CLI account has no APT, even though YOUR Petra wallet has APT!

---

## ✅ **THE FIX: Import Your Petra Wallet**

This will make the CLI use YOUR actual wallet (the one with APT).

---

## 📋 **STEP-BY-STEP INSTRUCTIONS**

### **Step 1: Get Your Private Key from Petra** (1 minute)

1. Open **Petra Wallet** extension
2. Click **Settings** (gear icon in top right)
3. Click on **your account name**
4. Click **"Show Private Key"**
5. Enter your **password**
6. **Copy the private key** (starts with `0x`)

⚠️ **IMPORTANT:** Never share this key with anyone!

---

### **Step 2: Initialize CLI with Your Wallet** (1 minute)

**Open PowerShell and run:**

```powershell
cd C:\Users\crisy\OneDrive\Escritorio\test4\move

C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key YOUR_PRIVATE_KEY_HERE --network testnet
```

**Replace `YOUR_PRIVATE_KEY_HERE` with the key you copied from Petra.**

**Example (with fake key):**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key 0xabc123def456789... --network testnet
```

**Output should show:**
```
Aptos CLI is now set up for account 0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c at profile default
```

✅ **It should show YOUR wallet address!**

---

### **Step 3: Verify Setup** (30 seconds)

**Check the account:**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe account list
```

**Should output:**
```
0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c
```

**Check the balance:**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe account balance
```

**Should show your actual APT balance from Petra!**

---

### **Step 4: Deploy the Contract** (2 minutes)

**Now run the deployment script:**

```powershell
cd C:\Users\crisy\OneDrive\Escritorio\test4
.\redeploy.ps1
```

**This will now work because:**
- ✅ CLI is using YOUR wallet
- ✅ Your wallet has APT
- ✅ Contract will deploy successfully!

---

## 🔐 **SECURITY Q&A**

### **Q: Is it safe to give my private key to the CLI?**
**A:** Yes! The CLI stores it encrypted locally in:
```
C:\Users\Acer\.aptos\config.yaml
```
Only YOU have access to this file on YOUR computer.

### **Q: Can the AI see my private key?**
**A:** No! I cannot see what you type in your terminal. It's completely local.

### **Q: What if I don't want to import my key?**
**A:** Use Option 1 instead:
1. Run: `C:\Users\Acer\.aptoscli\bin\aptos.exe account list`
2. Copy the CLI's account address
3. Fund it at: https://aptoslabs.com/testnet-faucet
4. Run deployment script

---

## 🎯 **ALTERNATIVE: Fund CLI Account (No Private Key Needed)**

If you prefer NOT to import your private key:

### **Step 1: Get CLI account address**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe account list
```

**Copy the address shown.**

### **Step 2: Fund it**
1. Go to: https://aptoslabs.com/testnet-faucet
2. Paste the CLI account address
3. Click "Faucet"
4. Wait 10 seconds

### **Step 3: Verify**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe account balance
```

Should show ~100 APT

### **Step 4: Deploy**
```powershell
cd C:\Users\crisy\OneDrive\Escritorio\test4
.\redeploy.ps1
```

---

## 🎊 **AFTER SUCCESSFUL DEPLOYMENT**

Once the script succeeds:

1. ✅ Contract deployed to: `0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c`
2. ✅ Contract initialized
3. ✅ Verified on explorer

**Then:**

### **1. Create Supabase Table**
Run the SQL from `CREATE_STAKES_TABLE.sql` in Supabase SQL Editor

### **2. Start Dev Server**
```powershell
npm run dev
```

### **3. Test Staking**
Open `http://localhost:3000/dashboard` and test!

---

## 📊 **COMPARISON**

| Method | Security | Convenience | Recommended For |
|--------|----------|-------------|-----------------|
| **Import Petra Key** | Safe (local) | High | Production use |
| **Fund CLI Account** | Safe | Medium | Quick testing |

---

## 🚀 **RECOMMENDED APPROACH**

**For Production (what you're doing):**
→ Import your Petra wallet key (Steps 1-4 above)

**For Quick Testing:**
→ Fund the CLI account (Alternative method)

---

## 🎯 **EXECUTE NOW**

**Copy and run these commands:**

```powershell
# Get your private key from Petra first!
# Then run:

cd C:\Users\crisy\OneDrive\Escritorio\test4\move

C:\Users\Acer\.aptoscli\bin\aptos.exe init --private-key YOUR_PRIVATE_KEY --network testnet

# Verify
C:\Users\Acer\.aptoscli\bin\aptos.exe account list
C:\Users\Acer\.aptoscli\bin\aptos.exe account balance

# Deploy
cd ..
.\redeploy.ps1
```

**Replace `YOUR_PRIVATE_KEY` with your actual key from Petra!**

---

## ✅ **SUCCESS CRITERIA**

You'll know it worked when:

1. ✅ `account list` shows your Petra address
2. ✅ `account balance` shows your APT
3. ✅ Deployment script completes successfully
4. ✅ No "INSUFFICIENT_BALANCE" error

---

**Time to complete: 3-5 minutes**  
**Result: Fully deployed contract from YOUR wallet!** 🚀
