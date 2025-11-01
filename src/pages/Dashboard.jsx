import React, { useState, useEffect } from 'react';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { motion, useMotionValue, useTransform } from 'framer-motion';
import { X, Heart, Search, SlidersHorizontal, Sparkles, Zap } from 'lucide-react';
import Layout from '../components/Layout';
import Card from '../components/Card';
import Button from '../components/Button';
import { useDiscoverUsers } from '../hooks/useSupabase';
import { useStakeToConnect } from '../hooks/useAptosContract';
import { useAuthStore } from '../store/useStore';
import { getRoleBadgeClass, getRoleIcon, formatAddress, getIPFSUrl } from '../utils/helpers';
import { toast } from 'react-hot-toast';
import { useInitializeContract } from '../hooks/useInitializeContract';

const SwipeCard = ({ user, onSwipe }) => {
  const x = useMotionValue(0);
  const rotate = useTransform(x, [-200, 200], [-25, 25]);
  const opacity = useTransform(x, [-200, -100, 0, 100, 200], [0, 1, 1, 1, 0]);

  const handleDragEnd = (event, info) => {
    if (Math.abs(info.offset.x) > 100) {
      onSwipe(info.offset.x > 0 ? 'right' : 'left');
    }
  };

  return (
    <motion.div
      drag="x"
      dragConstraints={{ left: 0, right: 0 }}
      style={{ x, rotate, opacity }}
      onDragEnd={handleDragEnd}
      className="absolute w-full max-w-md cursor-grab active:cursor-grabbing"
      whileTap={{ scale: 0.95 }}
    >
      <Card className="overflow-hidden">
        {/* Profile Image */}
        <div className="relative h-96 bg-gradient-to-b from-dark-light to-dark overflow-hidden">
          {user.image_url ? (
            <img
              src={getIPFSUrl(user.image_url)}
              alt={user.name}
              className="w-full h-full object-cover"
            />
          ) : (
            <div className="w-full h-full flex items-center justify-center text-6xl">
              {getRoleIcon(user.role)}
            </div>
          )}
          
          {/* Gradient Overlay */}
          <div className="absolute inset-0 bg-gradient-to-t from-dark via-dark/50 to-transparent" />

          {/* Info Overlay */}
          <div className="absolute bottom-0 left-0 right-0 p-6 space-y-3">
            <div className="flex items-center gap-3">
              <h2 className="text-3xl font-bold text-shadow">{user.name}</h2>
              <span className={`badge ${getRoleBadgeClass(user.role)}`}>
                {getRoleIcon(user.role)} {user.role}
              </span>
            </div>

            {user.bio && (
              <p className="text-grey text-sm line-clamp-2 text-shadow">{user.bio}</p>
            )}

            {/* Skills or Tags */}
            {user.skills && user.skills.length > 0 && (
              <div className="flex flex-wrap gap-2">
                {user.skills.slice(0, 3).map((skill) => (
                  <span key={skill} className="badge text-xs">
                    {skill}
                  </span>
                ))}
              </div>
            )}

            {/* Reputation Score */}
            <div className="flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-yellow-400" />
              <span className="text-sm">
                Reputation: <span className="font-semibold text-yellow-400">{user.reputation_score || 50}</span>
              </span>
            </div>

            {/* Wallet Address */}
            <p className="text-xs text-grey">{formatAddress(user.wallet_address)}</p>
          </div>
        </div>

        {/* Additional Info */}
        <div className="p-6 space-y-4">
          {user.project_name && (
            <div>
              <h3 className="font-semibold text-sm text-grey">Project</h3>
              <p>{user.project_name}</p>
            </div>
          )}

          {user.project_description && (
            <div>
              <h3 className="font-semibold text-sm text-grey">About</h3>
              <p className="text-sm">{user.project_description}</p>
            </div>
          )}

          {user.investment_focus && (
            <div>
              <h3 className="font-semibold text-sm text-grey">Investment Focus</h3>
              <p className="text-sm">{user.investment_focus}</p>
            </div>
          )}

          {/* Social Links */}
          {(user.twitter_handle || user.linkedin_link || user.github_link) && (
            <div className="flex gap-3 pt-2">
              {user.twitter_handle && (
                <a
                  href={`https://twitter.com/${user.twitter_handle.replace('@', '')}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-grey hover:text-primary transition-colors"
                >
                  𝕏
                </a>
              )}
              {user.linkedin_link && (
                <a
                  href={user.linkedin_link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-grey hover:text-primary transition-colors"
                >
                  in
                </a>
              )}
              {user.github_link && (
                <a
                  href={user.github_link}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="text-grey hover:text-primary transition-colors"
                >
                  gh
                </a>
              )}
            </div>
          )}
        </div>
      </Card>
    </motion.div>
  );
};

const Dashboard = () => {
  const { connected, account } = useWallet();
  const address = account?.address;
  const { user } = useAuthStore();
  const [filters, setFilters] = useState({ role: null, skills: [] });
  const [showFilters, setShowFilters] = useState(false);
  const { users, loading, refetch: refetchUsers } = useDiscoverUsers(filters);
  const [currentIndex, setCurrentIndex] = useState(0);
  const { stakeToConnect, loading: stakeLoading } = useStakeToConnect();
  const [isStaking, setIsStaking] = useState(false);
  const [needsInit, setNeedsInit] = useState(false);
  const [initializing, setInitializing] = useState(false);
  const { initialize } = useInitializeContract();

  const currentUser = users[currentIndex];

  const handleInitialize = async () => {
    setInitializing(true);
    try {
      const result = await initialize();
      if (result) {
        setNeedsInit(false);
        toast.success('Contract ready! You can now stake.');
      }
    } catch (error) {
      console.error('Init error:', error);
    } finally {
      setInitializing(false);
    }
  };

  const handleSwipe = async (direction) => {
    if (!currentUser) return;

    if (direction === 'right') {
      // User wants to connect
      try {
        setIsStaking(true);

        // Stake to connect (APT native, no approval needed)
        toast.loading('Staking 0.1 APT to connect...');
        const result = await stakeToConnect(currentUser.wallet_address);
        toast.dismiss();
        
        if (result) {
          toast.success('Stake successful! Waiting for mutual interest...');
          // Move to next user
          setCurrentIndex((prev) => prev + 1);
          // Refresh user list to exclude the staked user
          setTimeout(() => {
            refetchUsers();
          }, 1000);
        }
      } catch (error) {
        console.error('Stake error:', error);
        toast.dismiss();
        
        // Check if contract needs initialization
        if (error.message?.includes('E_NOT_INITIALIZED') || 
            error.message?.includes('0x1')) {
          setNeedsInit(true);
          toast.error('Contract needs to be initialized first');
        } else {
          toast.error('Failed to stake. Please try again.');
        }
      } finally {
        setIsStaking(false);
      }
    } else {
      // User skipped
      setCurrentIndex((prev) => prev + 1);
    }
  };

  const handleButtonSwipe = (direction) => {
    handleSwipe(direction);
  };

  if (!address || !user) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <Card className="p-8 text-center">
            <p>Please connect your wallet and complete onboarding</p>
          </Card>
        </div>
      </Layout>
    );
  }

  if (loading) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="spinner w-12 h-12"></div>
        </div>
      </Layout>
    );
  }

  if (!currentUser) {
    return (
      <Layout>
        <div className="flex items-center justify-center min-h-[60vh]">
          <Card className="p-8 text-center space-y-4">
            <h2 className="text-2xl font-bold">No more users to discover</h2>
            <p className="text-grey">Check back later for new connections!</p>
            <Button onClick={() => setCurrentIndex(0)}>
              Start Over
            </Button>
          </Card>
        </div>
      </Layout>
    );
  }

  return (
    <Layout>
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-3xl font-bold gradient-text">Discover</h1>
            <p className="text-grey">Find your next connection</p>
          </div>

          <div className="flex gap-3">
            <Button
              variant="secondary"
              icon={<Search className="w-5 h-5" />}
              className="p-3"
            >
              Search
            </Button>
            <Button
              variant="secondary"
              icon={<SlidersHorizontal className="w-5 h-5" />}
              onClick={() => setShowFilters(!showFilters)}
              className="p-3"
            >
              Filters
            </Button>
          </div>
        </div>

        {/* Initialize Contract Warning */}
        {needsInit && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <Card className="p-6 bg-yellow-500/10 border-yellow-500/30">
              <div className="flex items-start gap-4">
                <Zap className="w-6 h-6 text-yellow-400 flex-shrink-0 mt-1" />
                <div className="flex-1">
                  <h3 className="text-lg font-bold text-yellow-400 mb-2">
                    Contract Initialization Required
                  </h3>
                  <p className="text-sm text-yellow-200 mb-4">
                    The smart contract needs to be initialized before anyone can stake. 
                    This is a one-time setup that creates the stake registry on-chain.
                  </p>
                  <Button
                    onClick={handleInitialize}
                    disabled={initializing}
                    className="bg-yellow-500 hover:bg-yellow-600 text-dark font-semibold"
                  >
                    {initializing ? (
                      <div className="flex items-center gap-2">
                        <div className="w-4 h-4 border-2 border-dark/30 border-t-dark rounded-full animate-spin" />
                        <span>Initializing...</span>
                      </div>
                    ) : (
                      <div className="flex items-center gap-2">
                        <Zap className="w-4 h-4" />
                        <span>Initialize Contract (One-Time)</span>
                      </div>
                    )}
                  </Button>
                  <p className="text-xs text-yellow-300 mt-2">
                    Cost: ~0.001 APT gas fee
                  </p>
                </div>
              </div>
            </Card>
          </motion.div>
        )}

        {/* Filters Panel */}
        {showFilters && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
          >
            <Card className="p-6">
              <h3 className="font-bold mb-4">Filters</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm text-grey mb-2">Role</label>
                  <div className="flex gap-2">
                    {['founder', 'builder', 'investor'].map((role) => (
                      <button
                        key={role}
                        onClick={() => setFilters({ ...filters, role: role })}
                        className={`px-4 py-2 rounded-lg capitalize transition-all ${
                          filters.role === role
                            ? 'bg-primary text-white'
                            : 'glass-button'
                        }`}
                      >
                        {role}
                      </button>
                    ))}
                    <button
                      onClick={() => setFilters({ ...filters, role: null })}
                      className="px-4 py-2 rounded-lg glass-button"
                    >
                      Clear
                    </button>
                  </div>
                </div>
              </div>
            </Card>
          </motion.div>
        )}

        {/* Swipe Card Stack */}
        <div className="relative flex justify-center items-center min-h-[600px]">
          <SwipeCard user={currentUser} onSwipe={handleSwipe} />
        </div>

        {/* Action Buttons */}
        <div className="flex justify-center gap-6 pb-8">
          <motion.button
            onClick={() => handleButtonSwipe('left')}
            disabled={isStaking}
            className="w-16 h-16 rounded-full glass-card flex items-center justify-center hover:bg-red-500/20 hover:border-red-500 transition-all disabled:opacity-50"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
          >
            <X className="w-8 h-8 text-red-500" />
          </motion.button>

          <motion.button
            onClick={() => handleButtonSwipe('right')}
            disabled={isStaking}
            className="w-20 h-20 rounded-full glass-card flex items-center justify-center hover:bg-green-500/20 hover:border-green-500 transition-all disabled:opacity-50"
            whileHover={{ scale: 1.1 }}
            whileTap={{ scale: 0.9 }}
          >
            <Heart className="w-10 h-10 text-green-500" fill="currentColor" />
          </motion.button>
        </div>

        {/* Info: APT balance check handled automatically by blockchain */}
      </div>
    </Layout>
  );
};

export default Dashboard;
