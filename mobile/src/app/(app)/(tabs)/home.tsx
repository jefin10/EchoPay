import { router, type Href } from 'expo-router';
import { useState } from 'react';
import { StyleSheet, View } from 'react-native';

import { AppText, Icon, Screen, Shimmer, SkeletonBar, Stagger, Tap, toast, type IconName } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';
import { formatINR, greeting } from '@/core/utils/format';
import { ActivityRow, ActivityRowSkeleton } from '@/features/account/components/TransactionRow';
import { useBalance, useProfile, useRefreshAccount, useTransactions } from '@/features/account/hooks';

const QUICK_ACTIONS: { icon: IconName; label: string; href: Href }[] = [
  { icon: 'qr-code-scanner', label: 'Scan', href: '/qr-scanner' },
  { icon: 'smartphone', label: 'To phone', href: '/pay/phone' },
  { icon: 'account-balance-wallet', label: 'Balance', href: '/balance' },
  { icon: 'receipt-long', label: 'History', href: '/history' },
];

const MOVE_MONEY: { icon: IconName; title: string; subtitle: string; href: Href }[] = [
  { icon: 'contacts', title: 'To contact', subtitle: 'From your phone', href: '/pay/contacts' },
  { icon: 'alternate-email', title: 'To UPI ID', subtitle: 'Any UPI handle', href: '/pay/upi' },
  { icon: 'call-received', title: 'Request', subtitle: 'Ask anyone to pay you', href: '/requests' },
  { icon: 'qr-code-2', title: 'My QR', subtitle: 'Show & get paid', href: '/my-qr' },
];

