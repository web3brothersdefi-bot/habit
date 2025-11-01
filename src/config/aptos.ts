import { Aptos, AptosConfig, Network } from "@aptos-labs/ts-sdk";
import { PetraWallet } from "petra-plugin-wallet-adapter";

// ========== APTOS CONFIGURATION ==========

// Network configuration
export const APTOS_NETWORK = Network.DEVNET; // Using devnet (more stable than testnet)

// Aptos client configuration
const aptosConfig = new AptosConfig({
  network: APTOS_NETWORK,
});

export const aptosClient = new Aptos(aptosConfig);

// ========== WALLET CONFIGURATION ==========

export const wallets = [
  new PetraWallet(),
];

// ========== CONTRACT CONFIGURATION ==========

// Module address (will be set after deployment)
export const MODULE_ADDRESS = import.meta.env.VITE_MODULE_ADDRESS || "0x0";

// Module name
export const MODULE_NAME = "stake_match";

// Full module ID
export const MODULE_ID = `${MODULE_ADDRESS}::${MODULE_NAME}`;

// ========== CONTRACT CONSTANTS ==========

// Stake amount: 0.1 APT = 10,000,000 Octas (8 decimals)
export const STAKE_AMOUNT = 10_000_000n; // 0.1 APT

// Time periods
export const REFUND_PERIOD = 2 * 24 * 60 * 60; // 2 days in seconds
export const RELEASE_PERIOD = 7 * 24 * 60 * 60; // 7 days in seconds

// Platform fee
export const PLATFORM_FEE_BPS = 100; // 1% = 100 basis points

// ========== HELPER FUNCTIONS ==========

/**
 * Format APT amount from Octas
 */
export function formatAPT(octas: bigint | number): string {
  const amount = typeof octas === 'bigint' ? Number(octas) : octas;
  return (amount / 100_000_000).toFixed(2);
}

/**
 * Convert APT to Octas
 */
export function aptToOctas(apt: number): bigint {
  return BigInt(Math.floor(apt * 100_000_000));
}

/**
 * Format Aptos address for display
 */
export function formatAddress(address: string, chars = 4): string {
  if (!address) return '';
  return `${address.slice(0, chars + 2)}...${address.slice(-chars)}`;
}

/**
 * Validate Aptos address format
 */
export function isValidAptosAddress(address: string): boolean {
  // Aptos addresses are 32 bytes (64 hex chars) with 0x prefix
  const addressRegex = /^0x[a-fA-F0-9]{64}$/;
  return addressRegex.test(address);
}

/**
 * Normalize Aptos address (add leading zeros if needed)
 */
export function normalizeAddress(address: string): string {
  if (!address.startsWith('0x')) {
    address = '0x' + address;
  }
  // Pad to 64 hex characters
  const hexPart = address.slice(2);
  return '0x' + hexPart.padStart(64, '0');
}

// ========== TRANSACTION CONFIGURATION ==========

export const TX_OPTIONS = {
  max_gas_amount: "10000",
  gas_unit_price: "100",
};

// ========== FUNCTION NAMES ==========

export const FUNCTIONS = {
  INITIALIZE: `${MODULE_ID}::initialize`,
  STAKE_TO_CONNECT: `${MODULE_ID}::stake_to_connect`,
  REFUND_EXPIRED_STAKE: `${MODULE_ID}::refund_expired_stake`,
  RELEASE_STAKE: `${MODULE_ID}::release_stake_after_match`,
  GET_STAKE_STATUS: `${MODULE_ID}::get_stake_status`,
  IS_MATCHED: `${MODULE_ID}::is_matched`,
  GET_STAKE_AMOUNT: `${MODULE_ID}::get_stake_amount`,
};

// ========== EXPLORER LINKS ==========

export function getExplorerLink(
  type: 'transaction' | 'account' | 'module',
  identifier: string
): string {
  const baseUrl = APTOS_NETWORK === Network.MAINNET
    ? 'https://explorer.aptoslabs.com'
    : 'https://explorer.aptoslabs.com/?network=testnet';
  
  switch (type) {
    case 'transaction':
      return `${baseUrl}/txn/${identifier}`;
    case 'account':
      return `${baseUrl}/account/${identifier}`;
    case 'module':
      return `${baseUrl}/account/${identifier}?tab=modules`;
    default:
      return baseUrl;
  }
}

// ========== TYPE DEFINITIONS ==========

export interface StakeStatus {
  pending: boolean;
  matched: boolean;
  refunded: boolean;
  released: boolean;
}

export interface StakeInfo {
  staker: string;
  target: string;
  amount: bigint;
  timestamp: number;
  status: StakeStatus;
}

// ========== ERROR CODES ==========

export const ERROR_CODES = {
  E_NOT_INITIALIZED: 1,
  E_ALREADY_INITIALIZED: 2,
  E_NO_STAKE_EXISTS: 3,
  E_STAKE_ALREADY_EXISTS: 4,
  E_INSUFFICIENT_BALANCE: 5,
  E_REFUND_PERIOD_NOT_ELAPSED: 6,
  E_RELEASE_PERIOD_NOT_ELAPSED: 7,
  E_NOT_MATCHED: 8,
  E_ALREADY_REFUNDED: 9,
  E_ALREADY_RELEASED: 10,
  E_INVALID_AMOUNT: 11,
  E_UNAUTHORIZED: 12,
};

export function getErrorMessage(code: number): string {
  switch (code) {
    case ERROR_CODES.E_NOT_INITIALIZED:
      return "Contract not initialized";
    case ERROR_CODES.E_ALREADY_INITIALIZED:
      return "Contract already initialized";
    case ERROR_CODES.E_NO_STAKE_EXISTS:
      return "No stake exists";
    case ERROR_CODES.E_STAKE_ALREADY_EXISTS:
      return "Stake already exists";
    case ERROR_CODES.E_INSUFFICIENT_BALANCE:
      return "Insufficient balance";
    case ERROR_CODES.E_REFUND_PERIOD_NOT_ELAPSED:
      return "Refund period not elapsed (wait 2 days)";
    case ERROR_CODES.E_RELEASE_PERIOD_NOT_ELAPSED:
      return "Release period not elapsed (wait 7 days)";
    case ERROR_CODES.E_NOT_MATCHED:
      return "Users not matched";
    case ERROR_CODES.E_ALREADY_REFUNDED:
      return "Stake already refunded";
    case ERROR_CODES.E_ALREADY_RELEASED:
      return "Stake already released";
    case ERROR_CODES.E_INVALID_AMOUNT:
      return "Invalid stake amount";
    case ERROR_CODES.E_UNAUTHORIZED:
      return "Unauthorized action";
    default:
      return "Unknown error occurred";
  }
}
