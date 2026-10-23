/**
 * What the UI should do after a voice command has gone through the intent
 * pipeline (Flask classify → action, or Rasa chat).
 */
export type VoiceAction = 'transfer' | 'request' | 'balance' | 'chat' | 'none';

export interface VoiceOutcome {
  success: boolean;
  action: VoiceAction;
  message: string;
  intent?: string;
  confidence?: number;
  source?: 'intent_classifier' | 'rasa';
  // Extracted entities for transfer / request actions.
  amount?: number;
  recipient?: string;
  /** How `recipient` should be resolved against the backend. */
  recipientKind?: 'upi' | 'phone' | 'name';
  originalText?: string;
}

export const voiceError = (message: string): VoiceOutcome => ({
  success: false,
  action: 'none',
  message,
});
