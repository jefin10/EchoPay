import { act, fireEvent, renderRouter, screen } from 'expo-router/testing-library';

import { useSession } from '@/core/storage/session';

jest.mock('expo-local-authentication', () => ({
  hasHardwareAsync: jest.fn().mockResolvedValue(true),
  isEnrolledAsync: jest.fn().mockResolvedValue(true),
  authenticateAsync: jest.fn().mockResolvedValue({ success: false }),
}));

const fetchMock = jest.fn();
globalThis.fetch = fetchMock as unknown as typeof fetch;
const respond = (body: unknown, status = 200) =>
  Promise.resolve({ status, text: () => Promise.resolve(JSON.stringify(body)) });

type Element = Parameters<typeof fireEvent.press>[0];

// Await each interaction so async state updates settle before asserting.
const type = (el: Element, text: string) => act(async () => fireEvent.changeText(el, text));
const press = (el: Element) => act(async () => fireEvent.press(el));

beforeEach(() => {
  fetchMock.mockReset();
  useSession.getState().clear();
});

it('signs up a new user: phone → OTP → name → biometric gate', async () => {
  fetchMock
    .mockReturnValueOnce(respond({ status: 'success', otp: '123456' })) // send_otp
    .mockReturnValueOnce(respond({ status: 'success', isNewUser: true, phoneNumber: '+919876543210' })) // verify_otp
    .mockReturnValueOnce(
      respond({ status: 'success', upiName: 'Ravi', phoneNumber: '+919876543210', upiId: 'ravi@upi' }),
    ); // signup

  await renderRouter('./src/app');

  await type(await screen.findByPlaceholderText('Mobile number'), '9876543210');
  await press(screen.getByText('Send code'));

  expect(await screen.findByText(/backend returned code 123456/)).toBeOnTheScreen();
  expect(fetchMock.mock.calls[0][0]).toContain('send_otp/?phone=%2B919876543210');

  await type(screen.getByLabelText('Digit 1'), '123456');

  await type(await screen.findByPlaceholderText('Your full name'), 'Ravi');
  await press(screen.getByText('Create account'));

  expect(await screen.findByText('Unlock to continue to your wallet.')).toBeOnTheScreen();
  expect(useSession.getState()).toMatchObject({ isLoggedIn: true, phoneNumber: '+919876543210', upiId: 'ravi@upi' });
});

it('shows the backend error for a wrong OTP', async () => {
  fetchMock
    .mockReturnValueOnce(respond({ status: 'success' }))
    .mockReturnValueOnce(respond({ status: 'error', message: 'Invalid OTP' }, 400));

  await renderRouter('./src/app');
  await type(await screen.findByPlaceholderText('Mobile number'), '9876543210');
  await press(screen.getByText('Send code'));
  await type(await screen.findByLabelText('Digit 1'), '000000');

  expect(await screen.findByText('Invalid OTP')).toBeOnTheScreen();
  expect(useSession.getState().isLoggedIn).toBe(false);
});
