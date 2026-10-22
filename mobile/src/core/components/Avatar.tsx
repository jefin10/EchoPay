import { StyleSheet, View } from 'react-native';

import { initials } from '@/core/utils/format';
import { Colors, Type } from '@/core/theme';

import { AppText } from './AppText';

/** Rounded-square initials avatar. */
export function Avatar({
  name,
  size = 44,
  background = Colors.surfaceDim,
  color = Colors.ink,
}: {
  name: string;
  size?: number;
  background?: string;
  color?: string;
}) {
  return (
    <View style={[styles.box, { width: size, height: size, borderRadius: size * 0.3, backgroundColor: background }]}>
      <AppText style={Type.heading(size * 0.36, 700, color, 0)}>{initials(name)}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  box: { alignItems: 'center', justifyContent: 'center' },
});
