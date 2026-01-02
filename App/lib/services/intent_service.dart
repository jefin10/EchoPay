import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class IntentService {
  /// Process voice command and execute action
  /// Example: "send 1000 rs to jefin" -> Send money to jefin
  static Future<Map<String, dynamic>> processVoiceCommand(String text) async {
    try {
      print('Processing voice command: $text');

      // Step 1: Get intent and response from Flask server
      final intentResponse = await predictIntent(text);

      if (intentResponse == null || intentResponse['status'] == 'error') {
        return {
          'status': 'error',
          'message':
              intentResponse?['assistant_message'] ??
              'Failed to understand command',
          'action': 'none',
        };
      }

      final intent = intentResponse['predicted_intent'];
      final confidence = intentResponse['confidence_percentage'];
      final action = intentResponse['action'];
      final assistantMessage = intentResponse['assistant_message'];

      print('Intent: $intent, Confidence: $confidence%');
      print('Action: $action');

      // The /voice_command endpoint handles everything and returns ready-to-use data
      // Check if Django backend returned an error
      if (intentResponse['django_response'] != null &&
          intentResponse['django_response']['status'] == 'error') {
        return {
          'status': 'error',
          'intent': intent,
          'message': assistantMessage ?? 'Failed to process request',
          'action': action ?? 'error',
          'confidence': confidence,
        };
      }

      // Extract entities if available
      final entities = intentResponse['entities'];

      // Step 2: Route based on action from backend
      if (action == 'transfer_money' && entities != null) {
        return {
          'status': 'success',
          'intent': intent,
          'action': 'initiate_transfer',
          'message': assistantMessage ?? 'Transfer request',
          'data': {
            'amount': entities['amount'],
            'recipient':
                entities['recipient_name'] ??
                entities['phone_number'] ??
                entities['upi_id'],
            'original_text': text,
          },
          'confidence': confidence,
        };
      } else if (action == 'check_balance') {
        return {
          'status': 'success',
          'intent': intent,
          'action': 'show_balance',
          'message': assistantMessage ?? 'Opening balance page',
          'confidence': confidence,
        };
      } else if (action == 'request_money' && entities != null) {
        return {
          'status': 'success',
          'intent': intent,
          'action': 'initiate_request',
          'message': assistantMessage ?? 'Request money',
          'data': {
            'amount': entities['amount'],
            'recipient':
                entities['recipient_name'] ??
                entities['phone_number'] ??
                entities['upi_id'],
            'original_text': text,
          },
          'confidence': confidence,
        };
      } else if (action == 'general_conversation') {
        return {
          'status': 'success',
          'intent': intent,
          'action': 'chatbot',
          'message': assistantMessage ?? 'I\'m here to help!',
          'confidence': confidence,
        };
      } else {
        return {
          'status': 'success',
          'intent': intent,
          'action': action ?? 'unknown',
          'message': assistantMessage ?? 'I understood: $intent',
          'confidence': confidence,
        };
      }
    } catch (e) {
      print('Error in processVoiceCommand: $e');
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'action': 'none',
      };
    }
  }

  /// Get intent prediction from Flask server
  static Future<Map<String, dynamic>?> predictIntent(String text) async {
    try {
      // Get user phone number
      final userPhone = await getUserPhone() ?? '+919999999999';

      final response = await http.post(
        Uri.parse(CLASSIFY_INTENT_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'userPhone': userPhone}),
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
      final response = await http.get(Uri.parse('$INTENT_API_URL/health'));
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
