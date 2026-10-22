import { renderRouter, screen } from 'expo-router/testing-library';

import { buildUpiUri, parseUpiQr } from '@/features/payments/upi-qr';

import { mockBackend, press, signIn } from './test-utils';

// The scanner fires onBarcodeScanned as soon as it mounts, with a fixed payload.
let mockPayload = 'upi://pay?pa=anu%40upi&pn=Anu%20K&am=150&cu=INR';
jest.mock('expo-camera', () => {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const { useEffect } = require('react');
  return {
    useCameraPermissions: () => [{ granted: true, canAskAgain: true }, jest.fn()],
    scanFromURLAsync: jest.fn(),
    CameraView: ({ onBarcodeScanned }: { onBarcodeScanned?: (r: { data: string }) => void }) => {
      useEffect(() => {
        onBarcodeScanned?.({ data: mockPayload });
      }, [onBarcodeScanned]);
      return null;
    },
  };
});

describe('parseUpiQr', () => {
  it('reads payee, name and amount', () => {
    expect(parseUpiQr('upi://pay?pa=ravi%40okhdfc&pn=Ravi+Kumar&am=99.50&cu=INR')).toEqual({
      upiId: 'ravi@okhdfc',
      name: 'Ravi Kumar',
      amount: '99.50',
    });
  });

  it('rejects non-UPI payloads', () => {
    expect(parseUpiQr('https://example.com')).toBeNull();
    expect(parseUpiQr('upi://pay?pn=NoPayee')).toBeNull();
  });

  it('round-trips the receive QR', () => {
    expect(parseUpiQr(buildUpiUri({ upiId: 'ravi@upi', name: 'Ravi K' }))).toEqual({ upiId: 'ravi@upi', name: 'Ravi K' });
  });
});

describe('scanner', () => {
  beforeEach(() => signIn());

  it('hands a scanned UPI QR to the pay screen', async () => {
    mockPayload = 'upi://pay?pa=anu%40upi&pn=Anu%20K&am=150&cu=INR';
    mockBackend({ searchByUpiId: { status: 'success', upiName: 'Anu K', phoneNumber: '+919123456789' } });
    await renderRouter('./src/app', { initialUrl: '/qr-scanner' });

    expect(await screen.findByText('anu@upi')).toBeOnTheScreen();
    expect(screen.getByText('₹150')).toBeOnTheScreen();
    await press(screen.getByText('Proceed to pay'));

    expect(await screen.findByText('pay to upi id')).toBeOnTheScreen();
    expect(await screen.findByText('+919123456789')).toBeOnTheScreen();
    expect(screen.getByDisplayValue('150')).toBeOnTheScreen();
  });

  it('explains non-payment codes', async () => {
    mockPayload = 'hello world';
    mockBackend({});
    await renderRouter('./src/app', { initialUrl: '/qr-scanner' });
    expect(await screen.findByText('Not a UPI payment code: hello world')).toBeOnTheScreen();
  });
});
