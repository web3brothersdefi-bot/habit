import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useWallet } from '@aptos-labs/wallet-adapter-react';
import WalletSelector from './WalletSelector';
import { Home, Mail, MessageCircle, Trophy, User, Settings, LogOut } from 'lucide-react';
import Logo from './Logo';
import { useAuthStore } from '../store/useStore';
import { motion } from 'framer-motion';

const Layout = ({ children, showNavigation = true }) => {
  const { connected, account, disconnect } = useWallet();
  const address = account?.address;
  const navigate = useNavigate();
  const location = useLocation();
  const { clearUser } = useAuthStore();

  const handleLogout = () => {
    disconnect();
    clearUser();
    navigate('/');
  };

  const navItems = [
    { icon: Home, label: 'Discover', path: '/dashboard' },
    { icon: Mail, label: 'Requests', path: '/requests' },
    { icon: MessageCircle, label: 'Chats', path: '/chats' },
    { icon: Trophy, label: 'Leaderboard', path: '/leaderboard' },
    { icon: User, label: 'Profile', path: '/profile' },
  ];

  return (
    <div className="min-h-screen bg-dark text-white">
      {/* Top Navigation */}
      <nav className="fixed top-0 left-0 right-0 z-50 glass-card border-b border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            {/* Logo */}
            <Link to={address ? '/dashboard' : '/'}>
              <Logo size="sm" showText={true} />
            </Link>

            {/* Right Side */}
            <div className="flex items-center gap-4">
              {address && showNavigation && (
                <>
                  <Link to="/settings">
                    <motion.button
                      className="glass-button p-2"
                      whileHover={{ scale: 1.05 }}
                      whileTap={{ scale: 0.95 }}
                    >
                      <Settings className="w-5 h-5" />
                    </motion.button>
                  </Link>
                  
                  <motion.button
                    className="glass-button p-2"
                    onClick={handleLogout}
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                  >
                    <LogOut className="w-5 h-5" />
                  </motion.button>
                </>
              )}
              
              <WalletSelector />
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content */}
      <main className="pt-16 min-h-screen pb-20 lg:pb-6">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          {children}
        </div>
      </main>

      {/* Bottom Navigation (Mobile) */}
      {address && showNavigation && (
        <nav className="fixed bottom-0 left-0 right-0 lg:hidden z-50 glass-card border-t border-white/10">
          <div className="flex items-center justify-around h-16 px-4">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;

              return (
                <Link
                  key={item.path}
                  to={item.path}
                  className="flex flex-col items-center gap-1"
                >
                  <motion.div
                    className={`p-2 rounded-xl transition-colors ${
                      isActive ? 'bg-primary text-white' : 'text-grey hover:text-white'
                    }`}
                    whileTap={{ scale: 0.95 }}
                  >
                    <Icon className="w-5 h-5" />
                  </motion.div>
                  <span className={`text-xs ${isActive ? 'text-white' : 'text-grey'}`}>
                    {item.label}
                  </span>
                </Link>
              );
            })}
          </div>
        </nav>
      )}

      {/* Desktop Sidebar (optional - for larger screens) */}
      {address && showNavigation && (
        <aside className="hidden lg:block fixed left-0 top-16 bottom-0 w-64 glass-card border-r border-white/10 p-6">
          <nav className="space-y-2">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = location.pathname === item.path;

              return (
                <Link
                  key={item.path}
                  to={item.path}
                >
                  <motion.div
                    className={`flex items-center gap-3 px-4 py-3 rounded-xl transition-colors ${
                      isActive
                        ? 'bg-primary text-white'
                        : 'text-grey hover:text-white hover:bg-white/5'
                    }`}
                    whileHover={{ x: 5 }}
                    whileTap={{ scale: 0.98 }}
                  >
                    <Icon className="w-5 h-5" />
                    <span className="font-medium">{item.label}</span>
                  </motion.div>
                </Link>
              );
            })}
          </nav>
        </aside>
      )}
    </div>
  );
};

export default Layout;
