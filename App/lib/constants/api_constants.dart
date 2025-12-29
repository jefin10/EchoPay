/// API Constants for VoiceUPI Application
/// Simple React Native style - just change the URLs here!

// ==================== BASE URLs ====================
// Change these based on your environment:
// - Android Emulator: use 10.0.2.2
// - iOS Simulator: use localhost or your IP
// - Physical Device: use your computer's IP address

const String DJANGO_BASE_URL = 'http://192.168.1.2:8000';
const String INTENT_API_URL = 'http://192.168.1.2:5000';

// ==================== ENDPOINTS ====================

// Auth
const String SIGNUP_URL = '$DJANGO_BASE_URL/accounts/signup/';
const String SEND_OTP_URL = '$DJANGO_BASE_URL/accounts/send_otp';
const String VERIFY_OTP_URL = '$DJANGO_BASE_URL/accounts/verify_otp';

// Profile & Balance
const String GET_PROFILE_URL = '$DJANGO_BASE_URL/accounts/getProfile/';
const String GET_BALANCE_URL = '$DJANGO_BASE_URL/accounts/getBalance';

// Transactions
const String GET_TRANSACTIONS_URL = '$DJANGO_BASE_URL/accounts/getTransactions/';

// Search
const String SEARCH_BY_PHONE_URL = '$DJANGO_BASE_URL/accounts/searchPhonenumber/';
const String SEARCH_BY_UPI_URL = '$DJANGO_BASE_URL/accounts/searchByUpiId/';
const String CHECK_ACCOUNT_URL = '$DJANGO_BASE_URL/accounts/checkHasAccount/';

// Send Money
const String SEND_MONEY_PHONE_URL = '$DJANGO_BASE_URL/accounts/sendMoneyPhone/';
const String SEND_MONEY_ID_URL = '$DJANGO_BASE_URL/accounts/sendMoneyId/';

// Money Requests
const String GET_REQUESTS_URL = '$DJANGO_BASE_URL/accounts/getMoneyRequests/';
const String CREATE_REQUEST_URL = '$DJANGO_BASE_URL/accounts/createMoneyRequest/';
const String UPDATE_REQUEST_URL = '$DJANGO_BASE_URL/accounts/updateRequestStatus/';

// Intent Classification
const String CLASSIFY_INTENT_URL = '$INTENT_API_URL/predict';
const String VOICE_COMMAND_URL = '$INTENT_API_URL/predict';
