import { ActivityIndicator, StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { Colors, Type } from '@/core/theme';

import { AppText } from './AppText';
import { Icon, type IconName } from './Icon';
import { Tap } from './Tap';

interface AppButtonProps {
  label: string;
  onPress?: () => void;
  icon?: IconName;
  loading?: boolean;
  disabled?: boolean;
  background?: string;
  foreground?: string;
  /** Outlined secondary style. */
  outline?: boolean;
  style?: StyleProp<ViewStyle>;
}

/**
 * The primary call-to-action: ink fill, 16px radius, press-scale feedback
 * and a built-in loading state. Disabled and loading both block the tap.
 */
export function AppButton({
  label,
  onPress,
  icon,
  loading = false,
  disabled = false,
  background = Colors.ink,
  foreground = Colors.white,
  outline = false,
  style,
}: AppButtonProps) {
  const blocked = disabled || loading || !onPress;
  const fg = outline ? Colors.ink : foreground;
  return (
    <Tap
      onPress={blocked ? undefined : onPress}
      disabled={blocked}
      accessibilityRole="button"
      accessibilityState={{ disabled: blocked, busy: loading }}
      style={[
        styles.base,
        outline ? styles.outline : { backgroundColor: background },
        blocked && !loading && styles.disabled,
        style,
      ]}>
      {loading ? (
        <ActivityIndicator color={fg} />
      ) : (
        <View style={styles.row}>
          <AppText style={[Type.body(15, 700, fg), styles.label]}>{label}</AppText>
          {icon && <Icon name={icon} size={20} color={fg} />}
        </View>
      )}
    </Tap>
  );
}

const styles = StyleSheet.create({
  base: {
    minHeight: 56,
    paddingHorizontal: 22,
    borderRadius: 16,
    alignItems: 'center',
    justifyContent: 'center',
  },
  outline: { borderWidth: 1.5, borderColor: Colors.borderStrong, backgroundColor: 'transparent' },
  disabled: { opacity: 0.45 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  label: { letterSpacing: 0.1 },
});
