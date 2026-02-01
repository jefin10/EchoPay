import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';

class PayToUpiIdPage extends StatefulWidget {
  final String? prefilledUpiId;
  final String? prefilledAmount;
  final String? prefilledName;
  
  const PayToUpiIdPage({
    Key? key,
    this.prefilledUpiId,
    this.prefilledAmount,
    this.prefilledName,
  }) : super(key: key);

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
        final data = json.decode(response.body);
        setState(() {
          _userData = data;
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

    setState(() {
      _loading = true;
    });

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
        setState(() {
          _loading = false;
        });
        _showPaymentSuccessDialog();
      } else {
        setState(() {
          _loading = false;
        });
        final data = json.decode(response.body);
        _showSnackBar(data['error'] ?? 'Payment failed.');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showSnackBar('Payment failed: $e');
    }
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '₹${_amountController.text} sent to ${_userData!['upiName']}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Done', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pay to UPI ID',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _upiController,
                    hint: 'Enter UPI ID (e.g., user@upi)',
                    keyboardType: TextInputType.emailAddress,
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Colors.white),
                      onPressed: _searchUser,
                    ),
                    isDark: true,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_userData != null) ...[
                    _buildUserInfoCard(),
                    const SizedBox(height: 20),
                  ],
                  if (_error != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildInputField(
                    controller: _amountController,
                    label: 'Amount',
                    hint: 'Enter amount',
                    keyboardType: TextInputType.number,
                    prefixText: '₹ ',
                  ),
                  const SizedBox(height: 16),
                  _buildInputField(
                    controller: _remarkController,
                    label: 'Note (Optional)',
                    hint: 'Add a note',
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_userData != null && !_loading) ? _processPayment : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : const Text(
                              'Pay Now',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    String? label,
    required String hint,
    required TextInputType keyboardType,
    Widget? suffixIcon,
    String? prefixText,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: isDark ? Colors.white60 : AppColors.textSecondary),
            prefixText: prefixText,
            prefixStyle: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 16),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.15) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDark ? BorderSide.none : const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: isDark ? BorderSide.none : const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: isDark ? Colors.white : AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Text(
                (_userData!['upiName'] ?? 'U')[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData!['upiName'] ?? 'Unknown User',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _userData!['phoneNumber'] ?? 'N/A',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.verified, color: AppColors.success, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
