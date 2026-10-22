import { router } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppButton, AppDialog, AppText, Avatar, Icon, IconButton, Screen, Sheet, Stagger, Tap } from '@/core/components';
import { useSession, type FlagKey } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { useProfile } from '@/features/account/hooks';
import { InfoRow, MenuGroup, MenuRow, ToggleRow } from '@/features/profile/MenuRow';
import { useCopyUpi } from '@/features/profile/use-copy-upi';
import { useLogout } from '@/features/profile/use-logout';

type SheetKind = 'bank' | 'limits' | 'notifications' | 'help' | null;

const LIMITS = [
  ['Per transaction', '₹1,00,000'],
  ['Daily limit', '₹1,00,000'],
  ['Per month', '₹10,00,000'],
  ['Transactions/day', '20 transfers'],
] as const;

const FAQ = [
  [
    'How do I send money by voice?',
    'Tap the mic and say "Send ₹500 to" a phone number, UPI ID or contact name. EchoPay confirms the details before transferring.',
  ],
  [
    'What if a payment fails?',
    'Failed payments are not deducted. If your balance was deducted and the recipient did not receive the amount, contact support.',
  ],
  [
    'How do I check my balance?',
    'Ask the voice assistant "What is my balance?", or tap the wallet card on the home screen.',
  ],
  [
    'Is my data secure?',
    'The app locks behind biometrics on launch, and voice payments and balance checks ask for biometrics again. Your UPI PIN is never stored on this device.',
  ],
] as const;

const NOTIFICATIONS: { key: FlagKey; title: string; subtitle: string }[] = [
  { key: 'notif_payments', title: 'Payment alerts', subtitle: 'Sent & received confirmations' },
  { key: 'notif_requests', title: 'Money requests', subtitle: 'When someone requests money' },
  { key: 'notif_promotions', title: 'Offers & updates', subtitle: 'App news and promotions' },
];

