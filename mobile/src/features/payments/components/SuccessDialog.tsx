import { StyleSheet, View } from 'react-native';

import { AppButton, AppDialog, AppText, Icon } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';

/** Green tick confirmation shown after a payment or request succeeds. */
export function SuccessDialog({
  visible,
  title,
  message,
  onDone,
}: {
  visible: boolean;
  title: string;
  message: string;
  onDone: () => void;
}) {
  return (
    <AppDialog visible={visible} onClose={onDone}>
      <View style={styles.tick}>
        <Icon name="check" size={32} color={Colors.mint} />
      </View>
      <AppText style={[Type.heading(22), styles.title]}>{title}</AppText>
      <AppText style={[Type.body(14, 500, Colors.textSecondary), styles.message]}>{message}</AppText>
      <AppButton label="Done" onPress={onDone} style={styles.button} />
    </AppDialog>
  );
}

const styles = StyleSheet.create({
  tick: {
    width: 64,
    height: 64,
    borderRadius: 20,
    backgroundColor: alpha(Colors.mint, 0.12),
    alignItems: 'center',
    justifyContent: 'center',
  },
  title: { marginTop: 18 },
  message: { marginTop: 4, textAlign: 'center' },
  button: { alignSelf: 'stretch', marginTop: 22 },
});
