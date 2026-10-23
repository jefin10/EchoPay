import { act, fireEvent, renderRouter, screen } from 'expo-router/testing-library';

import { useSession } from '@/core/storage/session';

import { mockBackend, press, signIn } from './test-utils';

jest.mock('expo-clipboard', () => ({ setStringAsync: jest.fn().mockResolvedValue(true) }));

beforeEach(() => {
  signIn();
  mockBackend({
    getProfile: { status: 'success', upiName: 'Ravi', upiId: 'ravi@upi' },
    getBalance: { balance: '5000.00' },
    getTransactions: { transactions: {} },
  });
});

it('shows identity and copies the UPI ID', async () => {
  const Clipboard = jest.requireMock('expo-clipboard');
  await renderRouter('./src/app', { initialUrl: '/profile' });
  expect(await screen.findByText('ravi@upi')).toBeOnTheScreen();
  await press(screen.getByLabelText('Copy UPI ID'));
  expect(Clipboard.setStringAsync).toHaveBeenCalledWith('ravi@upi');
  expect(await screen.findByText('UPI ID copied')).toBeOnTheScreen();
});

it('turns the biometric lock off', async () => {
  await renderRouter('./src/app', { initialUrl: '/profile/security' });
  await act(async () => fireEvent(await screen.findByLabelText('Biometric lock'), 'valueChange', false));
  expect(useSession.getState().flags.biometricEnabled).toBe(false);
});

it('logs out back to onboarding', async () => {
  await renderRouter('./src/app', { initialUrl: '/profile' });
  await press(await screen.findByText('Log out'));
  await press((await screen.findAllByText('Log out')).at(-1)!);
  expect(await screen.findByText("What's your\nphone number?")).toBeOnTheScreen();
  expect(useSession.getState().isLoggedIn).toBe(false);
});
