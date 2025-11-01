# 📊 DATABASE SETUP FOR REQUESTS FEATURE

## ⚠️ **REQUIRED: Add Stakes Table to Supabase**

The Requests feature requires a `stakes` table in Supabase to track connection requests.

---

## 🗄️ **CREATE STAKES TABLE**

### **Option 1: Supabase Dashboard (Easiest)**

1. **Go to Supabase Dashboard:**
   ```
   https://app.supabase.com
   ```

2. **Select your project**

3. **Go to SQL Editor** (left sidebar)

4. **Click "New Query"**

5. **Paste this SQL:**

```sql
-- Create stakes table
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

-- Create index for faster queries
CREATE INDEX IF NOT EXISTS idx_stakes_staker ON stakes(staker);
CREATE INDEX IF NOT EXISTS idx_stakes_target ON stakes(target);
CREATE INDEX IF NOT EXISTS idx_stakes_status ON stakes(status);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_stakes_updated_at 
  BEFORE UPDATE ON stakes 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Add comments
COMMENT ON TABLE stakes IS 'Tracks stake-based connection requests between users';
COMMENT ON COLUMN stakes.staker IS 'Wallet address of user who staked (normalized to 66 chars)';
COMMENT ON COLUMN stakes.target IS 'Wallet address of target user (normalized to 66 chars)';
COMMENT ON COLUMN stakes.amount IS 'Amount staked in APT';
COMMENT ON COLUMN stakes.status IS 'pending | matched | refunded | released';
COMMENT ON COLUMN stakes.tx_hash IS 'Aptos transaction hash';
```

6. **Click "Run"**

7. **Verify:**
   - Go to "Table Editor"
   - You should see `stakes` table
   - Check columns match above

---

### **Option 2: Supabase CLI**

```bash
# Install Supabase CLI (if not installed)
npm install -g supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Create migration file
supabase migration new create_stakes_table

# Edit the migration file with the SQL above

# Apply migration
supabase db push
```

---

## 📋 **TABLE SCHEMA**

### **Columns:**

| Column | Type | Description | Required |
|--------|------|-------------|----------|
| `id` | BIGSERIAL | Primary key | Auto |
| `staker` | VARCHAR(66) | User who sent request | Yes |
| `target` | VARCHAR(66) | User receiving request | Yes |
| `amount` | VARCHAR(20) | Stake amount (0.1 APT) | Yes |
| `status` | VARCHAR(20) | Request status | Yes |
| `tx_hash` | VARCHAR(66) | Transaction hash | No |
| `created_at` | TIMESTAMP | When created | Auto |
| `updated_at` | TIMESTAMP | When updated | Auto |

### **Constraints:**

- `UNIQUE(staker, target)` - Prevents duplicate requests
- `NOT NULL` on staker, target, amount, status

### **Indexes:**

- `idx_stakes_staker` - Fast lookup by staker
- `idx_stakes_target` - Fast lookup by target
- `idx_stakes_status` - Fast filtering by status

### **Status Values:**

- `pending` - Request sent, waiting for response
- `matched` - Both users staked, match created
- `refunded` - Stake refunded (expired/cancelled)
- `released` - Stake released after successful chat

---

## ✅ **VERIFY TABLE**

### **Check Table Exists:**

```sql
SELECT * FROM stakes LIMIT 1;
```

**Expected:** Empty result or 1 row (if data exists)

---

### **Check Indexes:**

```sql
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'stakes';
```

**Expected:** 3 indexes listed

---

### **Test Insert:**

```sql
INSERT INTO stakes (staker, target, amount, status)
VALUES (
  '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef',
  '0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321',
  '0.1',
  'pending'
)
RETURNING *;
```

**Expected:** New row returned with auto-generated `id` and timestamps

---

### **Test Query:**

```sql
-- Get pending stakes for a user
SELECT * FROM stakes 
WHERE target = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef'
AND status = 'pending';
```

**Expected:** Returns the test row

---

### **Clean Up Test:**

```sql
DELETE FROM stakes 
WHERE staker = '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
```

---

## 🔐 **ROW LEVEL SECURITY (RLS)**

### **Enable RLS (Recommended):**

```sql
-- Enable RLS on stakes table
ALTER TABLE stakes ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read their own stakes
CREATE POLICY "Users can view own stakes"
ON stakes FOR SELECT
USING (
  staker = current_setting('request.jwt.claims', true)::json->>'wallet_address'
  OR target = current_setting('request.jwt.claims', true)::json->>'wallet_address'
);

-- Policy: Users can insert stakes where they are the staker
CREATE POLICY "Users can create stakes"
ON stakes FOR INSERT
WITH CHECK (
  staker = current_setting('request.jwt.claims', true)::json->>'wallet_address'
);

-- Policy: Users can update their own stakes
CREATE POLICY "Users can update own stakes"
ON stakes FOR UPDATE
USING (
  staker = current_setting('request.jwt.claims', true)::json->>'wallet_address'
);
```

**Note:** Adjust JWT claims based on your Supabase auth setup.

---

## 🔗 **FOREIGN KEY CONSTRAINTS (Optional)**