export default function HomeScreen() {
  const [hidden, setHidden] = useState(false);
  const profile = useProfile();
  const balance = useBalance();
  const transactions = useTransactions();
  const refreshAccount = useRefreshAccount();
  const [refreshing, setRefreshing] = useState(false);

  const userName = profile.data?.userName ?? '';
  const upiId =
    profile.data?.upiId || (userName ? `${userName.toLowerCase().replace(/\s/g, '')}@upi` : 'your-id@upi');
  const recent = transactions.data?.slice(0, 4) ?? [];

  const refresh = async () => {
    setRefreshing(true);
    await Promise.all([refreshAccount(), profile.refetch()]);
    setRefreshing(false);
  };

  return (
    <Screen onRefresh={refresh} refreshing={refreshing} edges={['top']} contentStyle={styles.content}>
      <Stagger>
        {/* Header */}
        <View style={styles.topRow}>
          <View style={styles.avatar}>
            <AppText style={Type.body(18, 800, Colors.pop)}>{userName ? userName[0]!.toUpperCase() : 'U'}</AppText>
          </View>
          <View style={styles.flex}>
            <AppText style={Type.body(12.5, 600, Colors.textSecondary)}>{greeting()}</AppText>
            <AppText style={[Type.heading(19), styles.name]} numberOfLines={1}>
              {userName || 'Welcome back'}
            </AppText>
          </View>
          <HeaderButton icon="qr-code-scanner" label="Scan QR" onPress={() => router.push('/qr-scanner')} />
          <HeaderButton icon="notifications-none" label="Notifications" onPress={() => toast('No new notifications')} />
        </View>

        {/* Wallet hero */}
        <Tap scale={0.985} onPress={() => router.push('/balance')} style={styles.wallet} accessibilityRole="button">
          <View style={styles.glow} />
          <View style={styles.walletHead}>
            <AppText style={Type.eyebrow(alpha(Colors.white, 0.55))}>available balance</AppText>
            <Tap
              scale={0.86}
              hitSlop={10}
              onPress={() => setHidden((h) => !h)}
              accessibilityLabel={hidden ? 'Show balance' : 'Hide balance'}>
              <Icon name={hidden ? 'visibility-off' : 'visibility'} size={18} color={alpha(Colors.white, 0.7)} />
            </Tap>
          </View>
          <View style={styles.balanceLine}>
            {balance.isLoading ? (
              <Shimmer>
                <SkeletonBar width={180} height={38} dark />
              </Shimmer>
            ) : balance.data == null ? (
              <AppText style={Type.amount(30, alpha(Colors.white, 0.7))}>Unavailable</AppText>
            ) : (
              <AppText style={Type.amount(38, Colors.white)}>
                {hidden ? '₹ ••••••' : formatINR(balance.data)}
              </AppText>
            )}
          </View>
          <View style={styles.walletFoot}>
            <AppText style={[Type.body(12.5, 600, alpha(Colors.white, 0.5)), styles.flex]} numberOfLines={1}>
              {upiId}
            </AppText>
            <AppText style={Type.body(12.5, 700, Colors.pop)}>View statement</AppText>
            <Icon name="north-east" size={15} color={Colors.pop} />
          </View>
        </Tap>

        {/* Quick pay */}
        <View style={styles.section}>
          <AppText style={Type.eyebrow()}>quick pay</AppText>
          <View style={styles.quick}>
            {QUICK_ACTIONS.map((a, i) => (
              <View key={a.label} style={styles.quickCell}>
                {i > 0 && <View style={styles.quickDivider} />}
                <Tap onPress={() => router.push(a.href)} style={styles.quickItem} accessibilityRole="button">
                  <Icon name={a.icon} size={23} />
                  <AppText style={Type.body(12, 700)}>{a.label}</AppText>
                </Tap>
              </View>
            ))}
          </View>
        </View>

        {/* Voice banner */}
        <Tap onPress={() => router.push('/speech')} style={styles.voice} accessibilityRole="button">
          <View style={styles.voiceIcon}>
            <Icon name="graphic-eq" size={24} color={Colors.pop} />
          </View>
          <View style={styles.flex}>
            <AppText style={Type.eyebrow(Colors.ink)}>voice pay</AppText>
            <AppText style={[Type.heading(16), styles.voiceTitle]}>“Send ₹500 to 98765 43210”</AppText>
            <AppText style={Type.body(12, 500, Colors.textSecondary)}>Say it once. We handle the rest.</AppText>
          </View>
          <View style={styles.voiceArrow}>
            <Icon name="arrow-forward" size={17} color={Colors.pop} />
          </View>
        </Tap>

        {/* Move money */}
        <View style={styles.section}>
          <AppText style={Type.eyebrow()}>move money</AppText>
          <View style={styles.grid}>
            {MOVE_MONEY.map((c) => (
              <Tap key={c.title} onPress={() => router.push(c.href)} style={styles.gridCard} accessibilityRole="button">
                <View style={styles.gridHead}>
                  <View style={styles.gridIcon}>
                    <Icon name={c.icon} size={19} />
                  </View>
                  <Icon name="north-east" size={16} color={Colors.textMuted} />
                </View>
                <AppText style={Type.heading(15)}>{c.title}</AppText>
                <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.gridSub]}>{c.subtitle}</AppText>
              </Tap>
            ))}
          </View>
        </View>

        {/* Recent activity */}
        <View style={styles.recent}>
          <View style={styles.recentHead}>
            <AppText style={Type.eyebrow()}>recent activity</AppText>
            <Tap scale={0.94} onPress={() => router.push('/history')} hitSlop={8}>
              <AppText style={Type.body(13, 700, Colors.primary)}>See all</AppText>
            </Tap>
          </View>
          {transactions.isLoading ? (
            [0, 1, 2].map((i) => <ActivityRowSkeleton key={i} />)
          ) : recent.length === 0 ? (
            <View style={styles.empty}>
              <View style={styles.emptyIcon}>
                <Icon name="receipt-long" size={22} color={Colors.textSecondary} />
              </View>
              <AppText style={Type.body(14, 700)}>Nothing here yet</AppText>
              <AppText style={Type.body(12, 500, Colors.textSecondary)}>Your first payment will show up here.</AppText>
            </View>
          ) : (
            recent.map((tx, i) => (
              <View key={`${tx.timestamp}-${i}`} style={i > 0 ? styles.divided : null}>
                <ActivityRow tx={tx} onPress={() => router.push('/history')} />
              </View>
            ))
          )}
        </View>
      </Stagger>
    </Screen>
  );
}

