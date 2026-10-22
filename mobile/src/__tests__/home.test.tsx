import { renderRouter, screen } from 'expo-router/testing-library';

import { mockBackend, press, signIn } from './test-utils';

const TX = {
  status: 'success',
  transactions: {
    sent: [{ receiver__user__upiName: 'anu', amount: '250.00', timestamp: new Date().toISOString(), status: 'completed' }],
    received: [{ sender__user__upiName: 'mom', amount: '1000.00', timestamp: '2026-01-01T10:00:00Z', status: 'completed' }],
  },
};

beforeEach(() => {
  signIn();
  mockBackend({
    getBalance: { status: 'success', balance: '12480.50' },
    getTransactions: TX,
    getProfile: { status: 'success', upiName: 'Ravi', upiId: 'ravi@upi' },
  });
});

it('shows balance, identity and recent activity', async () => {
  await renderRouter('./src/app');
  expect(await screen.findByText('₹12,480.50')).toBeOnTheScreen();
  expect(screen.getByText('Ravi')).toBeOnTheScreen();
  expect(screen.getByText('ravi@upi')).toBeOnTheScreen();
  expect(await screen.findByText('To anu')).toBeOnTheScreen();
  expect(screen.getByText('-₹250.00')).toBeOnTheScreen();
  expect(screen.getByText('+₹1,000.00')).toBeOnTheScreen();
});

it('hides the balance', async () => {
  await renderRouter('./src/app');
  await screen.findByText('₹12,480.50');
  await press(screen.getByLabelText('Hide balance'));
  expect(screen.queryByText('₹12,480.50')).toBeNull();
});

it('filters history', async () => {
  await renderRouter('./src/app', { initialUrl: '/history' });
  expect(await screen.findByText('To anu')).toBeOnTheScreen();
  expect(screen.getByText('From mom')).toBeOnTheScreen();
  await press(screen.getByText('Received'));
  expect(screen.queryByText('To anu')).toBeNull();
  expect(screen.getByText('From mom')).toBeOnTheScreen();
});
