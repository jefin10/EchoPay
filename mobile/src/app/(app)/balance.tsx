import { useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';

import { AppText, Card, Chip, Entrance, ErrorCard, Icon, IconButton, Screen, ScreenHeader } from '@/core/components';
import { useSession } from '@/core/storage/session';
import { alpha, Colors, Type } from '@/core/theme';
import { formatINR } from '@/core/utils/format';
import { useBalance } from '@/features/account/hooks';

export default function BalanceScreen() {
  const [visible, setVisible] = useState(true);
  const balance = useBalance();
  const userName = useSession((s) => s.userName) ?? 'User';
  const refresh = () => balance.refetch();

  return (
    <Screen onRefresh={refresh} refreshing={balance.isRefetching}>
      <Entrance>
        <ScreenHeader
          title="balance"
          right={
            <>
              <IconButton
                icon={visible ? 'visibility' : 'visibility-off'}
                accessibilityLabel={visible ? 'Hide balance' : 'Show balance'}
                onPress={() => setVisible((v) => !v)}
              />
              <IconButton icon="refresh" accessibilityLabel="Refresh" onPress={refresh} />
            </>
          }
        />

        <Card dark style={styles.hero}>
          <AppText style={Type.eyebrow(alpha(Colors.white, 0.55))}>hi, {userName.toLowerCase()}</AppText>
          <AppText style={[Type.body(14, 500, alpha(Colors.white, 0.7)), styles.label]}>available balance</AppText>
          <View style={styles.amountRow}>
            {balance.isLoading ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <AppText style={Type.amount(48, Colors.white)}>
                {visible ? formatINR(balance.data ?? 0) : '₹ ••••••'}
              </AppText>
            )}
          </View>
          <Chip label="instant" icon="bolt" />
        </Card>

        {balance.isError ? (
          <ErrorCard message="Failed to fetch balance. Pull to retry." onRetry={refresh} />
        ) : balance.data != null ? (
          <Card>
            <View style={styles.bankRow}>
              <View style={styles.bankIcon}>
                <Icon name="account-balance" />
              </View>
              <View style={styles.flex}>
                <AppText style={Type.heading(16)}>Bank account</AppText>
                <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]}>Linked & active</AppText>
              </View>
              <Chip label="active" background={alpha(Colors.mint, 0.12)} color={Colors.mint} />
            </View>
            <View style={styles.divider} />
            <View style={styles.totalRow}>
              <AppText style={Type.body(13, 500, Colors.textSecondary)}>Current balance</AppText>
              <AppText style={Type.amount(18)}>{visible ? formatINR(balance.data) : '₹••••••'}</AppText>
            </View>
          </Card>
        ) : null}
      </Entrance>
    </Screen>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  hero: { marginTop: 28, marginBottom: 22, paddingHorizontal: 24, paddingVertical: 26 },
  label: { marginTop: 6 },
  amountRow: { minHeight: 56, justifyContent: 'center', marginTop: 20, marginBottom: 24 },
  bankRow: { flexDirection: 'row', alignItems: 'center', gap: 14 },
  bankIcon: {
    width: 44,
    height: 44,
    borderRadius: 12,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sub: { marginTop: 2 },
  divider: { height: 1, backgroundColor: Colors.divider, marginVertical: 16 },
  totalRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
});