If you want referential integrity:

```sql
-- Add foreign key to users table
ALTER TABLE stakes
ADD CONSTRAINT fk_stakes_staker
FOREIGN KEY (staker) REFERENCES users(wallet_address)
ON DELETE CASCADE;

ALTER TABLE stakes
ADD CONSTRAINT fk_stakes_target
FOREIGN KEY (target) REFERENCES users(wallet_address)
ON DELETE CASCADE;
```

**Note:** Only add if you want automatic deletion when users are deleted.

---

## 📊 **SAMPLE QUERIES**

### **Get incoming requests:**

```sql
SELECT s.*, u.name, u.bio, u.profile_image, u.role, u.skills
FROM stakes s
JOIN users u ON s.staker = u.wallet_address
WHERE s.target = 'YOUR_WALLET_ADDRESS'
AND s.status = 'pending'
ORDER BY s.created_at DESC;
```

---

### **Get outgoing requests:**

```sql
SELECT s.*, u.name, u.bio, u.profile_image, u.role, u.skills
FROM stakes s
JOIN users u ON s.target = u.wallet_address
WHERE s.staker = 'YOUR_WALLET_ADDRESS'
AND s.status = 'pending'
ORDER BY s.created_at DESC;
```

---

### **Check for mutual stake:**

```sql
SELECT 
  a.id as stake_a_id,
  b.id as stake_b_id
FROM stakes a
JOIN stakes b 
  ON a.staker = b.target 
  AND a.target = b.staker
WHERE a.staker = 'USER_A_ADDRESS'
  AND a.target = 'USER_B_ADDRESS'
  AND a.status = 'pending'
  AND b.status = 'pending';
```

Returns rows if both users have staked on each other.

---

### **Get match statistics:**

```sql
SELECT 
  COUNT(*) FILTER (WHERE status = 'pending') as pending_requests,
  COUNT(*) FILTER (WHERE status = 'matched') as total_matches,
  COUNT(*) FILTER (WHERE status = 'refunded') as refunds,
  COUNT(*) FILTER (WHERE status = 'released') as releases
FROM stakes
WHERE staker = 'YOUR_WALLET_ADDRESS' 
   OR target = 'YOUR_WALLET_ADDRESS';
```

---

## 🧪 **TEST DATA**

### **Insert test requests:**

```sql
-- User A stakes on User B
INSERT INTO stakes (staker, target, amount, status, tx_hash)
VALUES (
  '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  '0.1',
  'pending',
  '0x1234567890abcdef'
);

-- User C stakes on User A
INSERT INTO stakes (staker, target, amount, status, tx_hash)
VALUES (
  '0xcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
  '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  '0.1',
  'pending',
  '0xfedcba0987654321'
);

-- User B stakes back on User A (creates match)
INSERT INTO stakes (staker, target, amount, status, tx_hash)
VALUES (
  '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
  '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  '0.1',
  'pending',
  '0xabcdef1234567890'
);
```

Now User A has:
- 1 outgoing request to User B
- 1 incoming request from User C
- Mutual stake with User B (ready to match)

---

## 🔄 **MIGRATION FROM EXISTING SYSTEM**

If you already have a stakes system:

```sql
-- Backup old table
CREATE TABLE stakes_backup AS SELECT * FROM stakes;

-- Drop old table
DROP TABLE stakes;

-- Create new table with schema above
-- ... (run CREATE TABLE from top)

-- Migrate data
INSERT INTO stakes (staker, target, amount, status, tx_hash, created_at)
SELECT 
  staker,
  target,
  amount,
  status,
  tx_hash,
  created_at
FROM stakes_backup;

-- Verify
SELECT COUNT(*) FROM stakes;
SELECT COUNT(*) FROM stakes_backup;
-- Should match
```

---

## ✅ **SETUP COMPLETE CHECKLIST**

- [ ] Stakes table created
- [ ] All columns present
- [ ] Indexes created
- [ ] Constraints applied
- [ ] Test insert works
- [ ] Test queries work
- [ ] RLS enabled (optional)
- [ ] Foreign keys added (optional)
- [ ] Sample data inserted (optional)
- [ ] Migration verified (if upgrading)

---

## 🚨 **TROUBLESHOOTING**

### **Error: "relation stakes does not exist"**
**Solution:** Run CREATE TABLE SQL above

### **Error: "duplicate key value"**
**Solution:** UNIQUE constraint on (staker, target) - don't insert duplicates

### **Error: "column does not exist"**
**Solution:** Check column names match schema exactly

### **Error: "permission denied"**
**Solution:** 
1. Check RLS policies
2. Temporarily disable RLS for testing
3. Verify user has correct permissions

---

## 📞 **NEED HELP?**

**Supabase Docs:**
```
https://supabase.com/docs/guides/database
```

**SQL Reference:**
```
https://www.postgresql.org/docs/
```

**Discord:**
```
https://discord.supabase.com
```

---

**ONCE TABLE IS CREATED, REQUESTS FEATURE WILL WORK!** ✅

**Estimated setup time: 5 minutes** ⚡
