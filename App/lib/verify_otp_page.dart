import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'constants/api_constants.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';

class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;
  const VerifyOtpPage({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage>
    with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  int _resendTimer = 30;
  Timer? _timer;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeController);
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendTimer = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          t.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    if (_isSending) return;
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      final uri = Uri.parse(SEND_OTP_URL).replace(
        queryParameters: {'phone': widget.phoneNumber},
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) _startResendTimer();
    } catch (_) {}
    setState(() => _isSending = false);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      _triggerShake('Please enter the complete OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final uri = Uri.parse(VERIFY_OTP_URL).replace(
        queryParameters: {'phone': widget.phoneNumber, 'otp': otp},
      );
      final response = await http.get(uri);
      setState(() => _isVerifying = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('phoneNumber', widget.phoneNumber);

          if (data['isNewUser'] == true) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(
              context,
              '/name-entry',
              arguments: {'phoneNumber': widget.phoneNumber},
            );
          } else {
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userName', data['upiName']);
            await prefs.setString('upiId', data['upiId']);
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/biometric');
          }
        } else {
          _triggerShake(data['message'] ?? 'Invalid OTP');
        }
      } else {
        _triggerShake('Failed to verify OTP');
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  void _triggerShake(String message) {
    setState(() => _error = message);
    for (var c in _otpControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 28),

                Text(
                  'verify',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the\n6-digit code.',
                  style: AppTypography.heading(
                    size: 38,
                    weight: FontWeight.w800,
                  ).copyWith(height: 1.05),
                ),
                const SizedBox(height: 14),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'Sent to '),
                      TextSpan(
                        text: widget.phoneNumber,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const TextSpan(text: '. Check your messages.'),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                _buildOtpRow(),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorChip(_error!),
                ],

                const SizedBox(height: 24),
                _buildResendRow(),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Verify & continue'),
                              SizedBox(width: 10),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.ink,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildOtpRow() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = _shakeController.isAnimating
            ? 8.0 * (0.5 - (_shakeAnim.value * 4).round() / 4.0)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(6, (i) => _buildOtpBox(i)),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return ListenableBuilder(
      listenable: _focusNodes[index],
      builder: (context, _) {
        final isFoc = _focusNodes[index].hasFocus;
        final hasValue = _otpControllers[index].text.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 46,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isFoc
                  ? AppColors.ink
                  : hasValue
                      ? AppColors.borderStrong
                      : AppColors.border,
              width: isFoc ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {});
                if (val.isNotEmpty && index < 5) {
                  _focusNodes[index + 1].requestFocus();
                } else if (val.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
                if (index == 5 && val.isNotEmpty) {
                  final otp = _otpControllers.map((c) => c.text).join();
                  if (otp.length == 6) _verifyOtp();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildResendRow() {
    return Row(
      children: [
        Text(
          "Didn't get it?",
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        if (_resendTimer > 0)
          Text(
            'Resend in ${_resendTimer}s',
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          )
        else
          GestureDetector(
            onTap: _isSending ? null : _resendOtp,
            child: Text(
              _isSending ? 'Sending' : 'Resend code',
              style: TextStyle(
                color: _isSending ? AppColors.textMuted : AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                decoration: _isSending ? null : TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorChip(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.coral.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.coral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.coral, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.coral,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
