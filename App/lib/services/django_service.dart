import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

/// Service class for making API calls to Django backend
class DjangoService {
  /// Send money by phone number
  /// Calls: POST /accounts/sendMoneyPhone/
  static Future<Map<String, dynamic>> sendMoneyByPhone({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
  }) async {
    try {
      print(
        'Calling Django sendMoneyPhone: $senderPhone -> $receiverPhone, amount: $amount',
      );

      final response = await http.post(
        Uri.parse(SEND_MONEY_PHONE_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPhone': senderPhone,
          'receiverPhone': receiverPhone,
          'amount': amount,
        }),
      );

      print('Django response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Transfer successful',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': error['error'] ?? error['message'] ?? 'Transfer failed',
        };
      }
    } catch (e) {
      print('Django sendMoneyPhone error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Send money by UPI ID
  /// Calls: POST /accounts/sendMoneyId/
  static Future<Map<String, dynamic>> sendMoneyByUpiId({
    required String senderPhone,
    required String receiverUpi,
    required double amount,
  }) async {
    try {
      print(
        'Calling Django sendMoneyId: $senderPhone -> $receiverUpi, amount: $amount',
      );

      final response = await http.post(
        Uri.parse(SEND_MONEY_ID_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderPhone': senderPhone,
          'receiverUpi': receiverUpi,
          'amount': amount,
        }),
      );

      print('Django response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Transfer successful',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': error['error'] ?? error['message'] ?? 'Transfer failed',
        };
      }
    } catch (e) {
      print('Django sendMoneyId error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Get account balance
  /// Calls: GET /accounts/getBalance?phoneNumber=...
  static Future<Map<String, dynamic>> getBalance(String phoneNumber) async {
    try {
      print('Calling Django getBalance for: $phoneNumber');

      final response = await http.get(
        Uri.parse('$GET_BALANCE_URL?phoneNumber=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Django response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'balance': data['balance'] ?? data['amount'] ?? 0,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'message':
              error['error'] ?? error['message'] ?? 'Failed to get balance',
        };
      }
    } catch (e) {
      print('Django getBalance error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Create money request by phone number
  /// Calls: POST /accounts/createMoneyRequest/
  static Future<Map<String, dynamic>> createMoneyRequest({
    required String requesterPhone,
    required String requesteePhone,
    required double amount,
    String? message,
  }) async {
    try {
      print(
        'Calling Django createMoneyRequest: $requesterPhone from $requesteePhone, amount: $amount',
      );

      final response = await http.post(
        Uri.parse(CREATE_REQUEST_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requesterPhone': requesterPhone,
          'requesteePhone': requesteePhone,
          'amount': amount,
          'message': message ?? 'Payment request for ₹$amount',
        }),
      );

      print('Django response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'message': data['message'] ?? 'Request sent successfully',
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'message': error['error'] ?? error['message'] ?? 'Request failed',
        };
      }
    } catch (e) {
      print('Django createMoneyRequest error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Get transactions history
  /// Calls: GET /accounts/getTransactions/
  static Future<Map<String, dynamic>> getTransactions(
    String phoneNumber,
  ) async {
    try {
      print('Calling Django getTransactions for: $phoneNumber');

      final response = await http.get(
        Uri.parse('$GET_TRANSACTIONS_URL?phoneNumber=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      print('Django response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'status': 'success',
          'transactions': data['transactions'] ?? data,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'status': 'error',
          'message':
              error['error'] ??
              error['message'] ??
              'Failed to get transactions',
        };
      }
    } catch (e) {
      print('Django getTransactions error: $e');
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  /// Search user by phone number
  /// Calls: GET /accounts/searchPhonenumber/
  static Future<Map<String, dynamic>> searchByPhone(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$SEARCH_BY_PHONE_URL?phoneNumber=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'status': 'success', 'found': true, 'data': data};
      } else {
        return {'status': 'error', 'found': false, 'message': 'User not found'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }
}
