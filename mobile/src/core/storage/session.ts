import Storage from 'expo-sqlite/kv-store';
import { create } from 'zustand';

/**
 * Everything the app persists locally, behind one typed store.
 *
 * Reads are synchronous (expo-sqlite kv-store), so the root layout can pick
 * the first screen without a loading flash.
 */
const K = {
  phoneNumber: 'phoneNumber',
  isLoggedIn: 'isLoggedIn',
  userName: 'userName',
  upiId: 'upiId',
} as const;

/** Boolean preferences (biometrics, notification toggles). */
export type FlagKey =
  | 'biometricEnabled'
  | 'notif_payments'
  | 'notif_requests'
  | 'notif_promotions';

const FLAG_DEFAULTS: Record<FlagKey, boolean> = {
  biometricEnabled: true,
  notif_payments: true,
  notif_requests: true,
  notif_promotions: false,
};

interface SessionState {
  phoneNumber: string | null;
  isLoggedIn: boolean;
  userName: string | null;
  upiId: string | null;
  flags: Record<FlagKey, boolean>;
  /** Biometric unlock passed this app run. In memory only, so every launch asks again. */
  unlocked: boolean;

  setPhoneNumber(phone: string): void;
  setLoggedIn(value: boolean): void;
  /** Persist the full identity after a successful login/signup. */
  saveSession(args: { phoneNumber: string; userName?: string | null; upiId?: string | null }): void;
  setFlag(key: FlagKey, value: boolean): void;
  setUnlocked(value: boolean): void;
  /** Wipe all persisted state (logout). */
  clear(): void;
}

const getBool = (key: string, fallback: boolean) => {
  const raw = Storage.getItemSync(key);
  return raw == null ? fallback : raw === 'true';
};

const readFlags = () =>
  Object.fromEntries(
    (Object.keys(FLAG_DEFAULTS) as FlagKey[]).map((k) => [k, getBool(k, FLAG_DEFAULTS[k])]),
  ) as Record<FlagKey, boolean>;

const readInitialState = () => ({
  phoneNumber: Storage.getItemSync(K.phoneNumber),
  isLoggedIn: getBool(K.isLoggedIn, false),
  userName: Storage.getItemSync(K.userName),
  upiId: Storage.getItemSync(K.upiId),
  flags: readFlags(),
  unlocked: false,
});

export const useSession = create<SessionState>()((set) => ({
  ...readInitialState(),

  setPhoneNumber(phone) {
    Storage.setItemSync(K.phoneNumber, phone);
    set({ phoneNumber: phone });
  },

  setLoggedIn(value) {
    Storage.setItemSync(K.isLoggedIn, String(value));
    set({ isLoggedIn: value });
  },

  saveSession({ phoneNumber, userName, upiId }) {
    Storage.setItemSync(K.phoneNumber, phoneNumber);
    Storage.setItemSync(K.isLoggedIn, 'true');
    const patch: Partial<SessionState> = { phoneNumber, isLoggedIn: true };
    if (userName) {
      Storage.setItemSync(K.userName, userName);
      patch.userName = userName;
    }
    if (upiId) {
      Storage.setItemSync(K.upiId, upiId);
      patch.upiId = upiId;
    }
    set(patch);
  },

  setFlag(key, value) {
    Storage.setItemSync(key, String(value));
    set((s) => ({ flags: { ...s.flags, [key]: value } }));
  },

  setUnlocked(value) {
    set({ unlocked: value });
  },

  clear() {
    Storage.clearSync();
    set({ ...readInitialState() });
  },
}));

/** Logged in but still has to pass the biometric gate this run. */
export const selectNeedsUnlock = (s: SessionState) => s.isLoggedIn && s.flags.biometricEnabled && !s.unlocked;

/** Non-hook accessor for use outside React (repositories, query functions). */
export const getSession = () => useSession.getState();
