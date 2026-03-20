import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants/api_constants.dart';
import 'verify_otp_page.dart';

import 'widgets/app_logo.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final List<String> _countryCodes = const ['+91', '+1', '+44', '+61', '+971'];
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  String? _error;
  bool _isFocused = false;

  late AnimationController _entranceController;
  late AnimationController _floatController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _cardSlide;
  late Animation<double> _logoFloat;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    )..repeat(reverse: true);

    _fadeIn = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Curves.easeOutCubic,
          ),
        );
    _logoFloat = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _entranceController.forward();

    _phoneFocusNode.addListener(() {
      setState(() => _isFocused = _phoneFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final fullPhoneNumber =
          '$_selectedCountryCode${_phoneController.text.trim()}';

      try {
        final response = await http.get(
          Uri.parse('$SEND_OTP_URL?phone=$fullPhoneNumber'),
        );

        setState(() => _isLoading = false);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'success') {
            if (mounted) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: const Duration(milliseconds: 500),
                  reverseTransitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return VerifyOtpPage(phoneNumber: fullPhoneNumber);
                  },
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    final tween = Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).chain(CurveTween(curve: Curves.easeOutCubic));
                    final fade = Tween<double>(begin: 0.0, end: 1.0)
                        .chain(CurveTween(curve: Curves.easeOut));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: FadeTransition(
                        opacity: animation.drive(fade),
                        child: child,
                      ),
                    );
                  },
                  settings: RouteSettings(
                    arguments: {'phoneNumber': fullPhoneNumber},
                  ),
                ),
              );
            }
          } else {
            setState(() => _error = data['message'] ?? 'Failed to send OTP');
          }
        } else {
          setState(() => _error = 'Failed to send OTP. Please try again.');
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _error = 'Network error. Please check your connection.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Blue hero section ──────────────────────────────
                Expanded(flex: 62, child: _buildHero(size)),

                // ── White bottom card ──────────────────────────────
                SlideTransition(
                  position: _cardSlide,
                  child: _buildBottomCard(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // HERO
  // ──────────────────────────────────────────────────────────────────────
  Widget _buildHero(Size size) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D47A1), // deep navy blue
            Color(0xFF1565C0),
            Color(0xFF1976D2),
            Color(0xFF1E88E5),
          ],
          stops: [0.0, 0.35, 0.70, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Decorative circle top-right
          Positioned(
            top: -size.width * 0.25,
            right: -size.width * 0.2,
            child: _glowCircle(size.width * 0.7, const Color(0xFF42A5F5), 0.18),
          ),
          // Decorative circle bottom-left
          Positioned(
            bottom: size.height * 0.02,
            left: -size.width * 0.25,
            child: _glowCircle(size.width * 0.6, const Color(0xFF0D47A1), 0.35),
          ),
          // Fine dot mesh overlay
          Positioned.fill(child: _meshOverlay()),

          // Logo — centered, floating (no SafeArea so gradient bleeds under status bar)
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              child: Center(
                child: AnimatedBuilder(
                  animation: _logoFloat,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _logoFloat.value),
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.14),
                          blurRadius: 70,
                          spreadRadius: 24,
                        ),
                        BoxShadow(
                          color: const Color(0xFF42A5F5).withOpacity(0.32),
                          blurRadius: 90,
                          spreadRadius: 12,
                        ),
                      ],
                    ),
                    child: AppLogo(
                      type: LogoType.full,
                      width: 300,
                      height: 200,
                    ),
                  ),
                ),
              ),
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

  Widget _meshOverlay() {
    return CustomPaint(painter: _DotMeshPainter());
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
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          const Text(
            'Phone Number',
            style: TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 10),

          // Input row
          _buildPhoneInput(),

          const SizedBox(height: 4),

          // Animated underline
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isFocused ? 2 : 1,
            decoration: BoxDecoration(
              gradient: _isFocused
                  ? const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    )
                  : const LinearGradient(
                      colors: [Color(0xFFDDE3EE), Color(0xFFDDE3EE)],
                    ),
              borderRadius: BorderRadius.circular(1),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFE53935),
                  size: 14,
                ),
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

          const SizedBox(height: 28),

          // Continue button — right-aligned circular
          Align(
            alignment: Alignment.centerRight,
            child: _buildContinueButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Country code
        Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.white),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(0xFF1565C0),
              ),
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCountryCode = value);
                }
              },
              items: _countryCodes
                  .map(
                    (code) => DropdownMenuItem<String>(
                      value: code,
                      child: Text(code),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),

        // Vertical divider
        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: const Color(0xFFCDD5E0),
        ),

        // Phone field
        Expanded(
          child: TextFormField(
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            style: const TextStyle(
              color: Color(0xFF1A1A2E),
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Enter mobile number',
              hintStyle: TextStyle(
                color: const Color(0xFF9EA8BA),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              counterText: '',
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              if (value.length != 10) {
                return 'Phone number must be 10 digits';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
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
          onTap: _isLoading ? null : _sendOtp,
          child: Center(
            child: _isLoading
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
// Subtle dot-mesh overlay painter for the hero section
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
