/// Outcome of a money-movement call (send / request). Carries a
/// user-presentable [message] regardless of success.
class TransferResult {
  const TransferResult({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final Map<String, dynamic>? data;

  factory TransferResult.success(String message, {Map<String, dynamic>? data}) =>
      TransferResult(success: true, message: message, data: data);

  factory TransferResult.failure(String message) =>
      TransferResult(success: false, message: message);
}
