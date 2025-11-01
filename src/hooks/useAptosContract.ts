import { useState } from 'react';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { toast } from 'react-hot-toast';
import {
  aptosClient,
  MODULE_ADDRESS,
  FUNCTIONS,
  normalizeAddress,
  getErrorMessage,
  TX_OPTIONS,
  MODULE_ID,
  STAKE_AMOUNT,
} from '../config/aptos';
import { InputTransactionData } from '@aptos-labs/wallet-adapter-core';
import { isContractReady } from '../utils/contractDiagnostics';

/**
 * Hook for staking to connect with another user
 */
export const useStakeToConnect = () => {
  const { account, signAndSubmitTransaction } = useWallet();
  const [loading, setLoading] = useState(false);

  const stakeToConnect = async (targetAddress: string) => {
    if (!account) {
      toast.error('Please connect your wallet');
      return null;
    }

    setLoading(true);
    try {
      // CRITICAL: Verify contract is ready before proceeding
      const contractReady = await isContractReady();
      if (!contractReady) {
        toast.error(
          'Smart contract not found or not initialized. Check console and run diagnostics.',
          { duration: 8000 }
        );
        console.error('❌ Contract not ready at address:', MODULE_ADDRESS);
        console.error('💡 Solution: Follow CRITICAL_FIX_GUIDE.md to deploy contract');
        return null;
      }

      const normalizedTarget = normalizeAddress(targetAddress);

      // PRE-CHECK 1: Check if stake already exists in Supabase AND blockchain
      try {
        const { supabase, TABLES } = await import('../config/supabase');
        const { normalizeAptosAddress } = await import('../utils/helpers');
        
        const normalizedStaker = normalizeAptosAddress(account.address);
        const normalizedTargetForDB = normalizeAptosAddress(targetAddress);
        
        // Check Supabase
        const { data: existingStake } = await supabase
          .from(TABLES.STAKES)
          .select('*')
          .eq('staker', normalizedStaker)
          .eq('target', normalizedTargetForDB)
          .maybeSingle();

        if (existingStake) {
          if (existingStake.status === 'pending') {
            toast.error(
              'You already sent a request to this user. Check your Requests page or go to Manage Stakes to refund.',
              { duration: 8000 }
            );
            return null;
          } else if (existingStake.status === 'matched') {
            toast.error('You are already matched with this user. Check your Chats.');
            return null;
          }
        }

        // Also check blockchain directly
        try {
          const resources = await aptosClient.getAccountResources({
            accountAddress: MODULE_ADDRESS,
          });
          
          const registryResource = resources.find(
            (r) => r.type === `${MODULE_ID}::StakeRegistry`
          );

          if (registryResource && registryResource.data) {
            const stakes = (registryResource.data as any).stakes || [];
            const onChainStake = stakes.find(
              (s: any) => 
                normalizeAddress(s.staker) === normalizeAddress(account.address) &&
                normalizeAddress(s.target) === normalizeAddress(targetAddress)
            );

            if (onChainStake) {
              toast.error(
                'You have an existing stake on-chain. Go to Manage Stakes to refund it first.',
                { duration: 8000 }
              );
              return null;
            }
          }
        } catch (blockchainCheckError) {
          console.warn('Could not check blockchain stakes:', blockchainCheckError);
          // Continue - transaction will fail if stake exists
        }
      } catch (checkError) {
        console.warn('Could not check existing stakes:', checkError);
        // Continue anyway - let blockchain check
      }

      const payload: InputTransactionData = {
        data: {
          function: FUNCTIONS.STAKE_TO_CONNECT as `${string}::${string}::${string}`,
          typeArguments: [],
          functionArguments: [normalizedTarget, MODULE_ADDRESS],
        },
      };

      const response = await signAndSubmitTransaction(payload);
      
      // Wait for transaction confirmation
      const txn = await aptosClient.waitForTransaction({
        transactionHash: response.hash,
      });

      if (txn.success) {
        toast.success('Stake successful! 🎉');
        
        // Record stake in Supabase and check for match
        try {
          const { supabase, TABLES } = await import('../config/supabase');
          const { normalizeAptosAddress } = await import('../utils/helpers');
          
          const normalizedStaker = normalizeAptosAddress(account.address);
          const normalizedTargetForDB = normalizeAptosAddress(targetAddress);
          
          // Record the stake
          const { data: insertedStake, error: insertError } = await supabase
            .from(TABLES.STAKES)
            .insert({
              staker: normalizedStaker,
              target: normalizedTargetForDB,
              amount: '0.1',
              status: 'pending',
              tx_hash: response.hash,
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
            })
            .select()
            .single();

          if (insertError) {
            console.error('Failed to record stake in database:', insertError);
            toast.error('Request sent, but database sync failed. Please refresh the page.', {
              duration: 6000,
            });
            return response.hash;
          }

          // Check if target has also staked on us (mutual stake = match)
          const { data: reverseStake } = await supabase
            .from(TABLES.STAKES)
            .select('*')
            .eq('staker', normalizedTargetForDB)
            .eq('target', normalizedStaker)
            .eq('status', 'pending')
            .maybeSingle();

          if (reverseStake) {
            // Both users have staked - create match!
            const [addr1, addr2] = [normalizedStaker, normalizedTargetForDB].sort();
            const chatRoomId = `${addr1}_${addr2}`;

            // Update both stakes to matched
            await supabase
              .from(TABLES.STAKES)
              .update({ status: 'matched' })
              .in('id', [reverseStake.id]);
              
            await supabase
              .from(TABLES.STAKES)
              .update({ status: 'matched' })
              .eq('staker', normalizedStaker)
              .eq('target', normalizedTargetForDB);

            // Create match
            await supabase.from(TABLES.MATCHES).insert({
              user_a: addr1,
              user_b: addr2,
              matched_at: new Date().toISOString(),
              chat_room_id: chatRoomId,
            });

            toast.success('🎉 It\'s a match! You can now chat!', { duration: 5000 });
          }
        } catch (dbError) {
          console.error('Error recording stake in DB:', dbError);
          // Don't fail the whole operation if DB fails
        }
        
        return response.hash;
      } else {
        toast.error('Transaction failed');
        return null;
      }
    } catch (error: any) {
      console.error('❌ Error staking:', error);
      console.error('Full error object:', JSON.stringify(error, null, 2));
      
      // Comprehensive error handling
      if (error.message?.includes('User rejected') || error.message?.includes('rejected the request')) {
        toast.error('Transaction rejected by user');
      } else if (error.message?.includes('Module not found') || 
                 error.message?.includes('module') || 
                 error.message?.includes('LINKER_ERROR')) {
        toast.error(
          '🚨 CRITICAL: Smart contract not deployed! Open CRITICAL_FIX_GUIDE.md and follow deployment steps.',
          { duration: 12000 }
        );
        console.error('\n🚨 CRITICAL ERROR: Module not found');
        console.error('📝 Solution: Follow CRITICAL_FIX_GUIDE.md to deploy contract');
        console.error(`📍 Current MODULE_ADDRESS: ${MODULE_ADDRESS}`);
        console.error('💡 Tip: Make sure MODULE_ADDRESS in .env matches your wallet address\n');
      } else if (error.message?.includes('E_NOT_INITIALIZED') || error.message?.includes('0x1')) {
        toast.error(
          'Contract not initialized. Click "Initialize Contract" button or follow CRITICAL_FIX_GUIDE.md.',
          { duration: 10000 }
        );
      } else if (error.message?.includes('E_STAKE_ALREADY_EXISTS') || error.message?.includes('0x4')) {
        toast.error(
          'You have an old stake on-chain. Go to /manage-stakes to refund it first.',
          { duration: 10000 }
        );
      } else if (error.transaction?.vm_status?.includes('ABORTED')) {
        const abortCode = parseInt(error.transaction.vm_status.match(/\d+/)?.[0] || '0');
        if (abortCode === 1) {
          toast.error(
            'Contract not initialized. Follow CRITICAL_FIX_GUIDE.md Step 4.',
            { duration: 10000 }
          );
        } else if (abortCode === 4) {
          toast.error(
            'Old stake exists. Go to /manage-stakes to refund.',
            { duration: 10000 }
          );
        } else {
          toast.error(getErrorMessage(abortCode));
        }
      } else if (error.message?.includes('INSUFFICIENT_BALANCE') || error.message?.includes('0x5')) {
        toast.error(
          'Insufficient APT balance. Get test APT from https://aptoslabs.com/testnet-faucet',
          { duration: 8000 }
        );
      } else {
        toast.error(error.message || 'Failed to stake. Check console for details.');
      }
      
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { stakeToConnect, loading };
};

/**
 * Hook for refunding expired stake
 */
export const useRefundStake = () => {
  const { account, signAndSubmitTransaction } = useWallet();
  const [loading, setLoading] = useState(false);

  const refundStake = async (targetAddress: string) => {
    if (!account) {
      toast.error('Please connect your wallet');
      return null;
    }

    setLoading(true);
    try {
      const normalizedTarget = normalizeAddress(targetAddress);

      const payload: InputTransactionData = {
        data: {
          function: FUNCTIONS.REFUND_EXPIRED_STAKE as `${string}::${string}::${string}`,
          typeArguments: [],
          functionArguments: [normalizedTarget, MODULE_ADDRESS],
        },
      };

      const response = await signAndSubmitTransaction(payload);
      
      const txn = await aptosClient.waitForTransaction({
        transactionHash: response.hash,
      });

      if (txn.success) {
        toast.success('Stake refunded! 💰');
        return response.hash;
      } else {
        toast.error('Transaction failed');
        return null;
      }
    } catch (error: any) {
      console.error('Error refunding:', error);
      
      if (error.transaction?.vm_status?.includes('ABORTED')) {
        const abortCode = parseInt(error.transaction.vm_status.match(/\d+/)?.[0] || '0');
        toast.error(getErrorMessage(abortCode));
      } else {
        toast.error(error.message || 'Failed to refund');
      }
      
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { refundStake, loading };
};

/**
 * Hook for releasing matched stakes
 */
export const useReleaseStake = () => {
  const { account, signAndSubmitTransaction } = useWallet();
  const [loading, setLoading] = useState(false);

  const releaseStake = async (otherUserAddress: string) => {
    if (!account) {
      toast.error('Please connect your wallet');
      return null;
    }

    setLoading(true);
    try {
      const normalizedOther = normalizeAddress(otherUserAddress);

      const payload: InputTransactionData = {
        data: {
          function: FUNCTIONS.RELEASE_STAKE as `${string}::${string}::${string}`,
          typeArguments: [],
          functionArguments: [normalizedOther, MODULE_ADDRESS],
        },
      };

      const response = await signAndSubmitTransaction(payload);
      
      const txn = await aptosClient.waitForTransaction({
        transactionHash: response.hash,
      });

      if (txn.success) {
        toast.success('Stakes released! 🎉');
        return response.hash;
      } else {
        toast.error('Transaction failed');
        return null;
      }
    } catch (error: any) {
      console.error('Error releasing:', error);
      
      if (error.transaction?.vm_status?.includes('ABORTED')) {
        const abortCode = parseInt(error.transaction.vm_status.match(/\d+/)?.[0] || '0');
        toast.error(getErrorMessage(abortCode));
      } else {
        toast.error(error.message || 'Failed to release stakes');
      }
      
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { releaseStake, loading };
};

/**
 * Hook to check stake status
 */
export const useStakeStatus = () => {
  const [loading, setLoading] = useState(false);

  const getStakeStatus = async (
    stakerAddress: string,
    targetAddress: string
  ): Promise<{
    pending: boolean;
    matched: boolean;
    refunded: boolean;
    released: boolean;
  } | null> => {
    setLoading(true);
    try {
      const normalizedStaker = normalizeAddress(stakerAddress);
      const normalizedTarget = normalizeAddress(targetAddress);

      const result = await aptosClient.view({
        payload: {
          function: FUNCTIONS.GET_STAKE_STATUS as `${string}::${string}::${string}`,
          typeArguments: [],
          functionArguments: [MODULE_ADDRESS, normalizedStaker, normalizedTarget],
        },
      });

      return {
        pending: result[0] as boolean,
        matched: result[1] as boolean,
        refunded: result[2] as boolean,
        released: result[3] as boolean,
      };
    } catch (error) {
      console.error('Error fetching stake status:', error);
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { getStakeStatus, loading };
};

/**
 * Hook to check if two users are matched
 */
export const useIsMatched = () => {
  const [loading, setLoading] = useState(false);

  const isMatched = async (
    userA: string,
    userB: string
  ): Promise<boolean> => {
    setLoading(true);
    try {
      const normalizedA = normalizeAddress(userA);
      const normalizedB = normalizeAddress(userB);

      const result = await aptosClient.view({
        payload: {
          function: FUNCTIONS.IS_MATCHED as `${string}::${string}::${string}`,
          typeArguments: [],
          functionArguments: [MODULE_ADDRESS, normalizedA, normalizedB],
        },
      });

      return result[0] as boolean;
    } catch (error) {
      console.error('Error checking match status:', error);
      return false;
    } finally {
      setLoading(false);
    }
  };

  return { isMatched, loading };
};

/**
 * Hook to get user's APT balance
 */
export const useAptBalance = () => {
  const { account } = useWallet();
  const [balance, setBalance] = useState<string>('0');
  const [loading, setLoading] = useState(false);

  const fetchBalance = async () => {
    if (!account) return;

    setLoading(true);
    try {
      const resources = await aptosClient.getAccountCoinAmount({
        accountAddress: account.address,
        coinType: '0x1::aptos_coin::AptosCoin',
      });

      // Convert from Octas to APT
      const aptAmount = Number(resources) / 100_000_000;
      setBalance(aptAmount.toFixed(2));
    } catch (error) {
      console.error('Error fetching balance:', error);
      setBalance('0');
    } finally {
      setLoading(false);
    }
  };

  return { balance, fetchBalance, loading };
};

/**
 * Hook to get stake amount (for display)
 */
export const useStakeAmount = () => {
  return {
    stakeAmount: Number(STAKE_AMOUNT) / 100_000_000, // Convert to APT
    stakeAmountFormatted: `${Number(STAKE_AMOUNT) / 100_000_000} APT`,
  };
};
