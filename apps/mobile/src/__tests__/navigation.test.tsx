import { renderRouter, screen } from 'expo-router/testing-library';

import { useSession } from '@/core/storage/session';

jest.mock('expo-local-authentication', () => ({
  hasHardwareAsync: jest.fn().mockResolvedValue(false),
  isEnrolledAsync: jest.fn().mockResolvedValue(false),
  authenticateAsync: jest.fn(),
}));

describe('root guards', () => {
  beforeEach(() => useSession.getState().clear());

  it('sends logged-out users to onboarding', async () => {
    await renderRouter('./src/app');
    expect(await screen.findByText("What's your\nphone number?")).toBeOnTheScreen();
  });

  it('shows the biometric gate when logged in and locked', async () => {
    useSession.getState().saveSession({ phoneNumber: '+919876543210', userName: 'Ravi' });
    await renderRouter('./src/app');
    expect(await screen.findByText('Unlock to continue to your wallet.')).toBeOnTheScreen();
  });

  it('opens the wallet once unlocked', async () => {
    useSession.getState().saveSession({ phoneNumber: '+919876543210', userName: 'Ravi' });
    useSession.getState().setUnlocked(true);
    await renderRouter('./src/app');
    expect(await screen.findByLabelText('Voice assistant')).toBeOnTheScreen();
  });
});
