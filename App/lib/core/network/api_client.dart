import 'dart:convert';
import 'package:http/http.dart' as http;

/// Thrown when a request fails at the network level or the server returns a
/// non-2xx status. [message] is already user-presentable.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// A thin JSON-over-HTTP client.
///
/// Repositories use this instead of touching `package:http` directly, so
/// JSON encoding/decoding, headers and error normalisation live in one place.
/// It returns decoded JSON (`Map`/`List`) and throws [ApiException] on failure;
/// repositories are responsible for mapping JSON into typed models.
class ApiClient {
  ApiClient([http.Client? client]) : _client = client ?? http.Client();

  final http.Client _client;

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<dynamic> getJson(
    Uri uri, {
    bool acceptedStatuses(int code)?,
  }) async {
    try {
      final res = await _client.get(uri, headers: _jsonHeaders);
      return _handle(res, acceptedStatuses);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  Future<dynamic> postJson(
    Uri uri,
    Map<String, dynamic> body, {
    bool acceptedStatuses(int code)?,
  }) async {
    try {
      final res = await _client.post(
        uri,
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );
      return _handle(res, acceptedStatuses);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Network error: $e');
    }
  }

  dynamic _handle(http.Response res, bool Function(int)? accepted) {
    final ok = accepted?.call(res.statusCode) ??
        (res.statusCode >= 200 && res.statusCode < 300);
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (ok) return decoded;

    String message = 'Request failed (${res.statusCode})';
    if (decoded is Map) {
      message = (decoded['error'] ?? decoded['message'] ?? message).toString();
    }
    throw ApiException(message, statusCode: res.statusCode);
  }
}
