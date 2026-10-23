import { StyleSheet, View, type StyleProp, type ViewStyle } from 'react-native';

import { Colors, Type } from '@/core/theme';

import { AppText } from './AppText';
import { Icon, type IconName } from './Icon';

/** Small rounded pill with an uppercase eyebrow label. */
export function Chip({
  label,
  icon,
  background = Colors.pop,
  color = Colors.ink,
  style,
}: {
  label: string;
  icon?: IconName;
  background?: string;
  color?: string;
  style?: StyleProp<ViewStyle>;
}) {
  return (
    <View style={[styles.chip, { backgroundColor: background }, style]}>
      {icon && <Icon name={icon} size={14} color={color} />}
      <AppText style={Type.eyebrow(color, 10)}>{label}</AppText>
    </View>
  );
}

const styles = StyleSheet.create({
  chip: {
    flexDirection: 'row',
    alignItems: 'center',
    alignSelf: 'flex-start',
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 40,
  },
});
