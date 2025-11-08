import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class PayToPhonenumberPage extends StatelessWidget {
  const PayToPhonenumberPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PayToPhonenumberBody();
  }
}

class PayToPhonenumberBody extends StatefulWidget {
  @override
  State<PayToPhonenumberBody> createState() => PayToPhonenumberBodyState();
}

class PayToPhonenumberBodyState extends State<PayToPhonenumberBody> {
  void _showPaymentSuccessDialog(double amount, String recipientName) {
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
                '₹${amount.toStringAsFixed(2)} sent to $recipientName',
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
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _remarkController = TextEditingController();
  bool _loading = false;
  bool _sending = false;
  String? _error;
  String? _sendResult;
  Map<String, dynamic>? _userData;

  Future<void> _searchUser() async {
    setState(() {
      _loading = true;
      _error = null;
      _userData = null;
      _sendResult = null;
    });
    final phoneNumber = _controller.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter a phone number.';
      });
      return;
    }
    try {
      // TODO: Replace with your actual backend URL
      final url = Uri.parse('$SEARCH_BY_PHONE_URL?phoneNumber=$phoneNumber');
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

  Future<void> _sendMoney() async {
    if (_userData == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() {
        _sendResult = 'Please enter a valid amount.';
      });
      return;
    }
    setState(() {
      _sending = true;
      _sendResult = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final senderPhone = prefs.getString('signedUpPhoneNumber') ?? '';
      final receiverPhone = _controller.text.trim();
      final remark = _remarkController.text.trim();
      final url = Uri.parse(SEND_MONEY_PHONE_URL);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPhone': senderPhone,
          'receiverPhone': receiverPhone,
          'amount': amount,
          'remark': remark,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          _sendResult = 'Payment successful!';
          _sending = false;
        });
        _showPaymentSuccessDialog(amount, _userData!['upiName'] ?? receiverPhone);
      } else {
        final data = json.decode(response.body);
        setState(() {
          _sendResult = data['error'] ?? 'Payment failed.';
          _sending = false;
        });
      }
    } catch (e) {
      setState(() {
        _sendResult = 'Error: $e';
        _sending = false;
      });
    }
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
        title: const Text('Pay to Phone Number', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInputField(
              controller: _controller,
              label: 'Phone Number',
              hint: 'Enter phone number',
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
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
                        side: const BorderSide(color: Color(0xFF6366F1), width: 1),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Search User'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_error != null) _buildErrorCard(_error!),
            if (_userData != null) _buildUserInfoCard(),
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2B5A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Icon(Icons.person, color: Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_userData!['upiName'] ?? 'Unknown User', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Text(_userData!['upiId'] ?? 'N/A', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.verified_user, color: Color(0xFF10B981), size: 20),
            ],
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _amountController,
            label: 'Amount',
            hint: 'Enter amount to send',
            keyboardType: TextInputType.number,
            prefixText: '₹ ',
          ),
          const SizedBox(height: 15),
          _buildInputField(
            controller: _remarkController,
            label: 'Remark (Optional)',
            hint: 'Add a note for this payment',
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _sending ? null : _sendMoney,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _sending
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Send Money', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (_sendResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _sendResult!,
                style: TextStyle(color: _sendResult == 'Payment successful!' ? Color(0xFF10B981) : Color(0xFFEF4444)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
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
          const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
