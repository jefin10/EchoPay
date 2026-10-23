import { ApiException, getJson, postJson } from '@/core/api/client';
import { Endpoints } from '@/core/api/endpoints';
import { localPhone } from '@/core/utils/phone';
import { voiceError, type VoiceOutcome } from '@/models/voice-outcome';

/**
 * Routes a spoken command through the intent pipeline:
 *   1. Flask classifies the text (`/voice_command`).
 *   2. Confidence >= 70% and a UPI action → an action outcome.
 *   3. Otherwise → the Rasa chatbot for casual conversation.
 */

export const CONFIDENCE_THRESHOLD = 70;

const FALLBACK_REPLY = "I'm here to help you with your UPI transactions!";

interface IntentResponse {
  predicted_intent?: string;
  action?: string;
  assistant_message?: string;
  confidence_percentage?: number;
  route_to_rasa?: boolean;
  entities?: {
    amount?: number;
    phone_number?: string;
    upi_id?: string;
    recipient_name?: string;
  };
}

export async function processCommand(text: string, userPhone = ''): Promise<VoiceOutcome> {
  let intent: IntentResponse;
  try {
    intent = (await postJson<IntentResponse>(Endpoints.voiceCommand, { text, userPhone })) ?? {};
  } catch (e) {
    if (e instanceof ApiException) return voiceError(e.message);
    throw e;
  }

  const predicted = intent.predicted_intent;
  const confidence = intent.confidence_percentage;

  if (intent.route_to_rasa || (confidence != null && confidence < CONFIDENCE_THRESHOLD)) {
    const reply = await chat(text, userPhone);
    return { ...reply, intent: predicted, confidence };
  }

  const base = { success: true, intent: predicted, confidence, source: 'intent_classifier' as const };

  switch (intent.action) {
    case 'transfer_money':
    case 'request_money':
      return {
        ...base,
        action: intent.action === 'transfer_money' ? 'transfer' : 'request',
        message: intent.assistant_message ?? 'Transfer request',
        ...pickEntities(intent.entities),
        originalText: text,
      };
    case 'check_balance':
      return { ...base, action: 'balance', message: intent.assistant_message ?? 'Checking your balance' };
    default:
      return {
        ...base,
        action: 'none',
        message: intent.assistant_message ?? `I understood: ${predicted}`,
      };
  }
}

/**
 * Choose the recipient from extracted entities.
 *
 * The Flask name regex also matches command words ("send 500 to 98…" yields
 * recipient_name "Send" next to the phone number), so the most precise entity
 * wins: UPI ID, then phone number, then name. Checking the name first would
 * make phone and UPI voice payments fail.
 */
export function pickEntities(entities: IntentResponse['entities']): Pick<
  VoiceOutcome,
  'amount' | 'recipient' | 'recipientKind'
> {
  if (!entities) return {};
  const recipient = entities.upi_id
    ? { recipient: entities.upi_id, recipientKind: 'upi' as const }
    : entities.phone_number
      ? { recipient: entities.phone_number, recipientKind: 'phone' as const }
      : entities.recipient_name
        ? { recipient: entities.recipient_name, recipientKind: 'name' as const }
        : {};

  // The amount regex grabs the first number, which can be the phone number
  // itself ("send to 9876543210 500 rupees"). Drop it rather than offer that.
  let amount = entities.amount;
  if (amount != null && entities.phone_number && String(Math.trunc(amount)) === localPhone(entities.phone_number)) {
    amount = undefined;
  }
  return { ...recipient, ...(amount != null && amount > 0 ? { amount } : {}) };
}

/** Send a message to Rasa and return its first text reply. */
export async function chat(message: string, userPhone = ''): Promise<VoiceOutcome> {
  try {
    const replies = await postJson<{ text?: string }[]>(Endpoints.rasaChat, {
      // One Rasa conversation per user.
      sender: userPhone || 'echopay-guest',
      message,
    });
    const text = Array.isArray(replies) && replies[0]?.text ? replies[0].text : FALLBACK_REPLY;
    return { success: true, action: 'chat', message: text, source: 'rasa' };
  } catch (e) {
    if (e instanceof ApiException) {
      return { success: false, action: 'chat', message: "Sorry, I couldn't process that. Please try again." };
    }
    throw e;
  }
}

export async function checkServerHealth(): Promise<boolean> {
  try {
    await getJson(Endpoints.voiceHealth);
    return true;
  } catch {
    return false;
  }
}
