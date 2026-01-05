import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import 'rasa_service.dart';

class IntentService {
  /// Process voice command and execute action
  /// Flow: Voice text -> Flask (intent classification) ->
  ///       If confidence >= 70%: Extract keywords & route to Django for UPI actions
  ///       If confidence < 70%: Route to Rasa for casual conversation
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
      final routeToRasa = intentResponse['route_to_rasa'] ?? false;

      print('Intent: $intent, Confidence: $confidence%');
      print('Action: $action');

      // CONFIDENCE CHECK: If confidence < 70% OR flagged to route to Rasa, send to Rasa chatbot
      if (routeToRasa || (confidence != null && confidence < 70.0)) {
        print('Routing to Rasa (confidence: $confidence%)...');

        // Send to Rasa for casual conversation
        final rasaResponse = await RasaService.sendMessage(text);

        return {
          'status': rasaResponse['status'],
          'intent': intent,
          'action': 'chatbot',
          'message': rasaResponse['message'],
          'confidence': confidence,
          'source': 'rasa',
        };
      }

      // HIGH CONFIDENCE (>= 70%): Process UPI-related actions
      print('High confidence - Processing UPI action...');

      // Extract entities if available
      final entities = intentResponse['entities'];

      // Route based on action from Flask backend (Flask only classifies, frontend calls Django)
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
    // Use 'signedUpPhoneNumber' - same key as other pages (balance, profile, etc.)
    return prefs.getString('signedUpPhoneNumber');
  }
}
