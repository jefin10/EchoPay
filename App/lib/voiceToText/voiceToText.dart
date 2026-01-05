import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/intent_service.dart';
import '../services/django_service.dart';
import '../constants/app_colors.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  final LocalAuthentication _localAuth = LocalAuthentication();
  late AnimationController _pulseController;

  bool _isListening = false;
  bool _speechEnabled = false;
  bool _isProcessing = false;
  bool _serverConnected = false;
  String _spokenText = '';
  String? _userPhone;
  String? _responseMessage;
  bool _isSuccess = true;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _checkServerConnection();
    _loadUserPhone();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _loadUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    _userPhone = prefs.getString('signedUpPhoneNumber');
  }

  void _checkServerConnection() async {
    final isConnected = await IntentService.checkServerHealth();
    setState(() => _serverConnected = isConnected);
  }

  Future<bool> _authenticateWithBiometrics(String reason) async {
    try {
      final bool canUseBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!canUseBiometrics || !isDeviceSupported) return true;

      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _spokenText = '';
      _responseMessage = null;
    });
    await _speech.listen(onResult: _onSpeechResult);
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  void _onSpeechResult(result) async {
    setState(() => _spokenText = result.recognizedWords);

    if (result.finalResult && _spokenText.isNotEmpty && _serverConnected) {
      await _processVoiceCommand(_spokenText);
    }
  }

  Future<void> _processVoiceCommand(String text) async {
    setState(() {
      _isProcessing = true;
      _responseMessage = null;
    });

    try {
      final result = await IntentService.processVoiceCommand(text);

      if (result['status'] == 'success') {
        final action = result['action'];

        if (action == 'initiate_transfer') {
          setState(() => _isProcessing = false);
          _showTransferConfirmation(result['data']);
        } else if (action == 'show_balance') {
          await _checkAndShowBalance();
        } else if (action == 'initiate_request') {
          setState(() => _isProcessing = false);
          _showRequestConfirmation(result['data']);
        } else if (action == 'chatbot') {
          setState(() {
            _isProcessing = false;
            _responseMessage = result['message'] ?? "I'm here to help!";
            _isSuccess = true;
          });
        } else {
          setState(() {
            _isProcessing = false;
            _responseMessage = result['message'];
            _isSuccess = true;
          });
        }
      } else {
        setState(() {
          _isProcessing = false;
          _responseMessage = result['message'] ?? 'Failed to process command';
          _isSuccess = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _responseMessage = 'Error: $e';
        _isSuccess = false;
      });
    }
  }

  Future<void> _checkAndShowBalance() async {
    final authenticated = await _authenticateWithBiometrics(
      'Authenticate to view your balance',
    );

    if (!authenticated) {
      setState(() {
        _isProcessing = false;
        _responseMessage = 'Authentication cancelled';
        _isSuccess = false;
      });
      return;
    }

    final userPhone =
        _userPhone ?? await IntentService.getUserPhone() ?? '+919999999999';
    final result = await DjangoService.getBalance(userPhone);

    setState(() => _isProcessing = false);

    if (result['status'] == 'success') {
      _showBalanceDialog(result['balance']);
    } else {
      setState(() {
        _responseMessage = result['message'] ?? 'Failed to get balance';
        _isSuccess = false;
      });
    }
  }

  Future<void> _executeMoneyTransfer(Map<String, dynamic> data) async {
    final amount = data['amount'];
    final recipient = data['recipient'];

    final authenticated = await _authenticateWithBiometrics(
      'Authenticate to send ₹$amount',
    );

    if (!authenticated) {
      _showSnackBar('Authentication cancelled', false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _responseMessage = 'Processing transfer...';
    });

    final senderPhone =
        _userPhone ?? await IntentService.getUserPhone() ?? '+919999999999';
    Map<String, dynamic> result;

    if (recipient != null && recipient.contains('@')) {
      result = await DjangoService.sendMoneyByUpiId(
        senderPhone: senderPhone,
        receiverUpi: recipient,
        amount: (amount is int) ? amount.toDouble() : amount,
      );
    } else if (recipient != null) {
      String receiverPhone = recipient.replaceAll(' ', '');
      if (!receiverPhone.startsWith('+91')) {
        receiverPhone = '+91${receiverPhone.replaceAll('+', '')}';
      }
      result = await DjangoService.sendMoneyByPhone(
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        amount: (amount is int) ? amount.toDouble() : amount,
      );
    } else {
      setState(() {
        _isProcessing = false;
        _responseMessage = 'Invalid recipient';
        _isSuccess = false;
      });
      return;
    }

    setState(() => _isProcessing = false);

    if (result['status'] == 'success') {
      _showSuccessDialog('Payment Successful!', '₹$amount sent to $recipient');
    } else {
      _showSnackBar(result['message'] ?? 'Transfer failed', false);
    }
  }

  Future<void> _executeMoneyRequest(Map<String, dynamic> data) async {
    final amount = data['amount'];
    final recipient = data['recipient'];

    final authenticated = await _authenticateWithBiometrics(
      'Authenticate to request ₹${amount ?? "money"}',
    );

    if (!authenticated) {
      _showSnackBar('Authentication cancelled', false);
      return;
    }

    setState(() {
      _isProcessing = true;
      _responseMessage = 'Sending request...';
    });

    final requesterPhone =
        _userPhone ?? await IntentService.getUserPhone() ?? '+919999999999';
    String requesteePhone = recipient?.toString().replaceAll(' ', '') ?? '';
    if (requesteePhone.isNotEmpty && !requesteePhone.startsWith('+91')) {
      requesteePhone = '+91${requesteePhone.replaceAll('+', '')}';
    }

    final result = await DjangoService.createMoneyRequest(
      requesterPhone: requesterPhone,
      requesteePhone: requesteePhone,
      amount: (amount is int) ? amount.toDouble() : (amount ?? 0.0),
    );

    setState(() => _isProcessing = false);

    if (result['status'] == 'success') {
      _showSnackBar('Request sent for ₹$amount', true);
    } else {
      _showSnackBar(result['message'] ?? 'Request failed', false);
    }
  }

  void _showTransferConfirmation(Map<String, dynamic>? data) {
    if (data == null) return;
    final amount = data['amount'] ?? 0;
    final recipient = data['recipient'] ?? 'Unknown';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '₹$amount',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'to $recipient',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeMoneyTransfer(data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRequestConfirmation(Map<String, dynamic>? data) {
    if (data == null) return;
    final amount = data['amount'];
    final recipient = data['recipient'] ?? 'someone';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.request_page_rounded,
                color: AppColors.warning,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Request ₹${amount ?? "money"}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'from $recipient',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeMoneyRequest(data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Send Request'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showBalanceDialog(dynamic balance) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: AppColors.info,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Your Balance',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                '₹$balance',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearResponse() {
    setState(() {
      _spokenText = '';
      _responseMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Voice Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _serverConnected
                                  ? AppColors.success
                                  : AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _serverConnected ? 'Online' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Spacer(),

                  // Speech display area
                  if (_spokenText.isNotEmpty || _isListening)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_isListening)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseController,
                                    builder: (context, child) => Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(
                                          0.5 + _pulseController.value * 0.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Listening...',
                                    style: TextStyle(
                                      color: AppColors.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            _spokenText.isEmpty
                                ? 'Say something...'
                                : '"$_spokenText"',
                            style: TextStyle(
                              fontSize: _spokenText.isEmpty ? 16 : 20,
                              fontWeight: _spokenText.isEmpty
                                  ? FontWeight.normal
                                  : FontWeight.w500,
                              color: _spokenText.isEmpty
                                  ? AppColors.textSecondary
                                  : AppColors.textPrimary,
                              fontStyle: _spokenText.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                  // Response area
                  if (_isProcessing)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _responseMessage ?? 'Processing...',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_responseMessage != null)
                    GestureDetector(
                      onTap: _clearResponse,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isSuccess
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.error.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    (_isSuccess
                                            ? AppColors.success
                                            : AppColors.error)
                                        .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isSuccess
                                    ? Icons.assistant
                                    : Icons.error_outline,
                                color: _isSuccess
                                    ? AppColors.success
                                    : AppColors.error,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _responseMessage!,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Hint text
                  if (!_isListening && _spokenText.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.mic_none_rounded,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tap the mic to start',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try "Send ₹500 to 9876543210"',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary.withOpacity(0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: AvatarGlow(
        animate: _isListening,
        glowColor: _isListening ? AppColors.error : AppColors.primary,
        duration: const Duration(milliseconds: 1500),
        child: GestureDetector(
          onTap: _speechEnabled
              ? (_isListening ? _stopListening : _startListening)
              : null,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isListening
                    ? [AppColors.error, AppColors.error.withRed(200)]
                    : [AppColors.primary, AppColors.primaryDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isListening ? AppColors.error : AppColors.primary)
                      .withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
