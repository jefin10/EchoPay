import type { ReactNode } from 'react';
import { StyleSheet, TextInput, View, type TextInputProps } from 'react-native';

import { Colors, Type } from '@/core/theme';

import { AppText } from './AppText';

type FieldProps = TextInputProps & {
  label?: string;
  left?: ReactNode;
  right?: ReactNode;
  error?: string | null;
};

/** Labelled text input on a white bordered surface. */
export function Field({ label, left, right, error, style, ...rest }: FieldProps) {
  return (
    <View style={styles.wrap}>
      {label && <AppText style={Type.eyebrow()}>{label}</AppText>}
      <View style={[styles.box, error ? styles.boxError : null]}>
        {left}
        <TextInput
          placeholderTextColor={Colors.textMuted}
          selectionColor={Colors.primary}
          {...rest}
          style={[Type.body(16, 600), styles.input, style]}
        />
        {right}
      </View>
      {error ? <AppText style={Type.body(12, 600, Colors.coral)}>{error}</AppText> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  wrap: { gap: 8 },
  box: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    backgroundColor: Colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingHorizontal: 16,
    minHeight: 56,
  },
  boxError: { borderColor: Colors.coral },
  input: { flex: 1, paddingVertical: 14 },
});
