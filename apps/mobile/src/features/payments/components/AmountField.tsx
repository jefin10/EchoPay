import type { TextInputProps } from 'react-native';

import { AppText, Field } from '@/core/components';
import { Type } from '@/core/theme';

import { sanitizeAmountInput } from '../amount';

/** Rupee amount input: decimal keyboard, ₹ prefix, input sanitised to 2dp. */
export function AmountField({
  value,
  onChangeText,
  label = 'Amount',
  error,
  ...rest
}: Omit<TextInputProps, 'onChangeText'> & {
  value: string;
  onChangeText: (v: string) => void;
  label?: string;
  error?: string | null;
}) {
  return (
    <Field
      label={label}
      value={value}
      onChangeText={(t) => onChangeText(sanitizeAmountInput(t))}
      placeholder="0"
      keyboardType="decimal-pad"
      error={error}
      left={<AppText style={Type.body(16, 800)}>₹</AppText>}
      style={Type.body(18, 700)}
      accessibilityLabel={label}
      {...rest}
    />
  );
}
