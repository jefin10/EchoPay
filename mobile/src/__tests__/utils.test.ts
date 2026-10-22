import { formatINR, initials, relativeDay } from '@/core/utils/format';
import { parseAmount, sanitizeAmountInput } from '@/features/payments/amount';
import { isPhoneLike, isUpiId, localPhone, toIndianE164 } from '@/core/utils/phone';

describe('formatINR', () => {
  it('uses Indian digit grouping', () => {
    expect(formatINR(5000)).toBe('₹5,000.00');
    expect(formatINR(1234567.5)).toBe('₹12,34,567.50');
    expect(formatINR(999)).toBe('₹999.00');
    expect(formatINR(250, { decimals: 0 })).toBe('₹250');
    expect(formatINR(-42)).toBe('-₹42.00');
  });
});

describe('initials', () => {
  it('takes up to two initials', () => {
    expect(initials('ravi kumar')).toBe('RK');
    expect(initials('Anu')).toBe('A');
    expect(initials('  ')).toBe('?');
  });
});

describe('relativeDay', () => {
  const now = new Date(2026, 9, 22, 12);
  it('labels today and yesterday', () => {
    expect(relativeDay(new Date(2026, 9, 22, 8).toISOString(), now)).toBe('Today');
    expect(relativeDay(new Date(2026, 9, 21, 23).toISOString(), now)).toBe('Yesterday');
    expect(relativeDay(new Date(2026, 9, 1).toISOString(), now)).toBe('1 Oct 2026');
  });
});

describe('phone helpers', () => {
  it('normalises Indian numbers', () => {
    expect(toIndianE164('98765 43210')).toBe('+919876543210');
    expect(toIndianE164('+91-98765-43210')).toBe('+919876543210');
    expect(toIndianE164('919876543210')).toBe('+919876543210');
    expect(toIndianE164('09876543210')).toBe('+919876543210');
    expect(toIndianE164('')).toBe('');
    expect(localPhone('+919876543210')).toBe('9876543210');
  });

  it('classifies recipients', () => {
    expect(isPhoneLike('+91 98765 43210')).toBe(true);
    expect(isPhoneLike('Ravi')).toBe(false);
    expect(isUpiId('ravi@upi')).toBe(true);
    expect(isUpiId('ravi')).toBe(false);
  });
});

describe('amount parsing', () => {
  it('accepts positive amounts with up to 2 decimals', () => {
    expect(parseAmount('250')).toBe(250);
    expect(parseAmount('1,000.50')).toBe(1000.5);
    expect(parseAmount('0')).toBeNull();
    expect(parseAmount('-5')).toBeNull();
    expect(parseAmount('1.234')).toBeNull();
    expect(parseAmount('abc')).toBeNull();
  });
  it('sanitises keystrokes', () => {
    expect(sanitizeAmountInput('12a.3456')).toBe('12.34');
    expect(sanitizeAmountInput('1.2.3')).toBe('1.23');
  });
});
