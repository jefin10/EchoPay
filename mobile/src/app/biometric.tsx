import { useEffect, useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import Animated, {
  useAnimatedStyle,
  useReducedMotion,
  useSharedValue,
  withRepeat,
  withTiming,
} from 'react-native-reanimated';
import { SafeAreaView } from 'react-native-safe-area-context';

import { authenticate } from '@/core/biometrics';
import { AppButton, AppLogo, AppText } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { Colors, Motion, Type } from '@/core/theme';

/** Unlock gate shown on every launch while logged in. */
export default function BiometricScreen() {
  const setUnlocked = useSession((s) => s.setUnlocked);
  const [busy, setBusy] = useState(false);
  const [status, setStatus] = useState('Tap to authenticate');
  const reduce = useReducedMotion();
  const pulse = useSharedValue(1);

  useEffect(() => {
    if (!reduce) pulse.set(withRepeat(withTiming(1.04, { duration: 1400, easing: Motion.inOut }), -1, true));
  }, [reduce, pulse]);

  const pulseStyle = useAnimatedStyle(() => ({ transform: [{ scale: pulse.get() }] }));

  const unlock = async () => {
    setBusy(true);
    setStatus('Authenticating');
    const outcome = await authenticate('Authenticate to access EchoPay');
    if (outcome === 'success') {
      setStatus('Welcome back');
      setTimeout(() => setUnlocked(true), 300);
    } else if (outcome === 'unavailable') {
      setStatus('Biometric not available');
      setTimeout(() => setUnlocked(true), 800);
    } else {
      setStatus('Authentication cancelled');
      setBusy(false);
    }
  };

  useEffect(() => {
    const t = setTimeout(unlock, 500);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <SafeAreaView style={styles.root}>
      <AppText style={Type.heading(22)}>EchoPay</AppText>
      <View style={styles.flex} />
      <Animated.View style={[styles.logoBox, pulseStyle]}>
        <AppLogo type="icon" width={88} height={88} />
      </Animated.View>
      <AppText style={[Type.heading(36, 800), styles.title]}>{'Pay smarter,\nspeak faster.'}</AppText>
      <AppText style={Type.body(15, 500, Colors.textSecondary)}>Unlock to continue to your wallet.</AppText>
      <View style={styles.flex} />
      <View style={styles.status}>
        {busy ? <ActivityIndicator size="small" color={Colors.primary} /> : <View style={styles.dot} />}
        <AppText style={Type.body(14, 600)}>{status}</AppText>
      </View>
      <AppButton label="Authenticate" icon="fingerprint" loading={busy} onPress={unlock} />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight, paddingHorizontal: 28, paddingVertical: 32 },
  flex: { flex: 1 },
  logoBox: {
    width: 132,
    height: 132,
    borderRadius: 36,
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.borderStrong,
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: { lineHeight: 40, marginTop: 36, marginBottom: 16 },
  status: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    paddingHorizontal: 18,
    paddingVertical: 14,
    marginBottom: 14,
    borderRadius: 14,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  dot: { width: 8, height: 8, borderRadius: 4, backgroundColor: Colors.pop },
});
