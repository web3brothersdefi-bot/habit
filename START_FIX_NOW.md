# ⚡ START FIX NOW - Quick Visual Guide

## 🎯 **THE PROBLEM**

```
❌ MODULE ADDRESS IN .ENV IS WRONG!
❌ Contract NOT deployed to that address
❌ Both fresh AND old users fail
✅ SOLUTION: Deploy to YOUR wallet address
```

---

## 🚀 **THE FIX (3 Simple Parts)**

```
PART 1: Update Addresses (3 min)
   ↓
PART 2: Deploy Contract (6 min)
   ↓
PART 3: Test Everything (3 min)
```

**Total: 12 minutes**

---

## 📍 **PART 1: UPDATE ADDRESSES**

### **A. Get Your Wallet Address**

1. Open Petra Wallet
2. Click your account name
3. Click "Copy Address"
4. **Paste it somewhere** - you'll need it!

**Example:** `0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c`

---

### **B. Update .env File**

Open: `c:\Users\crisy\OneDrive\Escritorio\test4\.env`

**Find line 22:**
```env
VITE_MODULE_ADDRESS=0x78be456e78ffec3148be7b55580d91adc963e6affdf5a77672d31e44c0baa84c
```

**Replace with YOUR address:**
```env
VITE_MODULE_ADDRESS=YOUR_WALLET_ADDRESS_HERE
```

**Save file!** (Ctrl+S)

---

### **C. Update Move.toml**

Open: `c:\Users\crisy\OneDrive\Escritorio\test4\move\Move.toml`

**Find line 7:**
```toml
habit = "0x78be456e78ffec3148be7b55580d91adc963e6affdf5a77672d31e44c0baa84c"
```

**Replace with YOUR address:**
```toml
habit = "YOUR_WALLET_ADDRESS_HERE"
```

**Save file!** (Ctrl+S)

---

## 🚀 **PART 2: DEPLOY CONTRACT**

### **A. Get Test APT**

1. **Open:** https://aptoslabs.com/testnet-faucet
2. **Paste:** Your wallet address
3. **Click:** "Faucet" button
4. **Wait:** 10 seconds
5. **Check:** Petra should show ~100 APT

---

### **B. Open PowerShell**

```powershell
cd c:\Users\crisy\OneDrive\Escritorio\test4\move
```

---

### **C. Run These Commands (One by One)**

**Command 1 - Compile:**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move compile
```

**Wait for:**
```
✅ BUILDING HabitPlatform
✅ Success
```

---

**Command 2 - Deploy:**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --assume-yes
```

**Wait for:**
```
✅ "success": true
✅ "vm_status": "Executed successfully"
```

**⚠️ If fails:** Make sure you got test APT from faucet!

---

**Command 3 - Initialize:**

**⚠️ REPLACE `<YOUR_ADDRESS>` WITH YOUR ACTUAL WALLET ADDRESS!**

```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id <YOUR_ADDRESS>::stake_match::initialize --args address:<YOUR_ADDRESS> --assume-yes
```

**Example (if your address is 0x07ca8...):**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id 0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c::stake_match::initialize --args address:0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c --assume-yes
```

**Wait for:**
```
✅ "success": true
```

---

### **D. Verify on Explorer**

**Open this link (replace <YOUR_ADDRESS>):**
```
https://explorer.aptoslabs.com/account/<YOUR_ADDRESS>?network=testnet
```

**Check:**
- ✅ **Modules tab** → See "stake_match"
- ✅ **Resources tab** → See "StakeRegistry"

**If you see both →** ✅ **SUCCESS!**

---

## 📊 **PART 3: CREATE SUPABASE TABLE**

### **A. Open Supabase**

1. Go to: https://supabase.com
2. Open your project
3. Click: **SQL Editor**

---

### **B. Run This SQL**

**Copy ALL of this:**
```sql
DROP TRIGGER IF EXISTS update_stakes_updated_at ON stakes;

CREATE TABLE IF NOT EXISTS stakes (
  id BIGSERIAL PRIMARY KEY,
  staker VARCHAR(66) NOT NULL,
  target VARCHAR(66) NOT NULL,
  amount VARCHAR(20) NOT NULL DEFAULT '0.1',
  status VARCHAR(20) NOT NULL DEFAULT 'pending',
  tx_hash VARCHAR(66),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  CONSTRAINT unique_stake UNIQUE(staker, target)
);

CREATE INDEX IF NOT EXISTS idx_stakes_staker ON stakes(staker);
CREATE INDEX IF NOT EXISTS idx_stakes_target ON stakes(target);
CREATE INDEX IF NOT EXISTS idx_stakes_status ON stakes(status);

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER update_stakes_updated_at 
  BEFORE UPDATE ON stakes 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();
