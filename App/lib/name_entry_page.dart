import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/api_constants.dart';
import 'constants/app_colors.dart';
import 'constants/app_typography.dart';

class NameEntryPage extends StatefulWidget {
  final String phoneNumber;
  const NameEntryPage({super.key, required this.phoneNumber});

  @override
  State<NameEntryPage> createState() => _NameEntryPageState();
}

class _NameEntryPageState extends State<NameEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse(SIGNUP_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'upiName': _nameController.text,
          'phoneNumber': widget.phoneNumber,
        }),
      );
      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('phoneNumber', widget.phoneNumber);
          await prefs.setString('userName', data['upiName']);
          await prefs.setString('upiId', data['upiId']);

          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/biometric');
        } else {
          setState(() => _error = data['error'] ?? 'Failed to create account');
        }
      } else {
        final data = jsonDecode(response.body);
        setState(() => _error = data['error'] ?? 'Failed to create account');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Network error. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackButton(),
                const SizedBox(height: 28),

                Text(
                  'one last step',
                  style: AppTypography.eyebrow(color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  'What should\nwe call you?',
                  style: AppTypography.heading(
                    size: 38,
                    weight: FontWeight.w800,
                  ).copyWith(height: 1.05),
                ),
                const SizedBox(height: 14),
                Text(
                  'Your name appears on your UPI handle and receipts.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 36),

                _buildNameInput(),

                if (_error != null) ...[
                  const SizedBox(height: 14),
                  _buildErrorChip(_error!),
                ],

                const SizedBox(height: 24),
                _buildPerk(),

                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
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
                              Text('Create account'),
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

  Widget _buildNameInput() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: _nameController,
        focusNode: _nameFocusNode,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        decoration: const InputDecoration(
          hintText: 'Your full name',
          hintStyle: TextStyle(
            color: AppColors.textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your name';
          }
          if (value.length < 2) {
            return 'Name must be at least 2 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPerk() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 18, 14),
      decoration: BoxDecoration(
        color: AppColors.popSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.pop.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.pop,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.ink,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'welcome bonus',
                  style: AppTypography.eyebrow(
                    color: AppColors.ink,
                    size: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '₹5,000 ready to spend',
                  style: AppTypography.heading(size: 15),
                ),
              ],
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
