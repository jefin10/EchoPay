import { StyleSheet, Switch, View } from 'react-native';

import { AppText, Icon, Tap, type IconName } from '@/core/components';
import { Colors, Type } from '@/core/theme';

const IconTile = ({ icon }: { icon: IconName }) => (
  <View style={styles.icon}>
    <Icon name={icon} size={19} />
  </View>
);

/** Settings row with icon, title, subtitle and a chevron. */
export function MenuRow({
  icon,
  title,
  subtitle,
  onPress,
}: {
  icon: IconName;
  title: string;
  subtitle?: string;
  onPress?: () => void;
}) {
  return (
    <Tap scale={0.98} onPress={onPress} disabled={!onPress} style={styles.row} accessibilityRole="button">
      <IconTile icon={icon} />
      <View style={styles.flex}>
        <AppText style={Type.body(15, 700)}>{title}</AppText>
        {subtitle ? <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]}>{subtitle}</AppText> : null}
      </View>
      {onPress && <Icon name="chevron-right" size={20} color={Colors.textMuted} />}
    </Tap>
  );
}

/** Settings row with a switch. */
export function ToggleRow({
  icon,
  title,
  subtitle,
  value,
  onValueChange,
}: {
  icon?: IconName;
  title: string;
  subtitle?: string;
  value: boolean;
  onValueChange: (v: boolean) => void;
}) {
  return (
    <View style={styles.row}>
      {icon && <IconTile icon={icon} />}
      <View style={styles.flex}>
        <AppText style={Type.body(15, 700)}>{title}</AppText>
        {subtitle ? <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]}>{subtitle}</AppText> : null}
      </View>
      <Switch
        value={value}
        onValueChange={onValueChange}
        trackColor={{ false: Colors.borderStrong, true: Colors.ink }}
        thumbColor={value ? Colors.pop : Colors.surface}
        accessibilityLabel={title}
      />
    </View>
  );
}

/** Two-column label/value row. */
export function InfoRow({ icon, label, value }: { icon?: IconName; label: string; value: string }) {
  return (
    <View style={styles.row}>
      {icon && <IconTile icon={icon} />}
      <AppText style={[Type.body(13, 500, Colors.textSecondary), styles.flex]}>{label}</AppText>
      <AppText style={Type.body(14, 700)} numberOfLines={1}>
        {value}
      </AppText>
    </View>
  );
}

/** White grouped card that separates its rows with dividers. */
export function MenuGroup({ children }: { children: React.ReactNode }) {
  const rows = Array.isArray(children) ? children.filter(Boolean) : [children];
  return (
    <View style={styles.group}>
      {rows.map((row, i) => (
        <View key={i} style={i > 0 ? styles.divided : null}>
          {row}
        </View>
      ))}
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 14 },
  icon: {
    width: 40,
    height: 40,
    borderRadius: 12,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sub: { marginTop: 2 },
  group: {
    paddingHorizontal: 16,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  divided: { borderTopWidth: 1, borderTopColor: Colors.divider },
});
