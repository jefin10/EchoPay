import { ActivityIndicator, StyleSheet, TextInput, View, type TextInputProps } from 'react-native';

import { Icon, Tap, type IconName } from '@/core/components';
import { Colors, Type } from '@/core/theme';

/** Input with a leading icon and an ink search button. */
export function SearchBox({
  icon,
  loading,
  onSearch,
  ...input
}: TextInputProps & { icon: IconName; loading: boolean; onSearch: () => void }) {
  return (
    <View style={styles.box}>
      <Icon name={icon} size={18} color={Colors.textSecondary} />
      <TextInput
        placeholderTextColor={Colors.textMuted}
        returnKeyType="search"
        onSubmitEditing={onSearch}
        autoCorrect={false}
        {...input}
        style={[Type.body(15, 600), styles.input]}
      />
      <Tap
        scale={0.92}
        onPress={loading ? undefined : onSearch}
        style={styles.button}
        accessibilityRole="button"
        accessibilityLabel="Search">
        {loading ? <ActivityIndicator size="small" color={Colors.white} /> : <Icon name="search" size={18} color={Colors.white} />}
      </Tap>
    </View>
  );
}

const styles = StyleSheet.create({
  box: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingLeft: 16,
    paddingRight: 9,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: Colors.borderStrong,
    backgroundColor: Colors.surface,
  },
  input: { flex: 1, paddingVertical: 18 },
  button: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
