/** Parse a user-entered rupee amount. Positive, at most 2 decimals; else null. */
export function parseAmount(text: string): number | null {
  const clean = text.replace(/[,₹\s]/g, '');
  if (!/^\d+(\.\d{1,2})?$/.test(clean)) return null;
  const n = Number.parseFloat(clean);
  return n > 0 ? n : null;
}

/** Keep only digits and one decimal point with up to 2 places, for amount inputs. */
export function sanitizeAmountInput(text: string): string {
  const [int = '', ...rest] = text.replace(/[^\d.]/g, '').split('.');
  return rest.length ? `${int}.${rest.join('').slice(0, 2)}` : int;
}
