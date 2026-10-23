import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';

import { ApiException } from '@/core/api/client';
import { AppButton, AppLogo, AppText, Icon, Sheet, Tap } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { sendOtp } from '@/features/auth/api';
import { AuthLayout } from '@/features/auth/components/AuthLayout';
import { InlineError } from '@/features/auth/components/InlineError';

const COUNTRY_CODES = ['+91', '+1', '+44', '+61', '+971'];

export default function PhoneNumberScreen() {
  const [code, setCode] = useState('+91');
  const [phone, setPhone] = useState('');
  const [pickerOpen, setPickerOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    if (!phone) return setError('Please enter phone number');
    if (phone.length !== 10) return setError('Phone number must be 10 digits');

    setError(null);
    setLoading(true);
    const full = `${code}${phone}`;
    try {
      const devOtp = await sendOtp(full);
      router.push({ pathname: '/verify-otp', params: { phone: full, devOtp: devOtp ?? '' } });
    } catch (e) {
      setError(e instanceof ApiException ? e.message : 'Network error. Please check your connection.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout
      top={
        <View style={styles.brand}>
          <View style={styles.logoBox}>
            <AppLogo type="icon" width={28} height={28} />
          </View>
          <AppText style={Type.heading(17)}>EchoPay</AppText>
        </View>
      }
      eyebrow="sign in"
      title={"What's your\nphone number?"}
      subtitle="We will send a one-time code to verify it."
      footer={
        <View style={styles.footer}>
          <AppButton label="Send code" icon="arrow-forward" loading={loading} onPress={submit} />
          <AppText style={[Type.body(12, 500, Colors.textMuted), styles.center]}>
            By continuing you agree to our Terms & Privacy.
          </AppText>
        </View>
      }>
      <View style={styles.phoneRow}>
        <Tap onPress={() => setPickerOpen(true)} style={styles.codeButton} accessibilityLabel="Country code">
          <AppText style={Type.body(16, 700)}>{code}</AppText>
          <Icon name="keyboard-arrow-down" size={18} />
        </Tap>
        <View style={styles.divider} />
        <TextInput
          value={phone}
          onChangeText={(t) => setPhone(t.replace(/\D/g, '').slice(0, 10))}
          placeholder="Mobile number"
          placeholderTextColor={Colors.textMuted}
          keyboardType="phone-pad"
          textContentType="telephoneNumber"
          autoComplete="tel"
          maxLength={10}
          autoFocus
          onSubmitEditing={submit}
          style={[Type.body(17, 600), styles.input]}
        />
      </View>
      <InlineError message={error} />

      <Sheet visible={pickerOpen} onClose={() => setPickerOpen(false)}>
        <AppText style={[Type.heading(18), styles.sheetTitle]}>Country code</AppText>
        {COUNTRY_CODES.map((c) => (
          <Tap
            key={c}
            onPress={() => {
              setCode(c);
              setPickerOpen(false);
            }}
            style={styles.codeRow}>
            <AppText style={Type.body(16, 700)}>{c}</AppText>
            {c === code && <Icon name="check" color={Colors.primary} />}
          </Tap>
        ))}
      </Sheet>
    </AuthLayout>
  );
}

const styles = StyleSheet.create({
  brand: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 28 },
  logoBox: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  phoneRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.surface,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: Colors.borderStrong,
    paddingHorizontal: 12,
  },
  codeButton: { flexDirection: 'row', alignItems: 'center', gap: 2, paddingVertical: 18 },
  divider: { width: 1.5, height: 28, backgroundColor: Colors.border, marginHorizontal: 10 },
  input: { flex: 1, paddingVertical: 18, letterSpacing: 0.5 },
  footer: { gap: 12 },
  center: { textAlign: 'center' },
  sheetTitle: { marginBottom: 8 },
  codeRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    paddingVertical: 16,
    borderBottomWidth: 1,
    borderBottomColor: Colors.divider,
  },
});
