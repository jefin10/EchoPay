import { isUpiId, toIndianE164 } from '@/core/utils/phone';
import { loadContacts, matchContactsByName, type DeviceContact } from '@/features/payments/contacts';
import type { VoiceOutcome } from '@/models/voice-outcome';

/** Where a voice payment/request goes once the spoken recipient is resolved. */
export type Target = { kind: 'phone'; phone: string; label: string } | { kind: 'upi'; upiId: string; label: string };

export type Resolution =
  | { status: 'resolved'; target: Target }
  | { status: 'choose'; name: string; matches: DeviceContact[] }
  | { status: 'failed'; message: string };

export const targetFromContact = (c: DeviceContact): Target => ({
  kind: 'phone',
  phone: toIndianE164(c.phone ?? ''),
  label: c.name,
});

/**
 * Turn the recipient the intent service extracted into something the
 * backend can pay. Spoken names are looked up in the phone book — the
 * Flutter app sent them to the backend as "+91<name>", which always failed.
 */
export async function resolveRecipient(
  outcome: Pick<VoiceOutcome, 'recipient' | 'recipientKind'>,
  contactsLoader = loadContacts,
): Promise<Resolution> {
  const { recipient, recipientKind } = outcome;
  if (!recipient) return { status: 'failed', message: 'Who should this go to? Try "send 500 to 98765 43210".' };

  if (recipientKind === 'upi' || isUpiId(recipient)) {
    return { status: 'resolved', target: { kind: 'upi', upiId: recipient, label: recipient } };
  }
  if (recipientKind === 'phone') {
    const phone = toIndianE164(recipient);
    return { status: 'resolved', target: { kind: 'phone', phone, label: phone } };
  }

  const contacts = await contactsLoader();
  if (!contacts.granted) {
    return { status: 'failed', message: `Allow contacts access so I can find "${recipient}", or say their number.` };
  }
  const matches = matchContactsByName(contacts.contacts, recipient);
  if (matches.length === 1) return { status: 'resolved', target: targetFromContact(matches[0]!) };
  if (matches.length > 1) return { status: 'choose', name: recipient, matches: matches.slice(0, 8) };
  return { status: 'failed', message: `No contact named "${recipient}". Try saying their number.` };
}
