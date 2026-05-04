import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/api_constants.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _checkAlreadySignedUp() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('isSignedUp') ?? false) {
      if (mounted) Navigator.pushReplacementNamed(context, '/biometric');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAlreadySignedUp();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await http.post(
      Uri.parse(SIGNUP_URL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'upiName': _nameController.text,
        'phoneNumber': _phoneController.text,
      }),
    );
    setState(() => _isLoading = false);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSignedUp', true);
      await prefs.setString('signedUpPhoneNumber', _phoneController.text);
      if (mounted) Navigator.pushReplacementNamed(context, '/biometric');
    } else {
      final data = jsonDecode(response.body);
      setState(() => _error = data['error'] ?? 'Signup failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'create',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Set up\nyour wallet.',
                  style: AppTypography.heading(
                    size: 38,
                    weight: FontWeight.w800,
                  ).copyWith(height: 1.05),
                ),
                const SizedBox(height: 14),
                Text(
                  'Just two details to get going.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                _buildLabel('Full name'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _nameController,
                  hint: 'Your full name',
                  keyboardType: TextInputType.name,
                  validator: (value) =>
                      value == null || value.isEmpty
                          ? 'Please enter your name'
                          : null,
                ),
                const SizedBox(height: 22),

                _buildLabel('Mobile number'),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _phoneController,
                  hint: '10-digit number',
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length != 10) {
                      return 'Phone number must be 10 digits';
                    }
                    return null;
                  },
                ),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorChip(_error!),
                ],

                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitSignup,
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
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 14),
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          counterText: '',
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
        validator: validator,
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
