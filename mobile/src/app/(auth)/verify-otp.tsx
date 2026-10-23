import { router, useLocalSearchParams } from 'expo-router';
import { useEffect, useRef, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { ApiException } from '@/core/api/client';
import { AppButton, AppText, IconButton, Tap } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { Colors, Type } from '@/core/theme';
import { sendOtp, verifyOtp } from '@/features/auth/api';
import { AuthLayout } from '@/features/auth/components/AuthLayout';
import { InlineError } from '@/features/auth/components/InlineError';
import { OtpInput, type OtpInputHandle } from '@/features/auth/components/OtpInput';

const RESEND_SECONDS = 30;

export default function VerifyOtpScreen() {
  const params = useLocalSearchParams<{ phone: string; devOtp?: string }>();
  const phone = params.phone ?? '';
  const [devOtp, setDevOtp] = useState(params.devOtp || null);
  const [code, setCode] = useState('');
  const [verifying, setVerifying] = useState(false);
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [timer, setTimer] = useState(RESEND_SECONDS);
  const otpRef = useRef<OtpInputHandle>(null);
  const { setPhoneNumber, saveSession } = useSession();

  useEffect(() => {
    if (timer <= 0) return;
    const t = setTimeout(() => setTimer((s) => s - 1), 1000);
    return () => clearTimeout(t);
  }, [timer]);

  const reject = (message: string) => {
    setError(message);
    setCode('');
    otpRef.current?.reject();
  };

  const verify = async (otp = code) => {
    if (otp.length !== 6) return reject('Please enter the complete OTP');
    setError(null);
    setVerifying(true);
    try {
      const result = await verifyOtp(phone, otp);
      setPhoneNumber(result.phoneNumber);
      if (result.isNewUser) {
        router.replace({ pathname: '/name-entry', params: { phone: result.phoneNumber } });
      } else {
        // Flipping isLoggedIn hands navigation to the root guards (→ biometric).
        saveSession({
          phoneNumber: result.phoneNumber,
          userName: result.profile?.userName,
          upiId: result.profile?.upiId,
        });
      }
    } catch (e) {
      reject(e instanceof ApiException ? e.message : 'Network error. Please try again.');
    } finally {
      setVerifying(false);
    }
  };

  const resend = async () => {
    if (sending) return;
    setSending(true);
    setError(null);
    try {
      setDevOtp(await sendOtp(phone));
      setTimer(RESEND_SECONDS);
    } catch (e) {
      setError(e instanceof ApiException ? e.message : 'Could not resend the code.');
    } finally {
      setSending(false);
    }
  };

  return (
    <AuthLayout
      top={<IconButton icon="arrow-back" accessibilityLabel="Back" onPress={() => router.back()} />}
      eyebrow="verify"
      title={'Enter the\n6-digit code.'}
      subtitle={
        <>
          Sent to <AppText style={Type.body(15, 700)}>{phone}</AppText>. Check your messages.
        </>
      }
      footer={<AppButton label="Verify & continue" icon="arrow-forward" loading={verifying} onPress={() => verify()} />}>
      <OtpInput
        ref={otpRef}
        onComplete={(otp) => {
          setCode(otp);
          verify(otp);
        }}
      />
      <InlineError message={error} />

      <View style={styles.resendRow}>
        <AppText style={Type.body(13, 500, Colors.textSecondary)}>{"Didn't get it?"}</AppText>
        {timer > 0 ? (
          <AppText style={Type.body(13, 700)}>Resend in {timer}s</AppText>
        ) : (
          <Tap scale={0.92} onPress={resend} disabled={sending} accessibilityRole="button">
            <AppText style={[Type.body(13, 800, sending ? Colors.textMuted : Colors.primary), !sending && styles.underline]}>
              {sending ? 'Sending' : 'Resend code'}
            </AppText>
          </Tap>
        )}
      </View>

      {__DEV__ && devOtp ? (
        <AppText style={[Type.body(12, 600, Colors.textMuted), styles.devHint]}>
          Dev build · backend returned code {devOtp}
        </AppText>
      ) : null}
    </AuthLayout>
  );
}

const styles = StyleSheet.create({
  resendRow: { flexDirection: 'row', alignItems: 'center', gap: 6, marginTop: 24 },
  underline: { textDecorationLine: 'underline' },
  devHint: { marginTop: 12 },
});
