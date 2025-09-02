import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IntentService {
  // static const String _baseUrl = 'http://172.16.204.240:5002'; // For Android emulator
  static const String _baseUrl = 'http://172.16.192.54:5002'; // For iOS simulator or real device on same network
  
  // Enhanced voice command processing
  static Future<Map<String, dynamic>?> processVoiceCommand(String text) async {
    try {
      // Get user phone number from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final userPhone = prefs.getString('userPhone') ?? '+919999999999';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/voice_command'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'userPhone': userPhone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return {
          'status': 'error',
          'error': 'Server error: ${response.statusCode}',
          'assistant_message': 'Sorry, I encountered an error processing your request.'
        };
      }
    } catch (e) {
      print('Network error: $e');
      return {
        'status': 'error',
        'error': 'Network error: $e',
        'assistant_message': 'Sorry, I cannot connect to the server right now.'
      };
    }
  }
  
  // Legacy method for backward compatibility
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

  // Direct chatbot interaction
  static Future<Map<String, dynamic>?> getChatbotResponse(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chatbot'),
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

  // Utility method to save user phone number
  static Future<void> setUserPhone(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userPhone', phoneNumber);
  }

  // Utility method to get user phone number
  static Future<String?> getUserPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userPhone');
  }
}