function HeaderButton({ icon, label, onPress }: { icon: IconName; label: string; onPress: () => void }) {
  return (
    <Tap onPress={onPress} style={styles.headerButton} accessibilityRole="button" accessibilityLabel={label}>
      <Icon name={icon} size={20} />
    </Tap>
  );
}

const styles = StyleSheet.create({
  content: { paddingTop: 12, gap: 0 },
  flex: { flex: 1 },
  topRow: { flexDirection: 'row', alignItems: 'center', gap: 10, marginBottom: 22 },
  avatar: {
    width: 46,
    height: 46,
    borderRadius: 15,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 3,
  },
  name: { marginTop: 3 },
  headerButton: {
    width: 46,
    height: 46,
    borderRadius: 15,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
    alignItems: 'center',
    justifyContent: 'center',
  },
  wallet: {
    backgroundColor: Colors.ink,
    borderRadius: 28,
    paddingHorizontal: 24,
    paddingVertical: 22,
    overflow: 'hidden',
    shadowColor: Colors.ink,
    shadowOpacity: 0.22,
    shadowRadius: 28,
    shadowOffset: { width: 0, height: 14 },
    elevation: 10,
  },
  glow: {
    position: 'absolute',
    right: -64,
    top: -64,
    width: 188,
    height: 188,
    borderRadius: 94,
    backgroundColor: alpha(Colors.pop, 0.1),
  },
  walletHead: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  balanceLine: { marginTop: 18, minHeight: 44, justifyContent: 'center' },
  walletFoot: { flexDirection: 'row', alignItems: 'center', gap: 4, marginTop: 22 },
  section: { marginTop: 30, gap: 12 },
  quick: {
    flexDirection: 'row',
    backgroundColor: Colors.surface,
    borderRadius: 20,
    borderWidth: 1,
    borderColor: Colors.border,
    paddingVertical: 16,
  },
  quickCell: { flex: 1, flexDirection: 'row', alignItems: 'center' },
  quickDivider: { width: 1, height: 34, backgroundColor: Colors.divider },
  quickItem: { flex: 1, alignItems: 'center', gap: 9 },
  voice: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 15,
    marginTop: 28,
    paddingVertical: 16,
    paddingLeft: 18,
    paddingRight: 16,
    borderRadius: 20,
    backgroundColor: Colors.popSoft,
  },
  voiceIcon: {
    width: 50,
    height: 50,
    borderRadius: 15,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
  },
  voiceTitle: { marginTop: 5, marginBottom: 2 },
  voiceArrow: {
    width: 34,
    height: 34,
    borderRadius: 11,
    backgroundColor: Colors.ink,
    alignItems: 'center',
    justifyContent: 'center',
  },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 12 },
  gridCard: {
    width: '47.8%',
    flexGrow: 1,
    padding: 16,
    borderRadius: 18,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  gridHead: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 },
  gridIcon: {
    width: 38,
    height: 38,
    borderRadius: 12,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridSub: { marginTop: 3 },
  recent: {
    marginTop: 30,
    paddingTop: 18,
    paddingHorizontal: 18,
    paddingBottom: 10,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  recentHead: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 },
  divided: { borderTopWidth: 1, borderTopColor: Colors.divider },
  empty: { alignItems: 'center', paddingTop: 26, paddingBottom: 24, gap: 4 },
  emptyIcon: {
    width: 46,
    height: 46,
    borderRadius: 15,
    backgroundColor: Colors.surfaceDim,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 10,
  },
});
