export interface UpiQr {
  /** Payee UPI ID (`pa`). */
  upiId: string;
  /** Payee name (`pn`). */
  name?: string;
  /** Amount (`am`). */
  amount?: string;
}

/**
 * Parse a UPI QR payload (`upi://pay?pa=…&pn=…&am=…`). Returns null for
 * anything without a payee address.
 */
export function parseUpiQr(data: string): UpiQr | null {
  const raw = data.trim();
  const query = raw.toLowerCase().startsWith('upi://') ? raw.slice(raw.indexOf('?') + 1) : raw.includes('pa=') ? raw : '';
  if (!query) return null;
  const params: Record<string, string> = {};
  for (const pair of query.split('&')) {
    const [k, ...v] = pair.split('=');
    if (!k) continue;
    try {
      params[k.toLowerCase()] = decodeURIComponent(v.join('=').replace(/\+/g, ' '));
    } catch {
      params[k.toLowerCase()] = v.join('=');
    }
  }
  if (!params.pa) return null;
  return {
    upiId: params.pa,
    ...(params.pn ? { name: params.pn } : {}),
    ...(params.am ? { amount: params.am } : {}),
  };
}

/** The `upi://pay` URI encoded in the user's own receive QR. */
export function buildUpiUri({ upiId, name }: { upiId: string; name: string }): string {
  return `upi://pay?pa=${encodeURIComponent(upiId)}&pn=${encodeURIComponent(name || 'User')}&cu=INR`;
}
