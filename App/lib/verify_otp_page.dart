import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'constants/api_constants.dart';


class VerifyOtpPage extends StatefulWidget {
  final String phoneNumber;
  const VerifyOtpPage({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage>
    with TickerProviderStateMixin {
  // 6-digit OTP boxes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  int _resendTimer = 30;
  Timer? _timer;

  late AnimationController _entranceController;
  late AnimationController _shakeController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _cardSlide;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeController);

    _entranceController.forward();
    _startResendTimer();

    // Focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _entranceController.dispose();
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
      final res = await http.get(
        Uri.parse('$SEND_OTP_URL?phone=${widget.phoneNumber}'),
      );
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
      final response = await http.get(
        Uri.parse('$VERIFY_OTP_URL?phone=${widget.phoneNumber}&otp=$otp'),
      );

      setState(() => _isVerifying = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('phoneNumber', widget.phoneNumber);

          if (data['isNewUser'] == true) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/name-entry',
                arguments: {'phoneNumber': widget.phoneNumber},
              );
            }
          } else {
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('userName', data['upiName']);
            await prefs.setString('upiId', data['upiId']);
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/biometric');
            }
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
    final maskedPhone = widget.phoneNumber.length > 4
        ? widget.phoneNumber.replaceRange(
            0, widget.phoneNumber.length - 4, '•' * (widget.phoneNumber.length - 4))
        : widget.phoneNumber;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Column(
            children: [
              // ── Blue hero ─────────────────────────────────────────
              Expanded(
                flex: 38,
                child: _buildHero(maskedPhone),
              ),

              // ── White bottom card ─────────────────────────────────
              SlideTransition(
                position: _cardSlide,
                child: _buildBottomCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // HERO
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildHero(String maskedPhone) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1),
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF1E88E5),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative glow blobs
          Positioned(
            top: -60,
            right: -60,
            child: _glowCircle(220, const Color(0xFF42A5F5), 0.15),
          ),
          Positioned(
            bottom: 0,
            left: -80,
            child: _glowCircle(200, const Color(0xFF0D47A1), 0.35),
          ),
          // Dot mesh
          Positioned.fill(child: CustomPaint(painter: _DotMeshPainter())),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),

                const Spacer(),

                // OTP sent message
                Text(
                  "We've Sent an OTP on\nyour Mobile No. ${widget.phoneNumber}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Check your SMS inbox',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), color.withOpacity(0.0)],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // BOTTOM CARD
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildBottomCard() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x330D47A1),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          28, 28, 28, MediaQuery.of(context).padding.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'One Time Password:',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: 24),

          // 4 OTP boxes
          _buildOtpBoxes(),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    color: Color(0xFFE53935), size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 32),

          // Resend row + submit button
          Row(
            children: [
              // Resend
              Expanded(
                child: _resendTimer > 0
                    ? RichText(
                        text: TextSpan(
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF9EA8BA)),
                          children: [
                            const TextSpan(text: 'Resend in '),
                            TextSpan(
                              text: '${_resendTimer}s',
                              style: const TextStyle(
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _isSending ? null : _resendOtp,
                        child: Text(
                          _isSending ? 'Sending…' : 'Resend OTP',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isSending
                                ? const Color(0xFF9EA8BA)
                                : const Color(0xFF1565C0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),

              // Circular submit button
              _buildSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // 4 CIRCULAR OTP BOXES
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildOtpBoxes() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        final dx = _shakeController.isAnimating
            ? 8.0 *
                (0.5 -
                    (_shakeAnim.value * 4).round() / 4.0)
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFoc
                ? const Color(0xFFEAF2FF)
                : const Color(0xFFF0F4FA),
            border: Border.all(
              color: isFoc
                  ? const Color(0xFF1565C0)
                  : const Color(0xFFD8E2F0),
              width: isFoc ? 2 : 1.5,
            ),
            boxShadow: isFoc
                ? [
                    BoxShadow(
                      color: const Color(0xFF1565C0).withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : [],
          ),
          child: Center(
            child: TextField(
              controller: _otpControllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              obscureText: true,
              obscuringCharacter: '●',
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 22,
                fontWeight: FontWeight.w700,
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
                // Auto-submit when all 6 filled
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

  // ──────────────────────────────────────────────────────────────────────
  // SUBMIT BUTTON
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF42A5F5).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _isVerifying ? null : _verifyOtp,
          child: Center(
            child: _isVerifying
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Dot mesh painter (same as phone_number_page)
// ──────────────────────────────────────────────────────────────────────────────
class _DotMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.055)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.5;

    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