export default function ProfileTab() {
  const profile = useProfile();
  const { phoneNumber, flags, setFlag } = useSession();
  const logout = useLogout();
  const [sheet, setSheet] = useState<SheetKind>(null);
  const [confirmLogout, setConfirmLogout] = useState(false);

  const name = profile.data?.userName ?? '';
  const upiId = profile.data?.upiId ?? '';
  const copyUpi = useCopyUpi(upiId);

  return (
    <Screen edges={['top']} onRefresh={() => profile.refetch()} refreshing={profile.isRefetching}>
      <Stagger>
        <View style={styles.header}>
          <AppText style={[Type.heading(22), styles.flex]}>profile</AppText>
          <IconButton icon="settings" accessibilityLabel="Security settings" onPress={() => router.push('/profile/security')} />
        </View>

        <View style={styles.identity}>
          <View style={styles.identityTop}>
            <Avatar name={name || 'U'} size={56} background={Colors.pop} color={Colors.ink} />
            <View style={styles.flex}>
              <AppText style={Type.heading(20, 700, Colors.white)} numberOfLines={1}>
                {name || 'Loading...'}
              </AppText>
              <AppText style={[Type.body(13, 600, alpha(Colors.white, 0.6)), styles.sub]}>{phoneNumber}</AppText>
            </View>
          </View>
          <Tap onPress={copyUpi} style={styles.upi} accessibilityLabel="Copy UPI ID">
            <View style={styles.flex}>
              <AppText style={Type.eyebrow(alpha(Colors.white, 0.5), 10)}>upi id</AppText>
              <AppText style={[Type.body(15, 700, Colors.white), styles.sub]}>{upiId || '—'}</AppText>
            </View>
            <Icon name="content-copy" size={18} color={Colors.pop} />
          </Tap>
        </View>

        <MenuGroup>
          <MenuRow icon="person-outline" title="Account details" subtitle="Name, UPI ID & balance" onPress={() => router.push('/profile/account')} />
          <MenuRow icon="account-balance" title="Bank accounts" subtitle="Manage linked accounts" onPress={() => setSheet('bank')} />
          <MenuRow icon="shield" title="Security" subtitle="Biometric settings" onPress={() => router.push('/profile/security')} />
          <MenuRow icon="tune" title="Transaction limits" subtitle="View limits" onPress={() => setSheet('limits')} />
        </MenuGroup>

        <View style={styles.section}>
          <AppText style={Type.eyebrow()}>preferences</AppText>
          <MenuGroup>
            <MenuRow icon="notifications-none" title="Notifications" subtitle="Manage alerts" onPress={() => setSheet('notifications')} />
            <MenuRow icon="help-outline" title="Help & support" subtitle="FAQs & contact" onPress={() => setSheet('help')} />
            <MenuRow icon="info-outline" title="About" subtitle="App version & legal" onPress={() => router.push('/profile/about')} />
          </MenuGroup>
        </View>

        <AppButton label="Log out" icon="logout" outline onPress={() => setConfirmLogout(true)} style={styles.logout} />
      </Stagger>

      <Sheet visible={sheet === 'bank'} onClose={() => setSheet(null)}>
        <AppText style={[Type.heading(20), styles.sheetTitle]}>Bank accounts</AppText>
        <AppText style={Type.body(15, 700)}>No bank accounts linked</AppText>
        <AppText style={[Type.body(13, 500, Colors.textSecondary), styles.para]}>
          Bank account linking is powered by your UPI handle. Payments go directly through your registered UPI.
        </AppText>
        <MenuGroup>
          <InfoRow label="Your UPI ID" value={upiId || '—'} />
        </MenuGroup>
      </Sheet>

      <Sheet visible={sheet === 'limits'} onClose={() => setSheet(null)}>
        <AppText style={[Type.heading(20), styles.sheetTitle]}>Transaction limits</AppText>
        <MenuGroup>
          {LIMITS.map(([label, value]) => (
            <InfoRow key={label} label={label} value={value} />
          ))}
        </MenuGroup>
      </Sheet>

      <Sheet visible={sheet === 'notifications'} onClose={() => setSheet(null)}>
        <AppText style={[Type.heading(20), styles.sheetTitle]}>Notifications</AppText>
        <MenuGroup>
          {NOTIFICATIONS.map((n) => (
            <ToggleRow
              key={n.key}
              title={n.title}
              subtitle={n.subtitle}
              value={flags[n.key]}
              onValueChange={(v) => setFlag(n.key, v)}
            />
          ))}
        </MenuGroup>
      </Sheet>

      <Sheet visible={sheet === 'help'} onClose={() => setSheet(null)}>
        <AppText style={[Type.heading(20), styles.sheetTitle]}>Help & support</AppText>
        <View style={styles.faq}>
          {FAQ.map(([q, a]) => (
            <View key={q} style={styles.faqItem}>
              <AppText style={Type.body(14, 700)}>{q}</AppText>
              <AppText style={[Type.body(13, 500, Colors.textSecondary), styles.para]}>{a}</AppText>
            </View>
          ))}
        </View>
      </Sheet>

      <AppDialog visible={confirmLogout} onClose={() => setConfirmLogout(false)}>
        <AppText style={Type.heading(22)}>Log out?</AppText>
        <AppText style={[Type.body(14, 500, Colors.textSecondary), styles.dialogText]}>
          You will need to verify your number again to come back.
        </AppText>
        <View style={styles.dialogActions}>
          <AppButton label="Cancel" outline onPress={() => setConfirmLogout(false)} style={styles.flex} />
          <AppButton label="Log out" background={Colors.coral} onPress={logout} style={styles.flex} />
        </View>
      </AppDialog>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', marginBottom: 22 },
  identity: { padding: 22, gap: 18, borderRadius: 28, backgroundColor: Colors.ink, marginBottom: 22 },
  identityTop: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  sub: { marginTop: 3 },
  upi: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 14,
    borderRadius: 16,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  section: { marginTop: 26, gap: 12 },
  logout: { marginTop: 26, borderColor: alpha(Colors.coral, 0.4) },
  sheetTitle: { marginBottom: 14 },
  para: { marginTop: 4, marginBottom: 14, lineHeight: 19 },
  faq: { gap: 4 },
  faqItem: { paddingBottom: 4 },
  dialogText: { marginTop: 8, textAlign: 'center' },
  dialogActions: { flexDirection: 'row', gap: 10, alignSelf: 'stretch', marginTop: 22 },
});
