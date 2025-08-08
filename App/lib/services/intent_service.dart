import 'dart:convert';
import 'package:http/http.dart' as http;

class IntentService {
  static const String _baseUrl = 'http://172.16.204.240:5002'; // For Android emulator
  // static const String _baseUrl = 'http://localhost:5000'; // For iOS simulator or real device on same network
  
  static Future<Map<String, dynamic>?> predictIntent(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Network error: $e');
      return null;
    }
  }

  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
