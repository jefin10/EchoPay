import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class PayToUpiIdPage extends StatefulWidget {
  final String? prefilledUpiId;
  final String? prefilledAmount;
  final String? prefilledName;

  const PayToUpiIdPage({
    super.key,
    this.prefilledUpiId,
    this.prefilledAmount,
    this.prefilledName,
  });

  @override
  State<PayToUpiIdPage> createState() => _PayToUpiIdPageState();
}

class _PayToUpiIdPageState extends State<PayToUpiIdPage> {
  final TextEditingController _upiController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUpiId != null) {
      _upiController.text = widget.prefilledUpiId!;
      _searchUser();
    }
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!;
    }
    if (widget.prefilledName != null) {
      _userData = {
        'upiName': widget.prefilledName,
        'phoneNumber': 'N/A',
        'upiId': widget.prefilledUpiId,
      };
    }
  }

  Future<void> _searchUser() async {
    setState(() {
      _loading = true;
      _error = null;
      _userData = null;
    });
    final upiId = _upiController.text.trim();
    if (upiId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter a UPI ID.';
      });
      return;
    }
    try {
      final url = Uri.parse('$SEARCH_BY_UPI_URL?upiId=$upiId');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body);
          _loading = false;
        });
      } else {
        final data = json.decode(response.body);
        setState(() {
          _error = data['error'] ?? 'User not found.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_userData == null || _amountController.text.trim().isEmpty) {
      _showSnackBar('Please complete all required fields');
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnackBar('Please enter a valid amount');
      return;
    }
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderPhone = prefs.getString('phoneNumber') ?? '';
      final receiverUpi = _upiController.text.trim();
      final remark = _remarkController.text.trim();

      final url = Uri.parse(SEND_MONEY_ID_URL);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPhone': senderPhone,
          'receiverUpi': receiverUpi,
          'amount': amount,
          'remark': remark,
        }),
      );

      if (response.statusCode == 200) {
        setState(() => _loading = false);
        if (mounted) _showPaymentSuccessDialog();
      } else {
        setState(() => _loading = false);
        final data = json.decode(response.body);
        _showSnackBar(data['error'] ?? 'Payment failed.');
      }
    } catch (e) {
      setState(() => _loading = false);
      _showSnackBar('Payment failed: $e');
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.mint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_rounded,
                    color: AppColors.mint, size: 32),
              ),
              const SizedBox(height: 18),
              Text('Payment sent', style: AppTypography.heading(size: 22)),
              const SizedBox(height: 4),
              Text(
                '₹${_amountController.text} to ${_userData!['upiName']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _topBar(),
              const SizedBox(height: 22),
              Text('to a upi id', style: AppTypography.eyebrow()),
              const SizedBox(height: 6),
              Text(
                'Pay any\nUPI handle.',
                style: AppTypography.heading(size: 30, weight: FontWeight.w800)
                    .copyWith(height: 1.05),
              ),
              const SizedBox(height: 22),
              _searchField(),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _errorChip(_error!),
              ],
              if (_userData != null) ...[
                const SizedBox(height: 22),
                _userInfoCard(),
              ],
              const SizedBox(height: 22),
              _label('Amount'),
              const SizedBox(height: 8),
              _input(_amountController, '0', TextInputType.number, prefix: '₹ '),
              const SizedBox(height: 16),
              _label('Note (optional)'),
              const SizedBox(height: 8),
              _input(_remarkController, 'Add a note', TextInputType.text),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_userData != null && !_loading) ? _processPayment : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.borderStrong,
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Pay now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Row(
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
        Text('pay to upi id', style: AppTypography.heading(size: 18)),
      ],
    );
  }

  Widget _searchField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderStrong, width: 1.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.alternate_email_rounded,
              color: AppColors.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _upiController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'someone@upi',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          GestureDetector(
            onTap: _loading ? null : _searchUser,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded,
                      color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _userInfoCard() {
    final name = _userData!['upiName'] ?? 'Unknown user';
    final phone = _userData!['phoneNumber'] ?? 'N/A';
    final initial = name.isNotEmpty ? name[0].toString().toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surfaceDim,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: const TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppTypography.heading(size: 16)),
                const SizedBox(height: 2),
                Text(
                  phone,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.mint.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded,
                    color: AppColors.mint, size: 12),
                const SizedBox(width: 4),
                Text(
                  'verified',
                  style: AppTypography.eyebrow(
                    color: AppColors.mint,
                    size: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      );

  Widget _input(
    TextEditingController controller,
    String hint,
    TextInputType keyboardType, {
    String? prefix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _errorChip(String message) {
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
