import { useQuery } from '@tanstack/react-query';
import { router } from 'expo-router';
import { useMemo, useState } from 'react';
import { ActivityIndicator, FlatList, Linking, Modal, StyleSheet, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import {
  AppButton,
  AppDialog,
  AppText,
  Avatar,
  ErrorCard,
  Field,
  Icon,
  ScreenHeader,
  Sheet,
  Tap,
  type IconName,
} from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { formatINR } from '@/core/utils/format';
import { localPhone, toIndianE164 } from '@/core/utils/phone';
import { useRefreshAccount } from '@/features/account/hooks';
import { parseAmount } from '@/features/payments/amount';
import { hasAccount, sendByPhone } from '@/features/payments/api';
import { AmountField } from '@/features/payments/components/AmountField';
import { RecipientCard } from '@/features/payments/components/RecipientCard';
import { SuccessDialog } from '@/features/payments/components/SuccessDialog';
import { filterContacts, loadContacts, type DeviceContact } from '@/features/payments/contacts';

export default function PayToContactsScreen() {
  const contacts = useQuery({ queryKey: ['deviceContacts'], queryFn: loadContacts, staleTime: 60_000 });
  const [query, setQuery] = useState('');
  const [checking, setChecking] = useState(false);
  const [notOnEchoPay, setNotOnEchoPay] = useState(false);
  const [payee, setPayee] = useState<DeviceContact | null>(null);
  const [paid, setPaid] = useState<{ name: string; amount: number } | null>(null);

  const list = useMemo(
    () => (contacts.data?.granted ? filterContacts(contacts.data.contacts, query) : []),
    [contacts.data, query],
  );

  const onContactPress = async (contact: DeviceContact) => {
    if (!contact.phone) return setNotOnEchoPay(true);
    setChecking(true);
    const exists = await hasAccount(localPhone(contact.phone));
    setChecking(false);
    if (exists) setPayee(contact);
    else setNotOnEchoPay(true);
  };

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.header}>
        <ScreenHeader
          title="contacts"
          right={
            <View style={styles.count}>
              <AppText style={Type.body(12, 800, Colors.pop)}>{list.length}</AppText>
            </View>
          }
        />
        <View style={styles.search}>
          <Icon name="search" size={18} color={Colors.textSecondary} />
          <TextInput
            value={query}
            onChangeText={setQuery}
            placeholder="Search name or number"
            placeholderTextColor={Colors.textMuted}
            autoCorrect={false}
            style={[Type.body(15, 600), styles.searchInput]}
          />
          {query ? (
            <Tap onPress={() => setQuery('')} hitSlop={8} accessibilityLabel="Clear search">
              <Icon name="close" size={18} color={Colors.textSecondary} />
            </Tap>
          ) : null}
        </View>
      </View>

      {contacts.isLoading ? (
        <View style={styles.center}>
          <ActivityIndicator color={Colors.ink} />
        </View>
      ) : contacts.isError ? (
        <Empty icon="error-outline" title="Could not load contacts" />
      ) : !contacts.data?.granted ? (
        <Empty icon="contacts" title="Contacts permission needed" subtitle="Allow access to pay people from your phone book.">
          <AppButton label="Open settings" onPress={() => Linking.openSettings()} style={styles.settings} />
        </Empty>
      ) : (
        <FlatList
          data={list}
          keyExtractor={(c) => c.id}
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={[styles.list, list.length === 0 && styles.grow]}
          ItemSeparatorComponent={() => <View style={styles.sep} />}
          ListEmptyComponent={
            <Empty icon="person-search" title={query ? 'No matching contacts' : 'No contacts found'} />
          }
          renderItem={({ item }) => (
            <Tap scale={0.98} onPress={() => onContactPress(item)} style={styles.row} accessibilityRole="button">
              <Avatar name={item.name} size={44} />
              <View style={styles.flex}>
                <AppText style={Type.body(15, 700)} numberOfLines={1}>
                  {item.name}
                </AppText>
                <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]}>
                  {item.phone ?? 'No phone number'}
                </AppText>
              </View>
              <Icon name="arrow-forward" size={18} color={Colors.textMuted} />
            </Tap>
          )}
        />
      )}

      <Modal visible={checking} transparent animationType="fade">
        <View style={styles.overlay}>
          <View style={styles.spinnerBox}>
            <ActivityIndicator color={Colors.ink} />
          </View>
        </View>
      </Modal>

      <AppDialog visible={notOnEchoPay} onClose={() => setNotOnEchoPay(false)}>
        <View style={styles.infoIcon}>
          <Icon name="info-outline" size={28} color={Colors.primary} />
        </View>
        <AppText style={[Type.body(15, 600), styles.infoText]}>No UPI account found for this contact.</AppText>
        <AppButton label="OK" onPress={() => setNotOnEchoPay(false)} style={styles.stretch} />
      </AppDialog>

      {payee && (
        <PaySheet
          contact={payee}
          onClose={() => setPayee(null)}
          onPaid={(amount) => {
            setPaid({ name: payee.name, amount });
            setPayee(null);
          }}
        />
      )}

      <SuccessDialog
        visible={paid != null}
        title="Payment sent"
        message={`${formatINR(paid?.amount ?? 0)} to ${paid?.name ?? ''}`}
        onDone={() => {
          setPaid(null);
          router.back();
        }}
      />
    </SafeAreaView>
  );
}

