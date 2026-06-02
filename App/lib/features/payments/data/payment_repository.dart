import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/transfer_result.dart';

/// Write-side money movement: sending money and raising requests, plus the
/// recipient lookup used by the pay flows. Replaces the static `DjangoService`.
class PaymentRepository {
  PaymentRepository(this._api);

  final ApiClient _api;

  Future<TransferResult> sendByPhone({
    required String senderPhone,
    required String receiverPhone,
    required double amount,
    String? remark,
  }) {
    return _send(
      Uri.parse(SEND_MONEY_PHONE_URL),
      {
        'senderPhone': senderPhone,
        'receiverPhone': receiverPhone,
        'amount': amount,
        if (remark != null) 'remark': remark,
      },
    );
  }

  Future<TransferResult> sendByUpiId({
    required String senderPhone,
    required String receiverUpi,
    required double amount,
    String? remark,
  }) {
    return _send(
      Uri.parse(SEND_MONEY_ID_URL),
      {
        'senderPhone': senderPhone,
        'receiverUpi': receiverUpi,
        'amount': amount,
        if (remark != null) 'remark': remark,
      },
    );
  }

  Future<TransferResult> createMoneyRequest({
    required String requesterPhone,
    required String requesteePhone,
    required double amount,
    String? message,
  }) {
    return _send(
      Uri.parse(CREATE_REQUEST_URL),
      {
        'requesterPhone': requesterPhone,
        'requesteePhone': requesteePhone,
        'amount': amount,
        'message': message ?? 'Payment request for ₹$amount',
      },
      successMessage: 'Request sent successfully',
    );
  }

  /// Returns the matched user payload, or `null` if no user was found.
  Future<Map<String, dynamic>?> searchByPhone(String phoneNumber) =>
      _search(Uri.parse(SEARCH_BY_PHONE_URL)
          .replace(queryParameters: {'phoneNumber': phoneNumber}));

  /// Returns the matched user payload, or `null` if no user was found.
  Future<Map<String, dynamic>?> searchByUpiId(String upiId) =>
      _search(Uri.parse(SEARCH_BY_UPI_URL)
          .replace(queryParameters: {'upiId': upiId}));

  /// Whether [phoneNumber] is registered with an account.
  Future<bool> hasAccount(String phoneNumber) async {
    final result = await _search(Uri.parse(CHECK_ACCOUNT_URL)
        .replace(queryParameters: {'phoneNumber': phoneNumber}));
    if (result == null) return false;
    return result['hasAccount'] == true || result['exists'] == true;
  }

  /// Money requests addressed to / raised by [phoneNumber]. Returns the raw
  /// decoded payload (the UI splits it into incoming/outgoing).
  Future<Map<String, dynamic>> getMoneyRequests(String phoneNumber) async {
    final json = await _api.getJson(
      Uri.parse(GET_REQUESTS_URL)
          .replace(queryParameters: {'phoneNumber': phoneNumber}),
    );
    return Map<String, dynamic>.from(json as Map);
  }

  Future<TransferResult> updateRequestStatus({
    required dynamic requestId,
    required String status,
    String? phoneNumber,
  }) {
    return _send(
      Uri.parse(UPDATE_REQUEST_URL),
      {
        'requestId': requestId,
        'status': status,
        if (phoneNumber != null) 'phoneNumber': phoneNumber,
      },
      successMessage: 'Request updated',
    );
  }

  Future<Map<String, dynamic>?> _search(Uri uri) async {
    try {
      final json = await _api.getJson(uri);
      return Map<String, dynamic>.from(json as Map);
    } on ApiException {
      return null;
    }
  }

  Future<TransferResult> _send(
    Uri uri,
    Map<String, dynamic> body, {
    String successMessage = 'Transfer successful',
  }) async {
    try {
      final json = await _api.postJson(
        uri,
        body,
        acceptedStatuses: (c) => c == 200 || c == 201,
      ) as Map;
      return TransferResult.success(
        json['message']?.toString() ?? successMessage,
        data: Map<String, dynamic>.from(json),
      );
    } on ApiException catch (e) {
      return TransferResult.failure(e.message);
    }
  }
}
