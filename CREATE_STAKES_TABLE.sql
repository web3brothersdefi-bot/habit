-- ============================================
-- STAKES TABLE SETUP - ERROR-FREE VERSION
-- ============================================

-- Drop existing trigger if it exists (fixes the error)
DROP TRIGGER IF EXISTS update_stakes_updated_at ON stakes;

-- Create stakes table (with IF NOT EXISTS)
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

-- Create indexes (with IF NOT EXISTS)
CREATE INDEX IF NOT EXISTS idx_stakes_staker ON stakes(staker);
CREATE INDEX IF NOT EXISTS idx_stakes_target ON stakes(target);
CREATE INDEX IF NOT EXISTS idx_stakes_status ON stakes(status);

-- Create or replace the trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

-- Create the trigger (after dropping old one above)
CREATE TRIGGER update_stakes_updated_at 
  BEFORE UPDATE ON stakes 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Add helpful comments
COMMENT ON TABLE stakes IS 'Tracks stake-based connection requests between users';
COMMENT ON COLUMN stakes.staker IS 'Wallet address of user who staked (normalized to 66 chars)';
COMMENT ON COLUMN stakes.target IS 'Wallet address of target user (normalized to 66 chars)';
COMMENT ON COLUMN stakes.amount IS 'Amount staked in APT';
COMMENT ON COLUMN stakes.status IS 'pending | matched | refunded | released';
COMMENT ON COLUMN stakes.tx_hash IS 'Aptos transaction hash';

-- Success message
DO $$ 
BEGIN 
  RAISE NOTICE 'Stakes table setup complete! ✅';
END $$;
