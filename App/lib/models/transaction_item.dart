/// A single ledger entry, normalised from the backend's split
/// `transactions.sent[]` / `transactions.received[]` payload.
class TransactionItem {
  const TransactionItem({
    required this.type,
    required this.counterpartyName,
    required this.amount,
    required this.timestamp,
    required this.status,
  });

  /// `'sent'` or `'received'`.
  final String type;
  final String counterpartyName;
  final double amount;

  /// Raw ISO timestamp as returned by the backend (may be empty).
  final String timestamp;
  final String status;

  bool get isSent => type == 'sent';

  /// `YYYY-MM-DD` portion of [timestamp], or empty.
  String get date => timestamp.isEmpty ? '' : timestamp.split('T').first;

  /// `HH:MM` portion of [timestamp], or empty.
  String get time {
    final parts = timestamp.split('T');
    if (parts.length < 2 || parts[1].length < 5) return '';
    return parts[1].substring(0, 5);
  }

  factory TransactionItem.sent(Map<String, dynamic> json) => TransactionItem(
        type: 'sent',
        counterpartyName: json['receiver__user__upiName']?.toString() ?? 'Unknown',
        amount: double.tryParse(json['amount'].toString()) ?? 0.0,
        timestamp: json['timestamp']?.toString() ?? '',
        status: json['status']?.toString() ?? 'completed',
      );

  factory TransactionItem.received(Map<String, dynamic> json) => TransactionItem(
        type: 'received',
        counterpartyName: json['sender__user__upiName']?.toString() ?? 'Unknown',
        amount: double.tryParse(json['amount'].toString()) ?? 0.0,
        timestamp: json['timestamp']?.toString() ?? '',
        status: json['status']?.toString() ?? 'completed',
      );

  /// Parse the full `{ transactions: { sent: [], received: [] } }` payload
  /// into a single list sorted newest-first.
  static List<TransactionItem> parseAll(Map<String, dynamic> data) {
    final tx = data['transactions'];
    if (tx is! Map) return [];
    final sent = (tx['sent'] as List? ?? [])
        .map((e) => TransactionItem.sent(Map<String, dynamic>.from(e)));
    final received = (tx['received'] as List? ?? [])
        .map((e) => TransactionItem.received(Map<String, dynamic>.from(e)));
    final all = [...sent, ...received]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }
}