function PaySheet({
  contact,
  onClose,
  onPaid,
}: {
  contact: DeviceContact;
  onClose: () => void;
  onPaid: (amount: number) => void;
}) {
  const senderPhone = useSession((s) => s.phoneNumber) ?? '';
  const refreshAccount = useRefreshAccount();
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [paying, setPaying] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const pay = async () => {
    const value = parseAmount(amount);
    if (value == null) return setError('Enter a valid amount.');
    setError(null);
    setPaying(true);
    const result = await sendByPhone({ senderPhone, receiverPhone: toIndianE164(contact.phone!), amount: value });
    setPaying(false);
    if (result.success) {
      refreshAccount();
      onPaid(value);
    } else {
      setError(result.message);
    }
  };

  return (
    <Sheet visible onClose={onClose} dismissable={!paying}>
      <View style={styles.sheet}>
        <RecipientCard name={contact.name} subtitle={contact.phone ?? undefined} />
        <AmountField value={amount} onChangeText={setAmount} autoFocus />
        <Field label="Note (optional)" value={note} onChangeText={setNote} placeholder="Add a note" maxLength={60} />
        <AppButton label="Pay now" loading={paying} onPress={pay} />
        {error && <ErrorCard message={error} />}
      </View>
    </Sheet>
  );
}

function Empty({
  icon,
  title,
  subtitle,
  children,
}: {
  icon: IconName;
  title: string;
  subtitle?: string;
  children?: React.ReactNode;
}) {
  return (
    <View style={styles.center}>
      <View style={styles.emptyIcon}>
        <Icon name={icon} size={28} />
      </View>
      <AppText style={[Type.heading(16), styles.emptyTitle]}>{title}</AppText>
      {subtitle ? <AppText style={[Type.body(13, 500, Colors.textSecondary), styles.center2]}>{subtitle}</AppText> : null}
      {children}
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: Colors.surfaceLight },
  flex: { flex: 1 },
  header: { paddingHorizontal: 20, paddingTop: 8, gap: 18, marginBottom: 14 },
  count: { paddingHorizontal: 10, paddingVertical: 6, borderRadius: 20, backgroundColor: Colors.ink },
  search: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: Colors.border,
    backgroundColor: Colors.surface,
  },
  searchInput: { flex: 1, paddingVertical: 14 },
  list: { paddingHorizontal: 20, paddingBottom: 24 },
  grow: { flexGrow: 1 },
  sep: { height: 1, backgroundColor: Colors.divider },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14, paddingVertical: 12 },
  sub: { marginTop: 2 },
  center: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 32 },
  center2: { textAlign: 'center', marginTop: 6 },
  emptyIcon: {
    width: 72,
    height: 72,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  emptyTitle: { marginTop: 18, textAlign: 'center' },
  settings: { marginTop: 20, alignSelf: 'stretch' },
  overlay: { flex: 1, backgroundColor: 'rgba(20,18,43,0.3)', alignItems: 'center', justifyContent: 'center' },
  spinnerBox: { padding: 20, borderRadius: 16, backgroundColor: Colors.surface },
  infoIcon: {
    width: 64,
    height: 64,
    borderRadius: 20,
    backgroundColor: alpha(Colors.primary, 0.1),
    alignItems: 'center',
    justifyContent: 'center',
  },
  infoText: { marginTop: 16, textAlign: 'center' },
  stretch: { alignSelf: 'stretch', marginTop: 22 },
  sheet: { gap: 18 },
});
