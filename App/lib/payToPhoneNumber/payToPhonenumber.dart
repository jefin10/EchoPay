import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _userData;

  Future<void> _searchUser() async {
    setState(() {
      _loading = true;
      _error = null;
      _userData = null;
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
      final url = Uri.parse('http://10.0.2.2:8000/accounts/searchPhonenumber/?phoneNumber=$phoneNumber');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay to Phone Number'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Enter phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _searchUser,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Search'),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            if (_userData != null)
              Card(
                elevation: 2,
                child: ListTile(
                  title: Text('UPI Name: ${_userData!['upiName'] ?? ''}'),
                  subtitle: Text('UPI ID: ${_userData!['upiId'] ?? ''}'),
                  trailing: const Icon(Icons.account_circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
