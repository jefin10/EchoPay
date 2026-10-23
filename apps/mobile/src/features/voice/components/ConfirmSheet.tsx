import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton, AppText, Avatar, ErrorCard, Sheet, Tap } from '@/core/components';
import { Colors, Type } from '@/core/theme';
import { parseAmount } from '@/features/payments/amount';
import { AmountField } from '@/features/payments/components/AmountField';
import type { DeviceContact } from '@/features/payments/contacts';

import { targetFromContact, type Target } from '../resolve';

/**
 * Confirm a voice payment or request. The amount stays editable (speech
 * often gets it wrong or misses it), and an ambiguous spoken name shows the
 * matching contacts to pick from first.
 */
export function ConfirmSheet({
  mode,
  initialAmount,
  target: initialTarget,
  choices,
  busy,
  onCancel,
  onConfirm,
}: {
  mode: 'transfer' | 'request';
  initialAmount?: number;
  target?: Target;
  choices?: { name: string; matches: DeviceContact[] };
  busy: boolean;
  onCancel: () => void;
  onConfirm: (amount: number, target: Target) => void;
}) {
  const [target, setTarget] = useState<Target | undefined>(initialTarget);
  const [amount, setAmount] = useState(initialAmount ? String(initialAmount) : '');
  const [error, setError] = useState<string | null>(null);

  const confirm = () => {
    const value = parseAmount(amount);
    if (value == null) return setError('Please enter a valid amount.');
    if (target) onConfirm(value, target);
  };

  return (
    <Sheet visible onClose={onCancel} dismissable={!busy}>
      {!target && choices ? (
        <View style={styles.body}>
          <AppText style={Type.eyebrow()}>which {choices.name}?</AppText>
          <AppText style={Type.heading(22)}>Pick a contact</AppText>
          {choices.matches.map((c) => (
            <Tap key={c.id} onPress={() => setTarget(targetFromContact(c))} style={styles.contact} accessibilityRole="button">
              <Avatar name={c.name} size={40} />
              <View style={styles.flex}>
                <AppText style={Type.body(15, 700)}>{c.name}</AppText>
                <AppText style={Type.body(12, 500, Colors.textSecondary)}>{c.phone}</AppText>
              </View>
            </Tap>
          ))}
          <AppButton label="Cancel" outline onPress={onCancel} />
        </View>
      ) : target ? (
        <View style={styles.body}>
          <AppText style={[Type.eyebrow(), styles.center]}>{mode === 'transfer' ? 'voice pay' : 'request money'}</AppText>
          <AppText style={[Type.body(15, 600, Colors.textSecondary), styles.center]}>
            {mode === 'transfer' ? 'to' : 'from'} <AppText style={Type.body(15, 800)}>{target.label}</AppText>
            {target.kind === 'phone' && target.label !== target.phone ? ` · ${target.phone}` : ''}
          </AppText>
          <AmountField value={amount} onChangeText={setAmount} autoFocus={!initialAmount} />
          {error && <ErrorCard message={error} />}
          <View style={styles.actions}>
            <AppButton label="Cancel" outline onPress={onCancel} disabled={busy} style={styles.flex} />
            <AppButton
              label={mode === 'transfer' ? 'Confirm' : 'Send request'}
              onPress={confirm}
              loading={busy}
              style={styles.flex}
            />
          </View>
        </View>
      ) : null}
    </Sheet>
  );
}

const styles = StyleSheet.create({
  body: { gap: 16 },
  flex: { flex: 1 },
  center: { textAlign: 'center' },
  contact: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 12,
    borderRadius: 16,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  actions: { flexDirection: 'row', gap: 10 },
});
