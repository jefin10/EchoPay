/// Example: How to use API Constants
/// 
/// This file shows you how to use the constants in your files

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'constants/api_constants.dart';

// Example 1: Simple GET request with query parameters
Future<void> getProfileExample(String phoneNumber) async {
  final url = Uri.parse('$GET_PROFILE_URL?phoneNumber=$phoneNumber');
  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print(data);
  }
}

// Example 2: POST request with body
Future<void> sendMoneyExample() async {
  final url = Uri.parse(SEND_MONEY_PHONE_URL);
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'senderPhone': '1234567890',
      'receiverPhone': '0987654321',
      'amount': 500,
    }),
  );
  
  if (response.statusCode == 200) {
    print('Money sent successfully!');
  }
}

// Example 3: Using the constants directly
void printUrls() {
  print('Django API: $DJANGO_BASE_URL');
  print('Intent API: $INTENT_API_URL');
  print('Signup URL: $SIGNUP_URL');
}

// To use in your files:
// 1. Import the constants: import '../constants/api_constants.dart';
// 2. Use the constant directly: Uri.parse(GET_BALANCE_URL)
// 3. Add query params: Uri.parse('$GET_PROFILE_URL?phoneNumber=$phone')
