/**
 * Backend URLs. Set EXPO_PUBLIC_API_HOST in .env.local:
 * - Android emulator: 10.0.2.2
 * - iOS simulator: localhost
 * - Physical device: your computer's LAN IP
 */
const API_HOST = process.env.EXPO_PUBLIC_API_HOST || '10.0.2.2';

export const DJANGO_BASE_URL = `http://${API_HOST}:8000`;
export const INTENT_API_URL = `http://${API_HOST}:5002`;
export const RASA_BASE_URL = `http://${API_HOST}:5005`;

const accounts = (path: string) => `${DJANGO_BASE_URL}/accounts/${path}/`;

export const Endpoints = {
  // Auth
  signUp: accounts('signup'),
  sendOtp: accounts('send_otp'),
  verifyOtp: accounts('verify_otp'),

  // Profile & balance
  getProfile: accounts('getProfile'),
  getBalance: accounts('getBalance'),

  // Transactions
  getTransactions: accounts('getTransactions'),

  // Search
  searchByPhone: accounts('searchPhonenumber'),
  searchByUpi: accounts('searchByUpiId'),
  checkAccount: accounts('checkHasAccount'),

  // Send money
  sendMoneyPhone: accounts('sendMoneyPhone'),
  sendMoneyId: accounts('sendMoneyId'),

  // Money requests
  getRequests: accounts('getMoneyRequests'),
  createRequest: accounts('createMoneyRequest'),
  createRequestByUpi: accounts('createMoneyRequestByUpi'),
  updateRequest: accounts('updateRequestStatus'),

  // Voice
  voiceCommand: `${INTENT_API_URL}/voice_command`,
  voiceHealth: `${INTENT_API_URL}/health`,
  rasaChat: `${RASA_BASE_URL}/webhooks/rest/webhook`,
} as const;
