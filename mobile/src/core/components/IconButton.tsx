import { StyleSheet, type StyleProp, type ViewStyle } from 'react-native';

import { Colors } from '@/core/theme';

import { Icon, type IconName } from './Icon';
import { Tap } from './Tap';

/** 44×44 bordered square icon button used in screen headers. */
export function IconButton({
  icon,
  onPress,
  accessibilityLabel,
  dark = false,
  style,
}: {
  icon: IconName;
  onPress?: () => void;
  accessibilityLabel: string;
  dark?: boolean;
  style?: StyleProp<ViewStyle>;
}) {
  return (
    <Tap
      scale={0.9}
      onPress={onPress}
      accessibilityRole="button"
      accessibilityLabel={accessibilityLabel}
      style={[styles.box, dark && styles.dark, style]}>
      <Icon name={icon} size={20} color={dark ? Colors.white : Colors.ink} />
    </Tap>
  );
}

const styles = StyleSheet.create({
  box: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  dark: { backgroundColor: 'rgba(255,255,255,0.1)', borderColor: 'rgba(255,255,255,0.18)' },
});
