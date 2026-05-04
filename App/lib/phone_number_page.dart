import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants/api_constants.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';
import 'verify_otp_page.dart';
import 'widgets/app_logo.dart';

class PhoneNumberPage extends StatefulWidget {
  const PhoneNumberPage({super.key});

  @override
  State<PhoneNumberPage> createState() => _PhoneNumberPageState();
}

class _PhoneNumberPageState extends State<PhoneNumberPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  final List<String> _countryCodes = const ['+91', '+1', '+44', '+61', '+971'];
  String _selectedCountryCode = '+91';
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';

    try {
      final uri = Uri.parse(SEND_OTP_URL).replace(
        queryParameters: {'phone': fullPhoneNumber},
      );
      final response = await http.get(uri);
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VerifyOtpPage(phoneNumber: fullPhoneNumber),
              settings: RouteSettings(
                arguments: {'phoneNumber': fullPhoneNumber},
              ),
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top brand row — small, deliberate
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: const AppLogo(type: LogoType.iconOnly),
                      ),
                      const SizedBox(width: 10),
                      Text('EchoPay', style: AppTypography.heading(size: 17)),
                    ],
                  ),
                  const SizedBox(height: 56),

                  Text(
                    'sign in',
                    style: AppTypography.eyebrow(color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "What's your\nphone number?",
                    style: AppTypography.heading(
                      size: 38,
                      weight: FontWeight.w800,
                    ).copyWith(height: 1.05),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'We will send a one-time code to verify it.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 40),

                  _buildPhoneRow(),

                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    _buildErrorChip(_error!),
                  ],

                  const Spacer(),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
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
                                Text('Send code'),
                                SizedBox(width: 10),
                                Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      'By continuing you agree to our Terms & Privacy.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneRow() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCountryCode,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.ink,
              ),
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              borderRadius: BorderRadius.circular(12),
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
          Container(
            width: 1.5,
            height: 28,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: AppColors.border,
          ),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocusNode,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                hintText: 'Mobile number',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                counterText: '',
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
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
      ),
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
