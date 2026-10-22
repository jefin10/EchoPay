import { renderRouter, screen } from 'expo-router/testing-library';

import { mockBackend, press, signIn, type } from './test-utils';

jest.mock('expo-contacts', () => ({
  requestPermissionsAsync: jest.fn().mockResolvedValue({ granted: true }),
  ContactField: { FULL_NAME: 'fullName', PHONES: 'phones' },
  ContactsSortOrder: { GivenName: 'givenName' },
  Contact: {
    getAllDetails: jest.fn().mockResolvedValue([
      { id: '1', fullName: 'Priya Sharma', phones: [{ number: '+91 91234 56789' }] },
      { id: '2', fullName: 'Arjun', phones: [{ number: '98765 00000' }] },
    ]),
  },
}));

const bodyOf = (fetchMock: jest.Mock, path: string) =>
  JSON.parse(fetchMock.mock.calls.find(([url]) => url.includes(path))![1].body);

beforeEach(() => signIn());

it('pays a phone number after looking it up', async () => {
  const fetchMock = mockBackend({
    searchPhonenumber: { status: 'success', upiName: 'anu', upiId: 'anu@upi' },
    sendMoneyPhone: { status: 'success', message: 'Successfully sent 250 to anu' },
    getBalance: { balance: '4750.00' },
    getTransactions: { transactions: { sent: [], received: [] } },
  });
  await renderRouter('./src/app', { initialUrl: '/pay/phone' });

  await type(await screen.findByLabelText('Phone number'), '98765 43210');
  await press(screen.getByLabelText('Search'));
  expect(await screen.findByText('anu@upi')).toBeOnTheScreen();
  expect(fetchMock.mock.calls[0][0]).toContain('phoneNumber=%2B919876543210');

  await press(screen.getByText('Pay now'));
  expect(await screen.findByText('Please enter a valid amount.')).toBeOnTheScreen();

  await type(screen.getByLabelText('Amount'), '250');
  await press(screen.getByText('Pay now'));
  expect(await screen.findByText('Payment sent')).toBeOnTheScreen();
  expect(screen.getByText('₹250.00 to anu')).toBeOnTheScreen();
  expect(bodyOf(fetchMock, 'sendMoneyPhone')).toEqual({
    senderPhone: '+919876543210',
    receiverPhone: '+919876543210',
    amount: 250,
  });
});

it('shows backend errors such as insufficient balance', async () => {
  mockBackend({
    searchByUpiId: { status: 'success', upiName: 'anu', phoneNumber: '+919123456789' },
    sendMoneyId: [{ status: 'error', error: 'Insufficient balance' }, 400],
  });
  // Prefilled as if from a scanned QR.
  await renderRouter('./src/app', { initialUrl: '/pay/upi?upi=anu%40upi&amount=99999&name=Anu' });

  expect(await screen.findByText('+919123456789')).toBeOnTheScreen();
  expect(screen.getByDisplayValue('99999')).toBeOnTheScreen();
  await press(screen.getByText('Pay now'));
  expect(await screen.findByText('Insufficient balance')).toBeOnTheScreen();
});

it('rejects malformed UPI IDs before calling the backend', async () => {
  const fetchMock = mockBackend({});
  await renderRouter('./src/app', { initialUrl: '/pay/upi' });
  await type(await screen.findByLabelText('name@upi'), 'not-an-id');
  await press(screen.getByLabelText('Search'));
  expect(await screen.findByText('That does not look like a UPI ID (name@bank).')).toBeOnTheScreen();
  expect(fetchMock.mock.calls.some(([url]) => url.includes('searchByUpiId'))).toBe(false);
});

it('pays a contact who has an account', async () => {
  const fetchMock = mockBackend({
    checkHasAccount: { hasAccount: true, status: 'success' },
    sendMoneyPhone: { status: 'success' },
    getBalance: { balance: '1' },
    getTransactions: { transactions: {} },
  });
  await renderRouter('./src/app', { initialUrl: '/pay/contacts' });

  await type(await screen.findByPlaceholderText('Search name or number'), 'pri');
  expect(screen.queryByText('Arjun')).toBeNull();
  await press(screen.getByText('Priya Sharma'));

  await type(await screen.findByLabelText('Amount'), '120.5');
  await press(screen.getByText('Pay now'));
  expect(await screen.findByText('₹120.50 to Priya Sharma')).toBeOnTheScreen();
  expect(bodyOf(fetchMock, 'sendMoneyPhone')).toMatchObject({ receiverPhone: '+919123456789', amount: 120.5 });
});

it('tells the user when a contact is not on EchoPay', async () => {
  mockBackend({ checkHasAccount: [{ hasAccount: false }, 404] });
  await renderRouter('./src/app', { initialUrl: '/pay/contacts' });
  await press(await screen.findByText('Arjun'));
  expect(await screen.findByText('No UPI account found for this contact.')).toBeOnTheScreen();
});
