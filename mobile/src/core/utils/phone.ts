/** Strip spaces, dashes and brackets from a phone number. */
export function compactPhone(raw: string): string {
  return raw.replace(/[\s\-()]/g, '');
}

/**
 * The last 10 digits of an Indian number, dropping +91 / 91 / leading 0.
 * Returns '' if there are no digits.
 */
export function localPhone(raw: string): string {
  const digits = compactPhone(raw).replace(/\D/g, '');
  return digits.length >= 10 ? digits.slice(-10) : digits;
}

/** Canonical `+91XXXXXXXXXX`, matching what the Django backend stores. */
export function toIndianE164(raw: string): string {
  const local = localPhone(raw);
  return local ? `+91${local}` : '';
}

/** True if the string looks like a phone number (10+ digits, nothing else). */
export function isPhoneLike(raw: string): boolean {
  const compact = compactPhone(raw).replace(/^\+/, '');
  return /^\d{10,13}$/.test(compact);
}

export function isUpiId(raw: string): boolean {
  return /^[\w.\-]+@[a-zA-Z]+$/.test(raw.trim());
}
