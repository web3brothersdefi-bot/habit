import { useState, useEffect } from 'react';
import { supabase, TABLES } from '../config/supabase';
import { useAuthStore } from '../store/useStore';
import { toast } from 'react-hot-toast';
import { normalizeAptosAddress } from '../utils/helpers';

/**
 * Hook to fetch user profile from Supabase
 */
export const useUserProfile = (walletAddress) => {
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!walletAddress) {
      setLoading(false);
      return;
    }

    const fetchProfile = async () => {
      try {
        const normalizedAddress = normalizeAptosAddress(walletAddress);
        
        const { data, error } = await supabase
          .from(TABLES.USERS)
          .select('*')
          .eq('wallet_address', normalizedAddress)
          .maybeSingle();

        // maybeSingle() returns null if no rows, doesn't throw error
        if (error) {
          console.error('Supabase error:', error);
          throw error;
        }
        
        setProfile(data); // Will be null if user doesn't exist
      } catch (err) {
        // Only log real errors, not "no user found"
        if (err.code !== 'PGRST116') {
          console.error('Error fetching profile:', err);
          setError(err.message);
        }
        setProfile(null);
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, [walletAddress]);

  const refetchProfile = async () => {
    if (!walletAddress) return;
    setLoading(true);
    
    try {
      const normalizedAddress = normalizeAptosAddress(walletAddress);
      
      const { data, error } = await supabase
        .from(TABLES.USERS)
        .select('*')
        .eq('wallet_address', normalizedAddress)
        .maybeSingle();

      if (error) throw error;
      setProfile(data);
    } catch (err) {
      console.error('Error refetching profile:', err);
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return { profile, loading, error, refetch: refetchProfile };
};

/**
 * Hook to create or update user profile
 */
export const useUpdateProfile = () => {
  const [loading, setLoading] = useState(false);

  const updateProfile = async (walletAddress, profileData) => {
    setLoading(true);
    
    try {
      // Validate required fields before sending
      if (!walletAddress) {
        throw new Error('Wallet address is required');
      }
      
      if (!profileData.role) {
        throw new Error('Role is required');
      }
      
      if (!profileData.name) {
        throw new Error('Name is required');
      }

      // Clean data: remove undefined values, keep explicit nulls
      const cleanData = Object.entries(profileData).reduce((acc, [key, value]) => {
        // Keep null values, but remove undefined
        if (value !== undefined) {
          acc[key] = value;
        }
        return acc;
      }, {});

      // Normalize Aptos address
      const normalizedAddress = normalizeAptosAddress(walletAddress);
      
      // Prepare final data
      const finalData = {
        wallet_address: normalizedAddress,
        ...cleanData,
        updated_at: new Date().toISOString(),
      };

      console.log('Creating profile with data:', finalData); // Debug log

      const { data, error } = await supabase
        .from(TABLES.USERS)
        .upsert(finalData, {
          onConflict: 'wallet_address',
        })
        .select()
        .single();

      if (error) {
        console.error('Supabase error:', error);
        throw error;
      }
      
      toast.success('Profile updated successfully!');
      return data;
    } catch (err) {
      console.error('Error updating profile:', err);
      
      // Better error messages
      if (err.code === '23502') {
        toast.error(`Missing required field: ${err.message}`);
      } else if (err.code === '23505') {
        toast.error('Profile already exists');
      } else {
        toast.error(err.message || 'Failed to update profile');
      }
      
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { updateProfile, loading };
};

/**
 * Hook to fetch all users for discovery
 * Excludes current user and users with pending requests
 */
export const useDiscoverUsers = (filters = {}) => {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    const fetchUsers = async () => {
      try {
        const normalizedAddress = normalizeAptosAddress(user?.wallet_address || '');
        
        // First, get all pending stakes by current user
        const { data: pendingStakes, error: stakesError } = await supabase
          .from(TABLES.STAKES)
          .select('target')
          .eq('staker', normalizedAddress)
          .eq('status', 'pending');

        if (stakesError) throw stakesError;

        // Extract target addresses to exclude
        const excludedAddresses = pendingStakes?.map(s => s.target) || [];
        excludedAddresses.push(normalizedAddress); // Exclude self

        let query = supabase
          .from(TABLES.USERS)
          .select('*')
          .not('wallet_address', 'in', `(${excludedAddresses.map(a => `"${a}"`).join(',')})`);

        // Apply role filter
        if (filters.role) {
          query = query.eq('role', filters.role);
        }

        // Apply skills filter (for builders)
        if (filters.skills && filters.skills.length > 0) {
          query = query.contains('skills', filters.skills);
        }

        const { data, error } = await query;

        if (error) throw error;
        
        // Shuffle users for random discovery
        const shuffled = data.sort(() => Math.random() - 0.5);
        setUsers(shuffled);
      } catch (err) {
        console.error('Error fetching users:', err);
        toast.error('Failed to load users');
      } finally {
        setLoading(false);
      }
    };

    if (user) {
      fetchUsers();
    }
  }, [user, filters]);

  const refetchUsers = () => {
    if (user) {
      setLoading(true);
      fetchUsers();
    }
  };

  return { users, loading, refetch: refetchUsers };
};

/**
 * Hook to fetch user matches
 */
export const useMatches = () => {
  const [matches, setMatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (!user) return;

    const fetchMatches = async () => {
      try {
        const normalizedAddress = normalizeAptosAddress(user.wallet_address);
        
        const { data, error } = await supabase
          .from(TABLES.MATCHES)
          .select(`
            *,
            user_a_profile:users!fk_matches_user_a(*),
            user_b_profile:users!fk_matches_user_b(*)
          `)
          .or(`user_a.eq.${normalizedAddress},user_b.eq.${normalizedAddress}`)
          .order('matched_at', { ascending: false });

        if (error) throw error;
        setMatches(data || []);
      } catch (err) {
        console.error('Error fetching matches:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchMatches();

    // Subscribe to new matches
    const normalizedAddress = normalizeAptosAddress(user.wallet_address);
    const subscription = supabase
      .channel('matches')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: TABLES.MATCHES,
          filter: `user_a=eq.${normalizedAddress},user_b=eq.${normalizedAddress}`,
        },
        (payload) => {
          setMatches((prev) => [payload.new, ...prev]);
          toast.success('New match! 🎉');
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [user]);

  return { matches, loading };
};

/**
 * Hook to manage chat messages
 */
export const useChatMessages = (chatRoomId) => {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!chatRoomId) return;

    const fetchMessages = async () => {
      try {
        const { data, error } = await supabase
          .from(TABLES.CHATS)
          .select('*')
          .eq('room_id', chatRoomId)
          .order('timestamp', { ascending: true });

        if (error) throw error;
        setMessages(data || []);
      } catch (err) {
        console.error('Error fetching messages:', err);
      } finally {
        setLoading(false);
      }
    };

    fetchMessages();

    // Subscribe to new messages
    const subscription = supabase
      .channel(`chat:${chatRoomId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: TABLES.CHATS,
          filter: `room_id=eq.${chatRoomId}`,
        },
        (payload) => {
          setMessages((prev) => [...prev, payload.new]);
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [chatRoomId]);

  const sendMessage = async (message, senderWallet) => {
    try {
      const { error } = await supabase.from(TABLES.CHATS).insert({
        room_id: chatRoomId,
        sender_wallet: senderWallet.toLowerCase(),
        message,
        timestamp: new Date().toISOString(),
      });

      if (error) throw error;
    } catch (err) {
      console.error('Error sending message:', err);
      toast.error('Failed to send message');
      throw err;
    }
  };

  return { messages, loading, sendMessage };
};

/**
 * Hook to create a match in Supabase
 */
export const useCreateMatch = () => {
  const [loading, setLoading] = useState(false);

  const createMatch = async (userA, userB) => {
    setLoading(true);
    try {
      // Sort addresses to maintain consistency
      const [addr1, addr2] = [userA, userB].sort();
      
      const chatRoomId = `${addr1}_${addr2}`;

      const { data, error } = await supabase
        .from(TABLES.MATCHES)
        .insert({
          user_a: addr1.toLowerCase(),
          user_b: addr2.toLowerCase(),
          matched_at: new Date().toISOString(),
          chat_room_id: chatRoomId,
        })
        .select()
        .single();

      if (error) throw error;
      
      return data;
    } catch (err) {
      console.error('Error creating match:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { createMatch, loading };
};

/**
 * Hook to update stake status in Supabase
 */
export const useUpdateStake = () => {
  const [loading, setLoading] = useState(false);

  const updateStake = async (staker, target, status, txHash) => {
    setLoading(true);
    try {
      const { data, error } = await supabase
        .from(TABLES.STAKES)
        .upsert({
          staker: staker.toLowerCase(),
          target: target.toLowerCase(),
          amount: '1', // 1 USDC
          status,
          tx_hash: txHash,
          updated_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw error;
      
      return data;
    } catch (err) {
      console.error('Error updating stake:', err);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { updateStake, loading };
};

/**
 * Hook to fetch incoming stake requests (people who staked on you)
 */
export const useIncomingRequests = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (!user) return;

    const fetchRequests = async () => {
      try {
        const normalizedAddress = normalizeAptosAddress(user.wallet_address);
        
        // Get all pending stakes where current user is the target
        const { data: stakes, error: stakesError } = await supabase
          .from(TABLES.STAKES)
          .select('*')
          .eq('target', normalizedAddress)
          .eq('status', 'pending')
          .order('created_at', { ascending: false });

        if (stakesError) throw stakesError;

        // Fetch user profiles for each staker
        const requestsWithProfiles = await Promise.all(
          (stakes || []).map(async (stake) => {
            const { data: profile, error: profileError } = await supabase
              .from(TABLES.USERS)
              .select('*')
              .eq('wallet_address', stake.staker)
              .maybeSingle();

            if (profileError) {
              console.error('Error fetching profile:', profileError);
              return { ...stake, profile: null };
            }

            return { ...stake, profile };
          })
        );

        setRequests(requestsWithProfiles);
      } catch (err) {
        console.error('Error fetching incoming requests:', err);
        toast.error('Failed to load requests');
      } finally {
        setLoading(false);
      }
    };

    fetchRequests();

    // Subscribe to new incoming requests
    const normalizedAddress = normalizeAptosAddress(user.wallet_address);
    const subscription = supabase
      .channel('incoming-requests')
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: TABLES.STAKES,
          filter: `target=eq.${normalizedAddress}`,
        },
        async (payload) => {
          // Fetch profile for new request
          const { data: profile } = await supabase
            .from(TABLES.USERS)
            .select('*')
            .eq('wallet_address', payload.new.staker)
            .maybeSingle();

          setRequests((prev) => [{ ...payload.new, profile }, ...prev]);
          toast.success('New connection request! 💌');
        }
      )
      .subscribe();

    return () => {
      subscription.unsubscribe();
    };
  }, [user]);

  return { requests, loading };
};

/**
 * Hook to fetch outgoing stake requests (people you staked on)
 */
export const useOutgoingRequests = () => {
  const [requests, setRequests] = useState([]);
  const [loading, setLoading] = useState(true);
  const { user } = useAuthStore();

  useEffect(() => {
    if (!user) return;

    const fetchRequests = async () => {
      try {
        const normalizedAddress = normalizeAptosAddress(user.wallet_address);
        
        // Get all pending stakes by current user
        const { data: stakes, error: stakesError } = await supabase
          .from(TABLES.STAKES)
          .select('*')
          .eq('staker', normalizedAddress)
          .eq('status', 'pending')
          .order('created_at', { ascending: false });

        if (stakesError) throw stakesError;

        // Fetch user profiles for each target
        const requestsWithProfiles = await Promise.all(
          (stakes || []).map(async (stake) => {
            const { data: profile, error: profileError } = await supabase
              .from(TABLES.USERS)
              .select('*')
              .eq('wallet_address', stake.target)
              .maybeSingle();

            if (profileError) {
              console.error('Error fetching profile:', profileError);
              return { ...stake, profile: null };
            }

            return { ...stake, profile };
          })
        );

        setRequests(requestsWithProfiles);
      } catch (err) {
        console.error('Error fetching outgoing requests:', err);
        toast.error('Failed to load sent requests');
      } finally {
        setLoading(false);
      }
    };

    fetchRequests();
  }, [user]);

  return { requests, loading };
};

/**
 * Hook to check if both users have staked and create match
 */
export const useCheckAndCreateMatch = () => {
  const [loading, setLoading] = useState(false);
  const { createMatch } = useCreateMatch();

  const checkAndCreateMatch = async (userA, userB) => {
    setLoading(true);
    try {
      const normalizedA = normalizeAptosAddress(userA);
      const normalizedB = normalizeAptosAddress(userB);

      // Check if both users have staked on each other
      const { data: stakeA, error: errorA } = await supabase
        .from(TABLES.STAKES)
        .select('*')
        .eq('staker', normalizedA)
        .eq('target', normalizedB)
        .eq('status', 'pending')
        .maybeSingle();

      const { data: stakeB, error: errorB } = await supabase
        .from(TABLES.STAKES)
        .select('*')
        .eq('staker', normalizedB)
        .eq('target', normalizedA)
        .eq('status', 'pending')
        .maybeSingle();

      if (errorA || errorB) {
        console.error('Error checking stakes:', errorA || errorB);
        return null;
      }

      // If both stakes exist, create match
      if (stakeA && stakeB) {
        // Update both stakes to matched
        await supabase
          .from(TABLES.STAKES)
          .update({ status: 'matched', updated_at: new Date().toISOString() })
          .eq('id', stakeA.id);

        await supabase
          .from(TABLES.STAKES)
          .update({ status: 'matched', updated_at: new Date().toISOString() })
          .eq('id', stakeB.id);

        // Create match
        const match = await createMatch(normalizedA, normalizedB);
        
        toast.success('🎉 It\'s a match! You can now chat!');
        return match;
      }

      return null;
    } catch (err) {
      console.error('Error checking and creating match:', err);
      return null;
    } finally {
      setLoading(false);
    }
  };

  return { checkAndCreateMatch, loading };
};
