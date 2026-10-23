import { router, useLocalSearchParams } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, TextInput, View } from 'react-native';

import { ApiException } from '@/core/api/client';
import { AppButton, AppText, Icon, IconButton } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { signUp } from '@/features/auth/api';
import { AuthLayout } from '@/features/auth/components/AuthLayout';
import { InlineError } from '@/features/auth/components/InlineError';

export default function NameEntryScreen() {
  const { phone = '' } = useLocalSearchParams<{ phone: string }>();
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const saveSession = useSession((s) => s.saveSession);

  const submit = async () => {
    const trimmed = name.trim();
    if (!trimmed) return setError('Please enter your name');
    if (trimmed.length < 2) return setError('Name must be at least 2 characters');

    setError(null);
    setLoading(true);
    try {
      const profile = await signUp({ phoneNumber: phone, upiName: trimmed });
      saveSession({ phoneNumber: profile.phoneNumber, userName: profile.userName, upiId: profile.upiId });
    } catch (e) {
      setError(e instanceof ApiException ? e.message : 'Network error. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthLayout
      top={<IconButton icon="arrow-back" accessibilityLabel="Back" onPress={() => router.back()} />}
      eyebrow="one last step"
      title={'What should\nwe call you?'}
      subtitle="Your name appears on your UPI handle and receipts."
      footer={<AppButton label="Create account" icon="arrow-forward" loading={loading} onPress={submit} />}>
      <TextInput
        value={name}
        onChangeText={setName}
        placeholder="Your full name"
        placeholderTextColor={Colors.textMuted}
        autoCapitalize="words"
        autoComplete="name"
        textContentType="name"
        autoFocus
        onSubmitEditing={submit}
        style={[Type.body(17, 600), styles.input]}
      />
      <InlineError message={error} />

      <View style={styles.perk}>
        <View style={styles.perkIcon}>
          <Icon name="bolt" size={20} />
        </View>
        <View style={styles.perkText}>
          <AppText style={Type.eyebrow(Colors.ink, 10)}>welcome bonus</AppText>
          <AppText style={Type.heading(15)}>₹5,000 ready to spend</AppText>
        </View>
      </View>
    </AuthLayout>
  );
}

const styles = StyleSheet.create({
  input: {
    backgroundColor: Colors.surface,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: Colors.borderStrong,
    paddingHorizontal: 18,
    paddingVertical: 20,
  },
  perk: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    marginTop: 24,
    paddingVertical: 14,
    paddingLeft: 16,
    paddingRight: 18,
    borderRadius: 14,
    backgroundColor: Colors.popSoft,
    borderWidth: 1,
    borderColor: alpha(Colors.pop, 0.4),
  },
  perkIcon: {
    width: 36,
    height: 36,
    borderRadius: 10,
    backgroundColor: Colors.pop,
    alignItems: 'center',
    justifyContent: 'center',
  },
  perkText: { flex: 1, gap: 3 },
});
