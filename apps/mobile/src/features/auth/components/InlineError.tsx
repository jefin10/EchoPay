import { StyleSheet, View } from 'react-native';

import { AppText, Entrance, Icon } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';

/** Coral error chip shown under auth inputs. Renders nothing when empty. */
export function InlineError({ message }: { message: string | null }) {
  if (!message) return null;
  return (
    <Entrance distance={8} style={styles.wrap}>
      <View style={styles.chip} accessibilityRole="alert">
        <Icon name="info-outline" size={18} color={Colors.coral} />
        <AppText style={[Type.body(13, 600, Colors.coral), styles.text]}>{message}</AppText>
      </View>
    </Entrance>
  );
}

const styles = StyleSheet.create({
  wrap: { marginTop: 14 },
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 12,
    backgroundColor: alpha(Colors.coral, 0.08),
    borderWidth: 1,
    borderColor: alpha(Colors.coral, 0.3),
  },
  text: { flex: 1 },
});
