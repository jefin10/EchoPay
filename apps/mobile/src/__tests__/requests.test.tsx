import { renderRouter, screen } from 'expo-router/testing-library';

import { mockBackend, press, signIn, type } from './test-utils';

const REQUESTS = {
  status: 'success',
  sentRequests: [
    {
      id: 7,
      requestee__user__upiName: 'arjun',
      requestee__user__phoneNumber: '+919000000001',
      amount: '300.00',
      message: 'movie',
      status: 'pending',
      created_at: '2026-10-20T10:00:00Z',
    },
  ],
  receivedRequests: [
    {
      id: 9,
      requester__user__upiName: 'priya',
      requester__user__phoneNumber: '+919000000002',
      amount: '150.00',
      message: 'lunch',
      status: 'pending',
      created_at: '2026-10-21T10:00:00Z',
    },
  ],
};

const bodiesOf = (fetchMock: jest.Mock, path: string) =>
  fetchMock.mock.calls.filter(([url]) => url.includes(path)).map(([, init]) => JSON.parse(init.body));

beforeEach(() => signIn());

it('pays a received request', async () => {
  const fetchMock = mockBackend({
    getMoneyRequests: REQUESTS,
    updateRequestStatus: { status: 'success', message: 'Request approved successfully' },
    getBalance: { balance: '1' },
    getTransactions: { transactions: {} },
  });
  await renderRouter('./src/app', { initialUrl: '/requests' });

  expect(await screen.findByText('priya')).toBeOnTheScreen();
  expect(screen.getByText('“lunch”')).toBeOnTheScreen();
  await press(screen.getByText('Pay'));
  expect(await screen.findByText('Paid')).toBeOnTheScreen();
  expect(bodiesOf(fetchMock, 'updateRequestStatus')).toEqual([
    { requestId: 9, status: 'approved', phoneNumber: '+919876543210' },
  ]);
});

it('cancels a sent request', async () => {
  const fetchMock = mockBackend({
    getMoneyRequests: REQUESTS,
    updateRequestStatus: { status: 'success' },
    getBalance: { balance: '1' },
    getTransactions: { transactions: {} },
  });
  await renderRouter('./src/app', { initialUrl: '/requests' });
  await press(await screen.findByText('Sent'));
  expect(screen.getByText('arjun')).toBeOnTheScreen();
  await press(screen.getByText('Cancel request'));
  expect(bodiesOf(fetchMock, 'updateRequestStatus')[0]).toMatchObject({ requestId: 7, status: 'cancelled' });
});

it('creates a request by UPI ID', async () => {
  const fetchMock = mockBackend({
    getMoneyRequests: { sentRequests: [], receivedRequests: [] },
    createMoneyRequestByUpi: { status: 'success', requestId: 11 },
  });
  await renderRouter('./src/app', { initialUrl: '/requests' });
  await press(await screen.findByText('New request'));
  await type(await screen.findByLabelText('Phone number or UPI ID'), 'anu@upi');
  await type(screen.getByLabelText('Amount'), '75');
  await press(screen.getByText('Send request'));

  expect(await screen.findByText('Money request sent')).toBeOnTheScreen();
  expect(bodiesOf(fetchMock, 'createMoneyRequestByUpi')[0]).toEqual({
    requesterPhone: '+919876543210',
    requesteeUpi: 'anu@upi',
    amount: 75,
    message: 'Payment request for ₹75',
  });
});
