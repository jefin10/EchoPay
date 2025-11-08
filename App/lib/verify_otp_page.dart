import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/api_constants.dart';

class VerifyOtpPage extends StatefulWidget {
  final String fullName;
  final String phoneNumber;
  const VerifyOtpPage({super.key, required this.fullName, required this.phoneNumber});

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  bool _isSending = false;
  String? _error;
  String? _info;

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
        _info = 'OTP sent to ${widget.phoneNumber}';
      });
    } else {
      setState(() {
        _error = 'Failed to send OTP';
      });
    }
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final response = await http.get(
      Uri.parse('$VERIFY_OTP_URL?phone=${widget.phoneNumber}&otp=${_otpController.text}'),
    );
    setState(() {
      _isVerifying = false;
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'Verified') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        // Save user phone number for voice assistant
        await prefs.setString('userPhone', widget.phoneNumber);
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/biometric');
        }
      } else {
        setState(() {
          _error = 'Invalid OTP';
        });
      }
    } else {
      setState(() {
        _error = 'Failed to verify OTP';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Enter OTP sent to ${widget.phoneNumber}'),
            const SizedBox(height: 16),
            if (_info != null) ...[
              Text(_info!, style: const TextStyle(color: Colors.green)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: 'OTP'),
              keyboardType: TextInputType.number,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _isSending ? null : _sendOtp,
                  child: _isSending ? const CircularProgressIndicator() : const Text('Resend OTP'),
                ),
                ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyOtp,
                  child: _isVerifying ? const CircularProgressIndicator() : const Text('Verify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
