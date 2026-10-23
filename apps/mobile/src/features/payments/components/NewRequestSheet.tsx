import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton, AppText, ErrorCard, Field, Sheet } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { Type } from '@/core/theme';
import { isUpiId, localPhone, toIndianE164 } from '@/core/utils/phone';

import { parseAmount } from '../amount';
import { createMoneyRequest, createMoneyRequestByUpi } from '../api';
import { AmountField } from './AmountField';

/** Ask someone (by phone number or UPI ID) to pay you. */
export function NewRequestSheet({ visible, onClose, onSent }: { visible: boolean; onClose: () => void; onSent: () => void }) {
  const requesterPhone = useSession((s) => s.phoneNumber) ?? '';
  const [who, setWho] = useState('');
  const [amount, setAmount] = useState('');
  const [message, setMessage] = useState('');
  const [sending, setSending] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const reset = () => {
    setWho('');
    setAmount('');
    setMessage('');
    setError(null);
  };

  const send = async () => {
    const target = who.trim();
    const value = parseAmount(amount);
    const byUpi = isUpiId(target);
    if (!byUpi && localPhone(target).length !== 10) return setError('Enter a 10-digit phone number or a UPI ID.');
    if (value == null) return setError('Please enter a valid amount.');

    setError(null);
    setSending(true);
    const result = byUpi
      ? await createMoneyRequestByUpi({ requesterPhone, requesteeUpi: target, amount: value, message: message.trim() })
      : await createMoneyRequest({
          requesterPhone,
          requesteePhone: toIndianE164(target),
          amount: value,
          message: message.trim(),
        });
    setSending(false);
    if (result.success) {
      reset();
      onSent();
    } else {
      setError(result.message);
    }
  };

  return (
    <Sheet visible={visible} onClose={onClose} dismissable={!sending}>
      <View style={styles.body}>
        <View style={styles.heading}>
          <AppText style={Type.eyebrow()}>new request</AppText>
          <AppText style={[Type.heading(26, 800), styles.title]}>{'Ask anyone\nto pay you.'}</AppText>
        </View>
        <Field
          label="Phone number or UPI ID"
          value={who}
          onChangeText={setWho}
          placeholder="98765 43210 or name@upi"
          autoCapitalize="none"
          autoCorrect={false}
          accessibilityLabel="Phone number or UPI ID"
        />
        <AmountField value={amount} onChangeText={setAmount} />
        <Field label="Note (optional)" value={message} onChangeText={setMessage} placeholder="Add a note" maxLength={80} />
        {error && <ErrorCard message={error} />}
        <View style={styles.actions}>
          <AppButton label="Cancel" outline onPress={onClose} disabled={sending} style={styles.flex} />
          <AppButton label="Send request" onPress={send} loading={sending} style={styles.flex} />
        </View>
      </View>
    </Sheet>
  );
}

const styles = StyleSheet.create({
  body: { gap: 16 },
  heading: { gap: 6 },
  title: { lineHeight: 30 },
  actions: { flexDirection: 'row', gap: 10 },
  flex: { flex: 1 },
});
