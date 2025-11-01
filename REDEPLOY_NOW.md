# ⚡ REDEPLOY NOW - Correct Commands

## ✅ **WHAT WAS FIXED**

I've updated both configuration files to YOUR correct wallet address:

**Your Wallet:** `0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c`

**Files Updated:**
- ✅ `move/Move.toml` line 7 → Your address
- ✅ `.env` line 22 → Your address

---

## 🚀 **REDEPLOY COMMANDS (Copy-Paste)**

**Open PowerShell and run these commands ONE BY ONE:**

### **Command 1: Navigate to move folder**
```powershell
cd C:\Users\crisy\OneDrive\Escritorio\test4\move
```

---

### **Command 2: Clean build**
```powershell
Remove-Item -Path build -Recurse -Force -ErrorAction SilentlyContinue
```

---

### **Command 3: Compile**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move compile
```

**Expected output:**
```
✅ BUILDING HabitPlatform
✅ Result: ["7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c::stake_match"]
```

**⚠️ IMPORTANT:** Check that the address starts with `7ca90e...` (YOUR address)!

---

### **Command 4: Deploy (with proper gas)**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 20000 --assume-yes
```

**Expected output:**
```
✅ "success": true
✅ "vm_status": "Executed successfully"
```

---

### **Command 5: Initialize (with proper gas)**
```powershell
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id 0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c::stake_match::initialize --args address:0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c --max-gas 20000 --assume-yes
```

**Expected output:**
```
✅ "success": true
✅ "vm_status": "Executed successfully"
```

---

### **Command 6: Verify on Explorer**

**Open this link in browser:**
```
https://explorer.aptoslabs.com/account/0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c?network=testnet
```

**Check:**
- ✅ **Modules tab** → See "stake_match" module
- ✅ **Resources tab** → See "0x7ca90e...::stake_match::StakeRegistry"

---

## 🔍 **UNDERSTANDING THE FIX**

### **Why It Failed Before:**

**Line-by-line analysis:**

1. **Move.toml line 7 had:**
   ```toml
   habit = "0x78be456e78ffec3148be7b55580d91adc963e6affdf5a77672d31e44c0baa84c"
   ```
   ❌ Old/example address

2. **When you ran publish:**
   - Compiler used address from Move.toml
   - Deployed to `78be456e...` (wrong address)
   - Output showed: `"78be456e...::stake_match"`

3. **When you ran initialize:**
   - You used YOUR address `7ca90e...`
   - But contract was at `78be456e...`
   - Address mismatch → Module not found!

4. **Gas issue:**
   - Default gas too low for initialization
   - Need `--max-gas 20000` flag

### **What's Fixed:**

1. ✅ **Move.toml updated** → YOUR address
2. ✅ **.env updated** → YOUR address  
3. ✅ **Gas flags added** → `--max-gas 20000`
4. ✅ **Now deploys to correct address!**

---

## ✅ **SUCCESS CRITERIA**

**You'll know it worked when:**

1. ✅ Compile shows: `7ca90e5eea844329...::stake_match`
2. ✅ Publish succeeds with "success": true
3. ✅ Initialize succeeds with "success": true
4. ✅ Explorer shows your modules
5. ✅ Explorer shows StakeRegistry resource

---

## 📋 **COMPLETE COMMAND SEQUENCE**

**Copy all of these and run in PowerShell:**

```powershell
# Navigate
cd C:\Users\crisy\OneDrive\Escritorio\test4\move

# Clean
Remove-Item -Path build -Recurse -Force -ErrorAction SilentlyContinue

# Compile
C:\Users\Acer\.aptoscli\bin\aptos.exe move compile

# Deploy with proper gas
C:\Users\Acer\.aptoscli\bin\aptos.exe move publish --max-gas 20000 --assume-yes

# Initialize with proper gas
C:\Users\Acer\.aptoscli\bin\aptos.exe move run --function-id 0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c::stake_match::initialize --args address:0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c --max-gas 20000 --assume-yes

# Go back to root
cd ..
```

---

## 🎯 **AFTER DEPLOYMENT**

### **Create Supabase Stakes Table:**

1. Open Supabase → SQL Editor
2. Run this SQL:

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

---

### **Start Dev Server:**

```powershell
npm run dev
```

---

### **Test Staking:**

1. Open: `http://localhost:3000/dashboard`
2. Swipe right on any user
3. Petra opens → Approve
4. **SUCCESS!** ✅

---

## 🚨 **IF YOU GET ERRORS**

### **Error: "Insufficient balance"**
**Solution:** Get more test APT
```
https://aptoslabs.com/testnet-faucet
Paste: 0x7ca90e5eea844329aa5792d04d1844d0b7af09d18fabc8a2721be73ec3b3301c
Click: Faucet
```

### **Error: "Module already exists"**
**Solution:** This is OK! It means the old module exists. The new one will override it.

### **Error: "Account sequence number mismatch"**
**Solution:** Wait 10 seconds and try again

### **Error: Still shows "78be456e..."**
**Solution:** 
1. Verify Move.toml line 7 = `7ca90e...`
2. Delete build folder
3. Compile again
4. Check compile output for correct address

---

## 📊 **VERIFICATION CHECKLIST**

After running all commands:

- [ ] ✅ Compile output shows `7ca90e5eea844329...::stake_match`
- [ ] ✅ Publish succeeded
- [ ] ✅ Initialize succeeded
- [ ] ✅ Explorer shows modules
- [ ] ✅ Explorer shows StakeRegistry
- [ ] ✅ Supabase table created
- [ ] ✅ Dev server running
- [ ] ✅ Staking works on dashboard

**All checked?** 🎉 **YOU'RE DONE!**

---

## 🎊 **YOU'RE READY!**

**Time to complete:** 5 minutes  
**Commands:** 5 total  
**Result:** Fully working dApp! 🚀

---

**START NOW: Copy Command 1 and paste in PowerShell!** ⚡
