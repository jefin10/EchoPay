/// The result of routing a voice command through the intent pipeline
/// (Flask classify → Django action or Rasa chat).
///
/// Replaces the untyped `Map<String, dynamic>` that `IntentService` used to
/// return. [action] drives what the UI does next:
///   `initiate_transfer`, `initiate_request`, `show_balance`,
///   `chatbot`, `none`, or a passthrough intent string.
class VoiceOutcome {
  const VoiceOutcome({
    required this.success,
    required this.action,
    required this.message,
    this.intent,
    this.confidence,
    this.source,
    this.amount,
    this.recipient,
    this.originalText,
  });

  final bool success;
  final String action;
  final String message;
  final String? intent;
  final double? confidence;
  final String? source;

  // Extracted entities for transfer / request actions.
  final String? amount;
  final String? recipient;
  final String? originalText;

  bool get isTransfer => action == 'initiate_transfer';
  bool get isRequest => action == 'initiate_request';
  bool get isBalance => action == 'show_balance';
  bool get isChat => action == 'chatbot';

  factory VoiceOutcome.error(String message) =>
      VoiceOutcome(success: false, action: 'none', message: message);
}
