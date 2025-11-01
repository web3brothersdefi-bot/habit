import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import { Toaster } from 'react-hot-toast';
import { useAuthStore } from './store/useStore';
import { useUserProfile } from './hooks/useSupabase';
import DebugInfo from './components/DebugInfo';

// Pages
import Landing from './pages/Landing';
import RoleSelection from './pages/onboarding/RoleSelection';
import ProfileSetup from './pages/onboarding/ProfileSetup';
import RoleDetails from './pages/onboarding/RoleDetails';
import Socials from './pages/onboarding/Socials';
import HabitsGoals from './pages/onboarding/HabitsGoals';
import Dashboard from './pages/Dashboard';
import Requests from './pages/Requests';
import ManageStakes from './pages/ManageStakes';
import Chats from './pages/Chats';
import Leaderboard from './pages/Leaderboard';
import Profile from './pages/Profile';
import Settings from './pages/Settings';

// Protected Route Component
const ProtectedRoute = ({ children }) => {
  const { connected, account } = useWallet();
  const { user } = useAuthStore();

  if (!connected || !account) {
    return <Navigate to="/" replace />;
  }

  if (!user) {
    return <Navigate to="/onboarding/role" replace />;
  }

  return children;
};

// Onboarding Route Component
const OnboardingRoute = ({ children }) => {
  const { connected, account } = useWallet();
  const { user } = useAuthStore();
  const address = account?.address;
  const { loading } = useUserProfile(address);

  // Not connected - redirect to landing
  if (!connected || !account) {
    return <Navigate to="/" replace />;
  }

  // Still loading profile - show nothing to avoid flash
  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="spinner w-12 h-12"></div>
      </div>
    );
  }

  // Existing user with profile - redirect to dashboard
  if (user && user.name && user.role) {
    console.log('⚠️ Existing user accessing onboarding - redirecting to dashboard');
    return <Navigate to="/dashboard" replace />;
  }

  // New user - show onboarding
  return children;
};

function App() {
  const { connected, account } = useWallet();
  const { setUser, user, clearUser } = useAuthStore();
  const address = account?.address;
  const { profile, loading } = useUserProfile(address);

  // Sync user profile from Supabase when wallet connects
  useEffect(() => {
    if (!connected || !address) {
      // Clear user when wallet disconnects
      clearUser();
      return;
    }

    if (!loading) {
      if (profile) {
        // User exists in database, load their profile
        console.log('✅ Existing user found:', profile.name);
        setUser(profile);
      } else {
        // New user detected
        // Don't clearUser() here - user might be in onboarding process
        // Only log if we don't already have a user in store (avoid spam during onboarding)
        if (!user) {
          console.log('New user detected, profile will be created during onboarding');
        }
      }
    }
  }, [connected, address, profile, loading, setUser, clearUser, user]);

  return (
    <Router>
      <div className="App">
        <Routes>
          {/* Public Routes */}
          <Route path="/" element={<Landing />} />

          {/* Onboarding Routes */}
          <Route
            path="/onboarding/role"
            element={
              <OnboardingRoute>
                <RoleSelection />
              </OnboardingRoute>
            }
          />
          <Route
            path="/onboarding/profile"
            element={
              <OnboardingRoute>
                <ProfileSetup />
              </OnboardingRoute>
            }
          />
          <Route
            path="/onboarding/details"
            element={
              <OnboardingRoute>
                <RoleDetails />
              </OnboardingRoute>
            }
          />
          <Route
            path="/onboarding/socials"
            element={
              <OnboardingRoute>
                <Socials />
              </OnboardingRoute>
            }
          />
          <Route
            path="/onboarding/habits"
            element={
              <OnboardingRoute>
                <HabitsGoals />
              </OnboardingRoute>
            }
          />

          {/* Protected Routes */}
          <Route
            path="/dashboard"
            element={
              <ProtectedRoute>
                <Dashboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/requests"
            element={
              <ProtectedRoute>
                <Requests />
              </ProtectedRoute>
            }
          />
          <Route
            path="/manage-stakes"
            element={
              <ProtectedRoute>
                <ManageStakes />
              </ProtectedRoute>
            }
          />
          <Route
            path="/chats"
            element={
              <ProtectedRoute>
                <Chats />
              </ProtectedRoute>
            }
          />
          <Route
            path="/leaderboard"
            element={
              <ProtectedRoute>
                <Leaderboard />
              </ProtectedRoute>
            }
          />
          <Route
            path="/profile"
            element={
              <ProtectedRoute>
                <Profile />
              </ProtectedRoute>
            }
          />
          <Route
            path="/settings"
            element={
              <ProtectedRoute>
                <Settings />
              </ProtectedRoute>
            }
          />

          {/* Catch-all redirect */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>

        {/* Toast Notifications */}
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              background: '#1E293B',
              color: '#fff',
              border: '1px solid rgba(255, 255, 255, 0.1)',
              borderRadius: '12px',
              backdropFilter: 'blur(10px)',
            },
            success: {
              iconTheme: {
                primary: '#4F46E5',
                secondary: '#fff',
              },
            },
            error: {
              iconTheme: {
                primary: '#EF4444',
                secondary: '#fff',
              },
            },
          }}
        />

        {/* Debug Info (Development Only) */}
        <DebugInfo />
      </div>
    </Router>
  );
}

export default App;
