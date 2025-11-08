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
      
      // Step 1: Get intent and keywords from Flask server
      final intentResponse = await predictIntent(text);
      
      if (intentResponse == null || intentResponse['status'] == 'error') {
        return {
          'status': 'error',
          'message': 'Failed to understand command',
          'action': 'none'
        };
      }
      
      final intent = intentResponse['predicted_intent'];
      final keywords = intentResponse['keywords'];
      final confidence = intentResponse['confidence_percentage'];
      
      print('Intent: $intent, Confidence: $confidence%');
      print('Keywords: $keywords');
      
      // Step 2: Execute action based on intent
      if (intent == 'transfer_money') {
        return await _handleTransferMoney(text, keywords);
      } else if (intent == 'check_balance') {
        return {
          'status': 'success',
          'intent': 'check_balance',
          'action': 'show_balance',
          'message': 'Opening balance page',
          'confidence': confidence
        };
      } else if (intent == 'request_money') {
        return await _handleRequestMoney(text, keywords);
      } else {
        return {
          'status': 'success',
          'intent': intent,
          'action': 'unknown',
          'message': 'I understood: $intent, but cannot perform this action yet',
          'confidence': confidence
        };
      }
      
    } catch (e) {
      print('Error in processVoiceCommand: $e');
      return {
        'status': 'error',
        'message': 'Network error: $e',
        'action': 'none'
      };
    }
  }
  
  /// Handle transfer money intent
  static Future<Map<String, dynamic>> _handleTransferMoney(
    String originalText, 
    Map<String, dynamic> keywords
  ) async {
    try {
      final amount = keywords['amount'];
      final recipient = keywords['recipient'];
      
      if (amount == null) {
        return {
          'status': 'error',
          'intent': 'transfer_money',
          'action': 'missing_info',
          'message': 'How much money do you want to send?',
          'missing': 'amount'
        };
      }
      
      if (recipient == null) {
        return {
          'status': 'error',
          'intent': 'transfer_money',
          'action': 'missing_info',
          'message': 'Who do you want to send money to?',
          'missing': 'recipient'
        };
      }
      
      // Parse amount (remove "rs", "rupees", etc.)
      final amountStr = amount.toString().replaceAll(RegExp(r'[^\d.]'), '');
      final amountValue = double.tryParse(amountStr);
      
      if (amountValue == null || amountValue <= 0) {
        return {
          'status': 'error',
          'intent': 'transfer_money',
          'action': 'invalid_amount',
          'message': 'Invalid amount: $amount',
        };
      }
      
      return {
        'status': 'success',
        'intent': 'transfer_money',
        'action': 'initiate_transfer',
        'message': 'Send ₹$amountValue to $recipient?',
        'data': {
          'amount': amountValue,
          'recipient': recipient,
          'original_text': originalText
        }
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error processing transfer: $e',
        'action': 'error'
      };
    }
  }
  
  /// Handle request money intent
  static Future<Map<String, dynamic>> _handleRequestMoney(
    String originalText,
    Map<String, dynamic> keywords
  ) async {
    try {
      final amount = keywords['amount'];
      final recipient = keywords['recipient'];
      
      return {
        'status': 'success',
        'intent': 'request_money',
        'action': 'initiate_request',
        'message': 'Request ₹${amount ?? 'some'} from ${recipient ?? 'someone'}?',
        'data': {
          'amount': amount,
          'recipient': recipient,
          'original_text': originalText
        }
      };
      
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error processing request: $e',
        'action': 'error'
      };
    }
  }
  
  /// Get intent prediction from Flask server
  static Future<Map<String, dynamic>?> predictIntent(String text) async {
    try {
      final response = await http.post(
        Uri.parse(CLASSIFY_INTENT_URL),
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
        Uri.parse('$INTENT_API_URL/health'),
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
