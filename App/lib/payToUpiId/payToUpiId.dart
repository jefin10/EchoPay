import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../constants/api_constants.dart';

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
    // Prefill data if provided from QR scan
    if (widget.prefilledUpiId != null) {
      _upiController.text = widget.prefilledUpiId!;
      _searchUser(); // Auto-search if UPI ID is prefilled
    }
    if (widget.prefilledAmount != null) {
      _amountController.text = widget.prefilledAmount!;
    }
    if (widget.prefilledName != null) {
      // If name is provided from QR, create mock user data
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
      // TODO: Replace with your actual backend URL
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
      // Get sender phone number from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final senderPhone = prefs.getString('signedUpPhoneNumber') ?? '';
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
          backgroundColor: const Color(0xFF2A2B5A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Color(0xFF10B981),
                size: 60,
              ),
              const SizedBox(height: 20),
              const Text(
                'Payment Successful!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '₹${_amountController.text} sent to ${_userData!['upiName']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Go back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Done'),
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
        backgroundColor: const Color(0xFF2A2B5A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B3A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pay to UPI ID',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // UPI ID Input
            _buildInputField(
              controller: _upiController,
              label: 'UPI ID',
              hint: 'Enter UPI ID (e.g., user@paytm)',
              keyboardType: TextInputType.emailAddress,
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                onPressed: _searchUser,
              ),
            ),
            const SizedBox(height: 20),

            // User Info Card
            if (_userData != null) _buildUserInfoCard(),
            
            if (_error != null) _buildErrorCard(),

            const SizedBox(height: 20),

            // Amount Input
            _buildInputField(
              controller: _amountController,
              label: 'Amount',
              hint: 'Enter amount to send',
              keyboardType: TextInputType.number,
              prefixText: '₹ ',
            ),
            const SizedBox(height: 20),

            // Remark Input
            _buildInputField(
              controller: _remarkController,
              label: 'Remark (Optional)',
              hint: 'Add a note for this payment',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _searchUser,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2B5A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Search User'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_userData != null && !_loading) ? _processPayment : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Send Money',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: Colors.white),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFF2A2B5A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.2),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.person,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userData!['upiName'] ?? 'Unknown User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _userData!['phoneNumber'] ?? 'N/A',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.verified_user,
            color: Color(0xFF10B981),
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Color(0xFFEF4444),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
