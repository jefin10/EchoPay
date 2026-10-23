import { router } from 'expo-router';
import { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton, AppText, Entrance, ErrorCard, Field, Screen, ScreenHeader } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { Type } from '@/core/theme';
import { formatINR } from '@/core/utils/format';
import { isUpiId, localPhone, toIndianE164 } from '@/core/utils/phone';
import { useRefreshAccount } from '@/features/account/hooks';

import { parseAmount } from '../amount';
import { searchByPhone, searchByUpiId, sendByPhone, sendByUpiId, type Recipient } from '../api';
import { AmountField } from './AmountField';
import { RecipientCard } from './RecipientCard';
import { SearchBox } from './SearchBox';
import { SuccessDialog } from './SuccessDialog';

const COPY = {
  phone: {
    header: 'pay to phone',
    eyebrow: 'to a number',
    title: 'Pay any\nphone number.',
    placeholder: 'Phone number',
    icon: 'smartphone',
    empty: 'Please enter a phone number.',
    invalid: 'Enter a 10-digit phone number.',
  },
  upi: {
    header: 'pay to upi id',
    eyebrow: 'to a upi id',
    title: 'Pay any\nUPI handle.',
    placeholder: 'name@upi',
    icon: 'alternate-email',
    empty: 'Please enter a UPI ID.',
    invalid: 'That does not look like a UPI ID (name@bank).',
  },
} as const;

const lookup = (mode: 'phone' | 'upi', value: string) =>
  mode === 'phone' ? searchByPhone(toIndianE164(value)) : searchByUpiId(value.trim());

/** Look up a recipient by phone or UPI ID, then pay them. */
export function PayScreen({
  mode,
  initialTarget = '',
  initialAmount = '',
  initialName,
}: {
  mode: 'phone' | 'upi';
  initialTarget?: string;
  initialAmount?: string;
  initialName?: string;
}) {
  const copy = COPY[mode];
  const senderPhone = useSession((s) => s.phoneNumber) ?? '';
  const refreshAccount = useRefreshAccount();

  const [target, setTarget] = useState(initialTarget);
  const [amount, setAmount] = useState(initialAmount);
  const [note, setNote] = useState('');
  const [recipient, setRecipient] = useState<Recipient | null>(
    initialName && initialTarget ? { upiName: initialName, upiId: initialTarget } : null,
  );
  const [searching, setSearching] = useState(!!initialTarget);
  const [searchError, setSearchError] = useState<string | null>(null);
  const [paying, setPaying] = useState(false);
  const [payError, setPayError] = useState<string | null>(null);
  const [paid, setPaid] = useState<number | null>(null);

  const search = async () => {
    const raw = target.trim();
    setSearchError(null);
    setPayError(null);
    if (!raw) return setSearchError(copy.empty);
    if (mode === 'phone' && localPhone(raw).length !== 10) return setSearchError(copy.invalid);
    if (mode === 'upi' && !isUpiId(raw)) return setSearchError(copy.invalid);

    setSearching(true);
    applyLookup(await lookup(mode, raw));
  };

  const applyLookup = (found: Recipient | null) => {
    setSearching(false);
    setRecipient(found);
    if (!found) setSearchError('User not found.');
  };

  // QR scans arrive with a UPI ID: confirm it exists straight away.
  useEffect(() => {
    if (!initialTarget) return;
    let cancelled = false;
    lookup(mode, initialTarget).then((found) => {
      if (cancelled) return;
      setSearching(false);
      if (found) setRecipient(found);
      else setSearchError('User not found.');
    });
    return () => {
      cancelled = true;
    };
  }, [initialTarget, mode]);

  const pay = async () => {
    if (!recipient) return;
    const value = parseAmount(amount);
    if (value == null) return setPayError('Please enter a valid amount.');
    setPayError(null);
    setPaying(true);
    const result =
      mode === 'phone'
        ? await sendByPhone({ senderPhone, receiverPhone: toIndianE164(target), amount: value })
        : await sendByUpiId({ senderPhone, receiverUpi: target.trim(), amount: value });
    setPaying(false);
    if (result.success) {
      refreshAccount();
      setPaid(value);
    } else {
      setPayError(result.message);
    }
  };

  return (
    <Screen>
      <Entrance>
        <ScreenHeader title={copy.header} />
        <View style={styles.heading}>
          <AppText style={Type.eyebrow()}>{copy.eyebrow}</AppText>
          <AppText style={[Type.heading(30, 800), styles.title]}>{copy.title}</AppText>
        </View>

        <SearchBox
          icon={copy.icon}
          loading={searching}
          onSearch={() => search()}
          value={target}
          onChangeText={(t) => {
            setTarget(t);
            setRecipient(null);
          }}
          placeholder={copy.placeholder}
          keyboardType={mode === 'phone' ? 'phone-pad' : 'email-address'}
          autoCapitalize="none"
          accessibilityLabel={copy.placeholder}
        />
        {searchError && (
          <View style={styles.gapSm}>
            <ErrorCard message={searchError} />
          </View>
        )}

        {recipient && (
          <Entrance distance={10} style={styles.form}>
            <RecipientCard
              name={recipient.upiName}
              subtitle={mode === 'phone' ? recipient.upiId : recipient.phoneNumber || recipient.upiId}
            />
            <AmountField value={amount} onChangeText={setAmount} autoFocus={!initialAmount} />
            <Field label="Note (optional)" value={note} onChangeText={setNote} placeholder="Add a note" maxLength={60} />
            <AppButton label="Pay now" loading={paying} onPress={pay} />
            {payError && <ErrorCard message={payError} />}
          </Entrance>
        )}
      </Entrance>

      <SuccessDialog
        visible={paid != null}
        title="Payment sent"
        message={`${formatINR(paid ?? 0)} to ${recipient?.upiName ?? target}`}
        onDone={() => {
          setPaid(null);
          router.back();
        }}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  heading: { marginTop: 22, marginBottom: 22, gap: 6 },
  title: { lineHeight: 34 },
  gapSm: { marginTop: 14 },
  form: { marginTop: 22, gap: 18 },
});
