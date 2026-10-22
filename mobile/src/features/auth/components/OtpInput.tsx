import { useEffect, useImperativeHandle, useRef, useState, type Ref } from 'react';
import { StyleSheet, TextInput, View, type TextInputInstance } from 'react-native';
import Animated, { useAnimatedStyle, useSharedValue, withSequence, withTiming } from 'react-native-reanimated';

import { Colors, Type } from '@/core/theme';

export interface OtpInputHandle {
  /** Clear all boxes, refocus the first one and shake the row. */
  reject(): void;
}

const LENGTH = 6;

/** Six single-digit boxes with auto-advance, backspace-to-previous and paste/autofill support. */
export function OtpInput({ onComplete, ref }: { onComplete: (code: string) => void; ref?: Ref<OtpInputHandle> }) {
  const [digits, setDigits] = useState<string[]>(Array(LENGTH).fill(''));
  const [focused, setFocused] = useState(0);
  const inputs = useRef<(TextInputInstance | null)[]>([]);
  const shake = useSharedValue(0);

  useEffect(() => {
    const t = setTimeout(() => inputs.current[0]?.focus(), 300);
    return () => clearTimeout(t);
  }, []);

  useImperativeHandle(ref, () => ({
    reject() {
      setDigits(Array(LENGTH).fill(''));
      inputs.current[0]?.focus();
      const step = { duration: 50 };
      shake.set(
        withSequence(
          withTiming(8, step),
          withTiming(-8, step),
          withTiming(6, step),
          withTiming(-6, step),
          withTiming(0, step),
        ),
      );
    },
  }));

  const shakeStyle = useAnimatedStyle(() => ({ transform: [{ translateX: shake.get() }] }));

  const update = (next: string[]) => {
    setDigits(next);
    if (next.every((d) => d !== '')) onComplete(next.join(''));
  };

  const onChange = (index: number, text: string) => {
    const clean = text.replace(/\D/g, '');
    if (clean.length > 1) {
      // Paste or SMS autofill: spread from this box onwards.
      const next = [...digits];
      clean
        .slice(0, LENGTH - index)
        .split('')
        .forEach((d, i) => (next[index + i] = d));
      update(next);
      inputs.current[Math.min(index + clean.length, LENGTH - 1)]?.focus();
      return;
    }
    const next = [...digits];
    next[index] = clean;
    update(next);
    if (clean && index < LENGTH - 1) inputs.current[index + 1]?.focus();
  };

  return (
    <Animated.View style={[styles.row, shakeStyle]}>
      {digits.map((d, i) => (
        <View
          key={i}
          style={[styles.box, d ? styles.filled : null, focused === i ? styles.focused : null]}>
          <TextInput
            ref={(el) => {
              inputs.current[i] = el;
            }}
            value={d}
            onChangeText={(t) => onChange(i, t)}
            onKeyPress={({ nativeEvent }) => {
              if (nativeEvent.key === 'Backspace' && !digits[i] && i > 0) {
                const next = [...digits];
                next[i - 1] = '';
                setDigits(next);
                inputs.current[i - 1]?.focus();
              }
            }}
            onFocus={() => setFocused(i)}
            keyboardType="number-pad"
            textContentType={i === 0 ? 'oneTimeCode' : 'none'}
            autoComplete={i === 0 ? 'sms-otp' : 'off'}
            maxLength={i === 0 ? LENGTH : 1}
            selectTextOnFocus
            caretHidden
            accessibilityLabel={`Digit ${i + 1}`}
            style={[Type.heading(22, 800), styles.input]}
          />
        </View>
      ))}
    </Animated.View>
  );
}

const styles = StyleSheet.create({
  row: { flexDirection: 'row', justifyContent: 'space-between' },
  box: {
    width: 46,
    height: 56,
    borderRadius: 12,
    backgroundColor: Colors.surface,
    borderWidth: 1.5,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  filled: { borderColor: Colors.borderStrong },
  focused: { borderColor: Colors.ink, borderWidth: 2 },
  input: { width: '100%', height: '100%', textAlign: 'center', padding: 0 },
});
