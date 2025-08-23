import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      Navigator.pushReplacementNamed(context, '/biometric');
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAlreadySignedUp();
  }

  Future<void> _submitSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await http.post(
        Uri.parse('http://172.16.204.240:8000/accounts/signup/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'upiName': _nameController.text,
          'phoneNumber': _phoneController.text,
        }),
      );
      setState(() {
        _isLoading = false;
      });
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSignedUp', true);
        await prefs.setString('signedUpPhoneNumber', _phoneController.text);
        Navigator.pushReplacementNamed(
          context,
          '/biometric',
        );
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _error = data['error'] ?? 'Signup failed';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter your full name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Enter your phone number' : null,
              ),
              const SizedBox(height: 32),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
              ],
              ElevatedButton(
                onPressed: _isLoading ? null : _submitSignup,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
