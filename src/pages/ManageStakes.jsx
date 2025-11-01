import React, { useState, useEffect } from 'react';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { motion } from 'framer-motion';
import { RefreshCw, Trash2, AlertCircle, CheckCircle, Clock } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Button from '../components/Button';
import { aptosClient, MODULE_ADDRESS, FUNCTIONS } from '../config/aptos';
import { normalizeAddress } from '../config/aptos';
import { toast } from 'react-hot-toast';

const ManageStakes = () => {
  const { account, signAndSubmitTransaction } = useWallet();
  const [stakes, setStakes] = useState([]);
  const [loading, setLoading] = useState(false);
  const [refunding, setRefunding] = useState(null);

  const fetchOnChainStakes = async () => {
    if (!account) return;
    
    setLoading(true);
    try {
      // This is a workaround - we'll check the registry directly
      const registryAddress = MODULE_ADDRESS;
      
      // Get all account resources to find stakes
      const resources = await aptosClient.getAccountResources({
        accountAddress: registryAddress,
      });

      const registryResource = resources.find(
        (r) => r.type === `${MODULE_ADDRESS}::stake_match::StakeRegistry`
      );

      if (registryResource && registryResource.data) {
        const allStakes = registryResource.data.stakes || [];
        
        // Filter stakes where current user is the staker
        const myStakes = allStakes.filter(
          (stake) => normalizeAddress(stake.staker) === normalizeAddress(account.address)
        );

        setStakes(myStakes);
        
        if (myStakes.length === 0) {
          toast.success('No pending stakes found! You can stake freely.');
        }
      }
    } catch (error) {
      console.error('Error fetching stakes:', error);
      toast.error('Failed to fetch stakes from blockchain');
    } finally {
      setLoading(false);
    }
  };

  const refundStake = async (targetAddress) => {
    if (!account) return;

    setRefunding(targetAddress);
    try {
      const normalizedTarget = normalizeAddress(targetAddress);

      const payload = {
        data: {
          function: FUNCTIONS.REFUND_EXPIRED_STAKE,
          typeArguments: [],
          functionArguments: [normalizedTarget, MODULE_ADDRESS],
        },
      };

      const response = await signAndSubmitTransaction(payload);
      
      const txn = await aptosClient.waitForTransaction({
        transactionHash: response.hash,
      });

      if (txn.success) {
        toast.success('Stake refunded! 💰 You can now stake again.');
        // Refresh stakes list
        setTimeout(() => {
          fetchOnChainStakes();
        }, 1000);
      } else {
        toast.error('Refund failed');
      }
    } catch (error) {
      console.error('Refund error:', error);
      
      if (error.message?.includes('E_REFUND_PERIOD_NOT_ELAPSED')) {
        toast.error('Must wait 2 days before refunding. Try clearing stale stakes instead.');
      } else {
        toast.error(error.message || 'Failed to refund');
      }
    } finally {
      setRefunding(null);
    }
  };

  const clearAllStaleStakes = async () => {
    if (!account || stakes.length === 0) return;

    setLoading(true);
    let successCount = 0;
    
    for (const stake of stakes) {
      try {
        await refundStake(stake.target);
        successCount++;
        await new Promise(resolve => setTimeout(resolve, 2000)); // Wait between refunds
      } catch (error) {
        console.error('Failed to refund stake:', stake.target, error);
      }
    }

    if (successCount > 0) {
      toast.success(`Cleared ${successCount} stale stake(s)!`);
    }
    
    setLoading(false);
  };

  useEffect(() => {
    if (account) {
      fetchOnChainStakes();
    }
  }, [account]);

  if (!account) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <Card className="p-8 text-center">
            <AlertCircle className="w-16 h-16 text-yellow-400 mx-auto mb-4" />
            <h2 className="text-xl font-bold mb-2">Wallet Not Connected</h2>
            <p className="text-gray-400">Please connect your wallet to manage stakes</p>
          </Card>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
        >
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-primary to-purple-400 bg-clip-text text-transparent">
                Manage Stakes
              </h1>
              <p className="text-sm text-gray-400 mt-1">
                View and refund your on-chain stakes
              </p>
            </div>
            <Button
              onClick={fetchOnChainStakes}
              disabled={loading}
              variant="secondary"
            >
              <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
          </div>
        </motion.div>

        {/* Info Card */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
        >
          <Card className="p-4 bg-blue-500/10 border-blue-500/30">
            <div className="flex items-start gap-3">
              <AlertCircle className="w-5 h-5 text-blue-400 flex-shrink-0 mt-0.5" />
              <div className="flex-1">
                <h3 className="font-semibold text-blue-400 mb-1">Why This Page?</h3>
                <p className="text-sm text-gray-400">
                  If you get "E_STAKE_ALREADY_EXISTS" errors, you have old test stakes on-chain. 
                  Refund them here (after 2 days) to stake again freely.
                </p>
              </div>
            </div>
          </Card>
        </motion.div>

        {/* Stakes List */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
        >
          {loading ? (
            <Card className="p-12 text-center">
              <div className="flex justify-center mb-4">
                <div className="w-12 h-12 border-4 border-primary/30 border-t-primary rounded-full animate-spin" />
              </div>
              <p className="text-gray-400">Checking blockchain for stakes...</p>
            </Card>
          ) : stakes.length === 0 ? (
            <Card className="p-12 text-center">
              <CheckCircle className="w-16 h-16 text-green-400 mx-auto mb-4" />
              <h3 className="text-xl font-bold text-white mb-2">All Clear!</h3>
              <p className="text-gray-400 mb-4">
                No pending stakes found on-chain. You can stake freely on the Dashboard.
              </p>
              <Button onClick={() => window.location.href = '/dashboard'}>
                Go to Dashboard
              </Button>
            </Card>
          ) : (
            <>
              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold text-white">
                  Pending Stakes ({stakes.length})
                </h2>
                {stakes.length > 1 && (
                  <Button
                    onClick={clearAllStaleStakes}
                    disabled={loading}
                    variant="secondary"
                    className="bg-red-500/20 hover:bg-red-500/30 text-red-400"
                  >
                    <Trash2 className="w-4 h-4 mr-2" />
                    Clear All
                  </Button>
                )}
              </div>

              <div className="space-y-4">
                {stakes.map((stake, index) => (
                  <Card key={index} className="p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <Clock className="w-5 h-5 text-yellow-400" />
                          <h3 className="font-bold text-white">Pending Stake</h3>
                        </div>
                        <div className="space-y-1 text-sm">
                          <p className="text-gray-400">
                            <span className="text-gray-500">To:</span>{' '}
                            <span className="font-mono">{stake.target.slice(0, 10)}...{stake.target.slice(-8)}</span>
                          </p>
                          <p className="text-gray-400">
                            <span className="text-gray-500">Amount:</span>{' '}
                            <span className="text-primary font-semibold">0.1 APT</span>
                          </p>
                          <p className="text-gray-400">
                            <span className="text-gray-500">Status:</span>{' '}
                            {stake.status?.pending ? (
                              <span className="text-yellow-400">Pending</span>
                            ) : stake.status?.matched ? (
                              <span className="text-green-400">Matched</span>
                            ) : stake.status?.refunded ? (
                              <span className="text-blue-400">Refunded</span>
                            ) : (
                              <span className="text-gray-400">Unknown</span>
                            )}
                          </p>
                        </div>
                      </div>

                      <div className="flex flex-col gap-2">
                        <Button
                          onClick={() => refundStake(stake.target)}
                          disabled={refunding === stake.target}
                          className="bg-red-500/20 hover:bg-red-500/30 text-red-400 border-red-500/30"
                        >
                          {refunding === stake.target ? (
                            <>
                              <div className="w-4 h-4 border-2 border-red-400/30 border-t-red-400 rounded-full animate-spin mr-2" />
                              Refunding...
                            </>
                          ) : (
                            <>
                              <Trash2 className="w-4 h-4 mr-2" />
                              Refund
                            </>
                          )}
                        </Button>
                      </div>
                    </div>
                  </Card>
                ))}
              </div>
            </>
          )}
        </motion.div>

        {/* Instructions */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
        >
          <Card className="p-4 bg-gray-800/50">
            <h3 className="font-semibold text-white mb-2">Instructions:</h3>
            <ul className="space-y-1 text-sm text-gray-400">
              <li>• Stakes can be refunded after 2 days (172,800 seconds)</li>
              <li>• Click "Refund" to get your 0.1 APT back</li>
              <li>• After refunding, you can stake on that user again</li>
              <li>• Use "Clear All" to refund all stale stakes at once</li>
            </ul>
          </Card>
        </motion.div>
      </div>
    </Layout>
  );
};

export default ManageStakes;
