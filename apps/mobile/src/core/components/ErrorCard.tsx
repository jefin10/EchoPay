import { StyleSheet, View } from 'react-native';

import { alpha, Colors, Type } from '@/core/theme';

import { AppText } from './AppText';
import { Icon } from './Icon';
import { Tap } from './Tap';

/** Coral inline error with an optional retry action. */
export function ErrorCard({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <View style={styles.box} accessibilityRole="alert">
      <Icon name="info-outline" size={18} color={Colors.coral} />
      <AppText style={[Type.body(13, 600, Colors.coral), styles.text]}>{message}</AppText>
      {onRetry && (
        <Tap onPress={onRetry} accessibilityRole="button" hitSlop={8}>
          <AppText style={Type.body(13, 800, Colors.coral)}>Retry</AppText>
        </Tap>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    padding: 16,
    borderRadius: 16,
    backgroundColor: alpha(Colors.coral, 0.08),
    borderWidth: 1,
    borderColor: alpha(Colors.coral, 0.3),
  },
  text: { flex: 1 },
});
