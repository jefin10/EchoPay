import { useSession } from '@/core/storage/session';

describe('session store', () => {
  beforeEach(() => useSession.getState().clear());

  it('starts logged out with default flags', () => {
    const s = useSession.getState();
    expect(s.isLoggedIn).toBe(false);
    expect(s.phoneNumber).toBeNull();
    expect(s.flags.biometricEnabled).toBe(true);
    expect(s.flags.notif_promotions).toBe(false);
  });

  it('saves and clears a session', () => {
    useSession.getState().saveSession({ phoneNumber: '+919876543210', userName: 'Ravi', upiId: 'ravi@upi' });
    expect(useSession.getState()).toMatchObject({
      isLoggedIn: true,
      phoneNumber: '+919876543210',
      userName: 'Ravi',
      upiId: 'ravi@upi',
    });

    useSession.getState().clear();
    expect(useSession.getState()).toMatchObject({ isLoggedIn: false, phoneNumber: null, userName: null });
  });

  it('persists flags', () => {
    useSession.getState().setFlag('biometricEnabled', false);
    expect(useSession.getState().flags.biometricEnabled).toBe(false);
  });
});
