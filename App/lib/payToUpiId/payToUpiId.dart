import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PayToUpiIdPage extends StatefulWidget {
  const PayToUpiIdPage({Key? key}) : super(key: key);

  @override
  State<PayToUpiIdPage> createState() => _PayToUpiIdPageState();
}

class _PayToUpiIdPageState extends State<PayToUpiIdPage> {
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
    final upiId = _controller.text.trim();
    if (upiId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please enter a UPI ID.';
      });
      return;
    }
    try {
      // TODO: Replace with your actual backend URL
      final url = Uri.parse('http://10.0.2.2:8000/accounts/searchByUpiId/?upiId=$upiId');
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
        title: const Text('Pay to UPI ID'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'Enter UPI ID',
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
                  subtitle: Text('Phone Number: ${_userData!['phoneNumber'] ?? ''}'),
                  trailing: const Icon(Icons.account_circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
