import { StyleSheet, View } from 'react-native';

import { AppText, Avatar, Card, Chip, Entrance, Icon, Screen, ScreenHeader, Tap } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { formatINR } from '@/core/utils/format';
import { useBalance, useProfile } from '@/features/account/hooks';
import { InfoRow, MenuGroup } from '@/features/profile/MenuRow';
import { useCopyUpi } from '@/features/profile/use-copy-upi';

export default function AccountDetailsScreen() {
  const profile = useProfile();
  const balance = useBalance();
  const phone = useSession((s) => s.phoneNumber) ?? '—';
  const name = profile.data?.userName || 'Unknown';
  const upiId = profile.data?.upiId ?? '';
  const copyUpi = useCopyUpi(upiId);

  return (
    <Screen
      onRefresh={() => {
        profile.refetch();
        balance.refetch();
      }}
      refreshing={profile.isRefetching || balance.isRefetching}>
      <Entrance>
        <ScreenHeader title="account details" />
        <View style={styles.heading}>
          <AppText style={Type.eyebrow()}>your account</AppText>
          <AppText style={[Type.heading(30, 800), styles.title]}>{'Account\nDetails.'}</AppText>
        </View>

        <Card style={styles.card}>
          <View style={styles.person}>
            <Avatar name={name} size={52} background={Colors.ink} color={Colors.pop} />
            <View style={styles.flex}>
              <AppText style={Type.heading(18)}>{name}</AppText>
              <AppText style={Type.body(13, 500, Colors.textSecondary)}>{phone}</AppText>
            </View>
          </View>
          <Tap onPress={copyUpi} style={styles.upi} accessibilityLabel="Copy UPI ID">
            <View style={styles.flex}>
              <AppText style={Type.eyebrow(Colors.textSecondary, 10)}>upi id</AppText>
              <AppText style={Type.body(15, 700)}>{upiId || 'N/A'}</AppText>
            </View>
            <Icon name="content-copy" size={18} color={Colors.primary} />
          </Tap>
        </Card>

        <Card style={styles.card}>
          <View style={styles.walletRow}>
            <View style={styles.walletIcon}>
              <Icon name="account-balance-wallet" />
            </View>
            <View style={styles.flex}>
              <AppText style={Type.eyebrow()}>wallet balance</AppText>
              <AppText style={[Type.amount(22), styles.amount]}>
                {balance.data != null ? formatINR(balance.data) : balance.isLoading ? '…' : '—'}
              </AppText>
            </View>
            <Chip label="active" background={alpha(Colors.mint, 0.12)} color={Colors.mint} />
          </View>
        </Card>

        <MenuGroup>
          <InfoRow icon="person-outline" label="Display name" value={name} />
          <InfoRow icon="smartphone" label="Phone number" value={phone} />
          <InfoRow icon="alternate-email" label="UPI handle" value={upiId || '—'} />
        </MenuGroup>
      </Entrance>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  heading: { marginTop: 22, marginBottom: 22, gap: 6 },
  title: { lineHeight: 34 },
  card: { marginBottom: 16, gap: 16 },
  person: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  upi: { flexDirection: 'row', alignItems: 'center', padding: 14, borderRadius: 14, backgroundColor: Colors.surfaceDim },
  walletRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  walletIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  amount: { marginTop: 4 },
});
