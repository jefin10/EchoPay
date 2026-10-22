import { router } from 'expo-router';
import type { ReactNode } from 'react';
import { StyleSheet, View } from 'react-native';

import { Type } from '@/core/theme';

import { AppText } from './AppText';
import { IconButton } from './IconButton';

/** Back button + lowercase Sora title + optional right-side actions. */
export function ScreenHeader({ title, right, onBack }: { title: string; right?: ReactNode; onBack?: () => void }) {
  return (
    <View style={styles.row}>
      <IconButton icon="arrow-back" accessibilityLabel="Back" onPress={onBack ?? (() => router.back())} />
      <AppText style={[Type.heading(22), styles.title]} numberOfLines={1}>
        {title}
      </AppText>
      {right && <View style={styles.right}>{right}</View>}
    </View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  title: { flex: 1 },
  right: { flexDirection: 'row', gap: 8 },
});