```

**Click:** "Run" button

**Wait for:** ✅ **Success**

---

## 🎮 **PART 4: TEST!**

### **A. Restart Server**

**PowerShell:**
```powershell
cd c:\Users\crisy\OneDrive\Escritorio\test4
npm run dev
```

---

### **B. For NEW Users**

1. **Open:** `http://localhost:3000/dashboard`
2. **Swipe:** Right on any user
3. **Petra:** Opens → Click "Approve"
4. **Result:** ✅ **SUCCESS!**

---

### **C. For OLD Users (with stakes)**

**First, refund old stakes:**
1. **Open:** `http://localhost:3000/manage-stakes`
2. **Click:** "Refund" on each stake
3. **Petra:** Approve each
4. **Wait:** Until all refunded

**Then stake:**
1. **Go to:** Dashboard
2. **Swipe:** Right
3. **Result:** ✅ **SUCCESS!**

---

## ✅ **SUCCESS CHECKLIST**

After following ALL steps:

- [ ] ✅ Updated .env with MY wallet address
- [ ] ✅ Updated Move.toml with MY wallet address
- [ ] ✅ Got test APT from faucet
- [ ] ✅ Compiled contract (aptos move compile)
- [ ] ✅ Deployed contract (aptos move publish)
- [ ] ✅ Initialized contract (aptos move run)
- [ ] ✅ Verified on Aptos Explorer
- [ ] ✅ Created stakes table in Supabase
- [ ] ✅ Restarted dev server
- [ ] ✅ Tested staking successfully

**All checked?** 🎉 **YOU'RE DONE!**

---

## 🚨 **COMMON MISTAKES**

### **❌ MISTAKE 1: Wrong Address**
**Problem:** Used example address instead of YOUR address  
**Fix:** Copy from Petra wallet, paste EVERYWHERE

### **❌ MISTAKE 2: Addresses Don't Match**
**Problem:** .env ≠ Move.toml ≠ Wallet  
**Fix:** All three MUST be identical

### **❌ MISTAKE 3: Skipped Initialization**
**Problem:** Deployed but didn't initialize  
**Fix:** Run initialization command (Step 2C Command 3)

### **❌ MISTAKE 4: No Test APT**
**Problem:** Deployment fails  
**Fix:** Get APT from faucet FIRST

### **❌ MISTAKE 5: Didn't Restart Server**
**Problem:** Old config cached  
**Fix:** Ctrl+C → npm run dev

---

## 📊 **VISUAL FLOW**

```
1. YOUR WALLET ADDRESS
   ↓
2. UPDATE .env
   ↓
3. UPDATE Move.toml
   ↓
4. GET TEST APT
   ↓
5. COMPILE CONTRACT
   ↓
6. DEPLOY CONTRACT (to YOUR address)
   ↓
7. INITIALIZE CONTRACT
   ↓
8. VERIFY ON EXPLORER
   ↓
9. CREATE SUPABASE TABLE
   ↓
10. RESTART SERVER
   ↓
11. TEST STAKING
   ↓
12. ✅ SUCCESS!
```

---

## 🎯 **KEY POINTS**

1. **MODULE_ADDRESS MUST BE YOUR WALLET**
   - Not example address
   - Not random address
   - YOUR actual Petra wallet address

2. **ALL ADDRESSES MUST MATCH**
   - .env file
   - Move.toml file
   - Deployment command
   - Initialization command

3. **DEPLOY BEFORE TEST**
   - Can't skip deployment
   - Can't use old deployment
   - Must deploy to YOUR address

4. **INITIALIZE AFTER DEPLOY**
   - Deployment alone isn't enough
   - Must initialize the registry
   - Use YOUR address in command

---

## ⚡ **QUICK COPY-PASTE**

**Your Address (example):**
```
0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c
```

**For .env:**
```
VITE_MODULE_ADDRESS=0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c
```

**For Move.toml:**
```
habit = "0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c"
```

**For initialization (replace address):**
```
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id 0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c::stake_match::initialize --args address:0x07ca8dd87a0b5bd0d07fda3b3c0b58de4ed8a6bb1f78e3a6c7b09b1d2e4f301c --assume-yes
```

---

## 🎊 **YOU'RE READY!**

**Time to fix: 12 minutes**  
**Difficulty: Easy (just follow steps)**  
**Result: Fully working dApp!** 🚀

---

## 📞 **NEED MORE HELP?**

**Read detailed guides:**
- `CRITICAL_FIX_GUIDE.md` - Step-by-step with explanations
- `COMPLETE_SOLUTION_FINAL.md` - Full technical overview
- `PRODUCTION_READY_SOLUTION.md` - Deep dive

---

**START NOW!** ⚡

**STEP 1: Open Petra wallet and copy your address!**
