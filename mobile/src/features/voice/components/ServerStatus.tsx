import { StyleSheet, View } from 'react-native';

import { AppText, Tap } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';

import { useVoiceServerHealth } from '../hooks';

/** Online/offline pill for the intent server; tap to re-check. */
export function ServerStatus() {
  const health = useVoiceServerHealth();
  const online = health.data === true;
  const color = health.isLoading ? Colors.textMuted : online ? Colors.mint : Colors.coral;
  return (
    <Tap
      onPress={() => health.refetch()}
      style={[styles.pill, { backgroundColor: alpha(color, 0.12) }]}
      accessibilityLabel={`Voice server ${online ? 'online' : 'offline'}. Tap to re-check.`}>
      <View style={[styles.dot, { backgroundColor: color }]} />
      <AppText style={Type.body(12, 700, color)}>{health.isLoading ? 'Checking' : online ? 'Online' : 'Offline'}</AppText>
    </Tap>
  );
}

const styles = StyleSheet.create({
  pill: { flexDirection: 'row', alignItems: 'center', gap: 6, paddingHorizontal: 10, paddingVertical: 6, borderRadius: 20 },
  dot: { width: 7, height: 7, borderRadius: 4 },
});
