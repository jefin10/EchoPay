import '../../../core/network/api_client.dart';
import '../../../core/network/api_constants.dart';
import '../../../models/voice_outcome.dart';

/// Routes a spoken command through the intent pipeline:
///   1. Flask classifies the text (`/voice_command`).
///   2. If confidence >= 70% and it's a UPI action → return an action outcome.
///   3. Otherwise → fall back to the Rasa chatbot for casual conversation.
///
/// Replaces the static `IntentService` + `RasaService`.
class VoiceRepository {
  VoiceRepository(this._api);

  final ApiClient _api;

  static const _confidenceThreshold = 70.0;

  Future<VoiceOutcome> processCommand(String text, {String userPhone = ''}) async {
    final Map<String, dynamic> intent;
    try {
      final json = await _api.postJson(
        Uri.parse(CLASSIFY_INTENT_URL),
        {'text': text, 'userPhone': userPhone},
      );
      intent = Map<String, dynamic>.from(json as Map);
    } on ApiException catch (e) {
      return VoiceOutcome.error(e.message);
    }

    final predictedIntent = intent['predicted_intent']?.toString();
    final action = intent['action']?.toString();
    final assistantMessage = intent['assistant_message']?.toString();
    final confidence = (intent['confidence_percentage'] as num?)?.toDouble();
    final routeToRasa = intent['route_to_rasa'] == true;
    final entities = intent['entities'] as Map?;

    // Low confidence or explicitly flagged → casual chat via Rasa.
    if (routeToRasa ||
        (confidence != null && confidence < _confidenceThreshold)) {
      final reply = await _chat(text);
      return VoiceOutcome(
        success: reply.success,
        action: 'chatbot',
        message: reply.message,
        intent: predictedIntent,
        confidence: confidence,
        source: 'rasa',
      );
    }

    switch (action) {
      case 'transfer_money':
        return VoiceOutcome(
          success: true,
          action: 'initiate_transfer',
          message: assistantMessage ?? 'Transfer request',
          intent: predictedIntent,
          confidence: confidence,
          amount: entities?['amount']?.toString(),
          recipient: _recipientOf(entities),
          originalText: text,
        );
      case 'request_money':
        return VoiceOutcome(
          success: true,
          action: 'initiate_request',
          message: assistantMessage ?? 'Request money',
          intent: predictedIntent,
          confidence: confidence,
          amount: entities?['amount']?.toString(),
          recipient: _recipientOf(entities),
          originalText: text,
        );
      case 'check_balance':
        return VoiceOutcome(
          success: true,
          action: 'show_balance',
          message: assistantMessage ?? 'Opening balance page',
          intent: predictedIntent,
          confidence: confidence,
        );
      case 'general_conversation':
        return VoiceOutcome(
          success: true,
          action: 'chatbot',
          message: assistantMessage ?? "I'm here to help!",
          intent: predictedIntent,
          confidence: confidence,
        );
      default:
        return VoiceOutcome(
          success: true,
          action: action ?? 'unknown',
          message: assistantMessage ?? 'I understood: $predictedIntent',
          intent: predictedIntent,
          confidence: confidence,
        );
    }
  }

  String? _recipientOf(Map? entities) =>
      entities?['recipient_name']?.toString() ??
      entities?['phone_number']?.toString() ??
      entities?['upi_id']?.toString();

  /// Send a message to the Rasa chatbot and return its first text reply.
  Future<VoiceOutcome> _chat(String message) async {
    try {
      final json = await _api.postJson(
        Uri.parse(RASA_CHAT_URL),
        {'sender': 'user', 'message': message},
      );
      final responses = json as List;
      final text = responses.isNotEmpty
          ? (responses.first['text']?.toString() ??
              "I'm here to help you with your UPI transactions!")
          : "I'm here to help you with your UPI transactions!";
      return VoiceOutcome(success: true, action: 'chatbot', message: text, source: 'rasa');
    } on ApiException {
      return VoiceOutcome(
        success: false,
        action: 'chatbot',
        message: "Sorry, I couldn't process that. Please try again.",
      );
    }
  }

  Future<bool> checkServerHealth() async {
    try {
      await _api.getJson(Uri.parse('$INTENT_API_URL/health'));
      return true;
    } on ApiException {
      return false;
    }
  }
}
