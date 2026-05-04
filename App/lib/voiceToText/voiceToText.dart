import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/intent_service.dart';
import '../services/django_service.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

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
      duration: const Duration(milliseconds: 900),
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
    _userPhone = prefs.getString('phoneNumber');
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
      _showSuccessDialog('Payment sent', '₹$amount to $recipient');
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('voice pay', style: AppTypography.eyebrow()),
            const SizedBox(height: 10),
            Text(
              '₹$amount',
              style: AppTypography.amount(size: 42),
            ),
            const SizedBox(height: 4),
            Text(
              'to $recipient',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.borderStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeMoneyTransfer(data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
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
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text('request money', style: AppTypography.eyebrow()),
            const SizedBox(height: 10),
            Text(
              '₹${amount ?? '?'}',
              style: AppTypography.amount(size: 42),
            ),
            const SizedBox(height: 4),
            Text(
              'from $recipient',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.borderStrong),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _executeMoneyRequest(data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Send Request',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBalanceDialog(dynamic balance) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDim,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.ink,
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),
              Text('wallet balance', style: AppTypography.eyebrow()),
              const SizedBox(height: 8),
              Text(
                '₹$balance',
                style: AppTypography.amount(size: 40),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.mint,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: AppTypography.heading(size: 20)),
              const SizedBox(height: 4),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
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
        backgroundColor: isSuccess ? AppColors.mint : AppColors.coral,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    if (_spokenText.isNotEmpty || _isListening) _speechCard(),
                    if (_isProcessing)
                      _processingCard()
                    else if (_responseMessage != null)
                      _responseCard(),
                    const Spacer(),
                    if (!_isListening && _spokenText.isEmpty && !_isProcessing)
                      _idleHint(),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _micButton(),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: AppColors.ink, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Text('voice pay', style: AppTypography.heading(size: 18)),
          const Spacer(),
          _statusChip(),
        ],
      ),
    );
  }

  Widget _statusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: _serverConnected ? AppColors.mint : AppColors.coral,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _serverConnected ? 'online' : 'offline',
            style: AppTypography.eyebrow(
              color: _serverConnected ? AppColors.mint : AppColors.coral,
              size: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _speechCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.pop.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) => Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.pop.withOpacity(
                          0.5 + _pulseController.value * 0.5,
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'listening',
                    style: AppTypography.eyebrow(
                      color: AppColors.ink,
                      size: 10,
                    ),
                  ),
                ],
              ),
            ),
          Text(
            _spokenText.isEmpty ? 'say something...' : '"$_spokenText"',
            style: _spokenText.isEmpty
                ? TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  )
                : AppTypography.heading(size: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _processingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            _responseMessage ?? 'processing...',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _responseCard() {
    return GestureDetector(
      onTap: _clearResponse,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isSuccess
                ? AppColors.mint.withOpacity(0.4)
                : AppColors.coral.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _isSuccess
                    ? AppColors.mint.withOpacity(0.1)
                    : AppColors.coral.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _isSuccess ? Icons.assistant_rounded : Icons.error_outline_rounded,
                color: _isSuccess ? AppColors.mint : AppColors.coral,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _responseMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const Icon(Icons.close_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _idleHint() {
    return Column(
      children: [
        Text('voice pay', style: AppTypography.eyebrow()),
        const SizedBox(height: 10),
        Text(
          'Just say what\nyou want to do.',
          textAlign: TextAlign.center,
          style: AppTypography.heading(size: 26, weight: FontWeight.w800)
              .copyWith(height: 1.1),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _sampleChip('Send ₹500 to 98765'),
            _sampleChip('What\'s my balance?'),
            _sampleChip('Request ₹200 from John'),
          ],
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _sampleChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _micButton() {
    return GestureDetector(
      onTap: _speechEnabled
          ? (_isListening ? _stopListening : _startListening)
          : null,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = _isListening
              ? 1.0 + _pulseController.value * 0.06
              : 1.0;
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: _isListening ? AppColors.coral : AppColors.ink,
            borderRadius: BorderRadius.circular(22),
            border: _isListening
                ? Border.all(color: AppColors.coral.withOpacity(0.3), width: 3)
                : null,
          ),
          child: Icon(
            _isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: _isListening ? Colors.white : AppColors.pop,
            size: 30,
          ),
        ),
      ),
    );
  }
}
