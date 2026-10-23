import * as LocalAuthentication from 'expo-local-authentication';

export type AuthOutcome = 'success' | 'cancelled' | 'unavailable';

/**
 * Ask for biometrics (falling back to the device PIN/pattern). Devices with
 * no biometric hardware or nothing enrolled report `unavailable`, which
 * callers treat as allowed, so the app still works on devices without it.
 */
export async function authenticate(reason: string): Promise<AuthOutcome> {
  try {
    const [hasHardware, enrolled] = await Promise.all([
      LocalAuthentication.hasHardwareAsync(),
      LocalAuthentication.isEnrolledAsync(),
    ]);
    if (!hasHardware || !enrolled) return 'unavailable';
    const result = await LocalAuthentication.authenticateAsync({
      promptMessage: reason,
      cancelLabel: 'Cancel',
      disableDeviceFallback: false,
    });
    return result.success ? 'success' : 'cancelled';
  } catch {
    return 'cancelled';
  }
}

/** Confirm a sensitive action. Resolves true when allowed to proceed. */
export async function confirmWithBiometrics(reason: string, enabled = true): Promise<boolean> {
  if (!enabled) return true;
  return (await authenticate(reason)) !== 'cancelled';
}
