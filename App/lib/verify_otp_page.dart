import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'constants/api_constants.dart';
import 'constants/app_colors.dart';

class VerifyOtpPage extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  const VerifyOtpPage({super.key, required this.fullName, required this.phoneNumber});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> with SingleTickerProviderStateMixin {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  String? _info;
  int _resendTimer = 30;
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _sendOtp();
    _startResendTimer();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendTimer = 30;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    setState(() {
      _isSending = true;
      _error = null;
      _info = null;
    });
    final response = await http.get(
      Uri.parse('$SEND_OTP_URL?phone=${widget.phoneNumber}'),
    );
    setState(() {
      _isSending = false;
    });
    if (response.statusCode == 200) {
      setState(() {
        _info = 'OTP sent successfully';
      });
      _startResendTimer();
    } else {
      setState(() {
        _error = 'Failed to send OTP';
      });
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() {
        _error = 'Please enter complete OTP';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final response = await http.get(
      Uri.parse('$VERIFY_OTP_URL?phone=${widget.phoneNumber}&otp=$otp'),
    );
    setState(() {
      _isVerifying = false;
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'Verified') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userPhone', widget.phoneNumber);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/biometric');
        }
      } else {
        setState(() {
          _error = 'Invalid OTP';
        });
        // Clear OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } else {
      setState(() {
        _error = 'Failed to verify OTP';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textWhite),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Header
                _buildHeader(),
                const SizedBox(height: 50),
                
                // OTP Input
                _buildOtpInput(),
                const SizedBox(height: 20),
                
                // Error/Info Message
                if (_error != null || _info != null) ...[
                  _buildMessage(),
                  const SizedBox(height: 20),
                ],
                
                const SizedBox(height: 30),
                
                // Verify Button
                _buildVerifyButton(),
                const SizedBox(height: 30),
                
                // Resend OTP
                _buildResendOtp(),
                
                const Spacer(),
                
                // Help Text
                _buildHelpText(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.lock_outline_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'OTP Verification',
          style: TextStyle(
            color: AppColors.textWhite,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Enter the code sent to',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.phoneNumber,
          style: const TextStyle(
            color: AppColors.primaryPurple,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 50,
          height: 60,
          child: TextField(
            controller: _otpControllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textWhite,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: AppColors.cardBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.cardBackground,
                  width: 2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primaryPurple,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
              
              // Auto verify when all fields are filled
              if (index == 5 && value.isNotEmpty) {
                final otp = _otpControllers.map((c) => c.text).join();
                if (otp.length == 6) {
                  _verifyOtp();
                }
              }
            },
          ),
        );
      }),
    );
  }

  Widget _buildMessage() {
    final isError = _error != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isError ? AppColors.error : AppColors.success).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isError ? AppColors.error : AppColors.success).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? AppColors.error : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isError ? _error! : _info!,
              style: TextStyle(
                color: isError ? AppColors.error : AppColors.success,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isVerifying ? null : _verifyOtp,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isVerifying
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text(
                'Verify OTP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }

  Widget _buildResendOtp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Didn\'t receive the code? ',
          style: TextStyle(
            color: AppColors.textGray,
            fontSize: 14,
          ),
        ),
        if (_resendTimer > 0)
          Text(
            'Resend in $_resendTimer s',
            style: TextStyle(
              color: AppColors.textGrayLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          TextButton(
            onPressed: _isSending ? null : _sendOtp,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
            ),
            child: Text(
              _isSending ? 'Sending...' : 'Resend',
              style: const TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHelpText() {
    return Text(
      'Enter the 6-digit code we sent to your phone number',
      style: TextStyle(
        color: AppColors.textGrayLight,
        fontSize: 12,
      ),
      textAlign: TextAlign.center,
    );
  }
}
