import { StyleSheet, View } from 'react-native';

import { AppText, Icon, Shimmer, SkeletonBar, Tap } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';
import { formatDate, formatINR, formatTime, relativeTime } from '@/core/utils/format';
import type { TransactionItem } from '@/models/transaction';

function DirectionIcon({ sent, size }: { sent: boolean; size: number }) {
  return (
    <View
      style={[
        styles.icon,
        { width: size, height: size, backgroundColor: sent ? Colors.surfaceDim : alpha(Colors.mint, 0.12) },
      ]}>
      <Icon name={sent ? 'arrow-upward' : 'arrow-downward'} size={size * 0.47} color={sent ? Colors.ink : Colors.mint} />
    </View>
  );
}

const title = (t: TransactionItem) => `${t.type === 'sent' ? 'To' : 'From'} ${t.counterpartyName}`;
const signed = (t: TransactionItem) => `${t.type === 'sent' ? '-' : '+'}${formatINR(t.amount)}`;

/** Compact row used in the home "recent activity" list. */
export function ActivityRow({ tx, onPress }: { tx: TransactionItem; onPress?: () => void }) {
  const sent = tx.type === 'sent';
  const when = relativeTime(tx.timestamp);
  return (
    <Tap scale={0.98} onPress={onPress} style={styles.activityRow} accessibilityRole="button">
      <DirectionIcon sent={sent} size={38} />
      <View style={styles.flex}>
        <AppText style={Type.body(14, 700)} numberOfLines={1}>
          {title(tx)}
        </AppText>
        <AppText style={[Type.body(12, 500, Colors.textSecondary), styles.sub]}>
          {when || (sent ? 'Sent' : 'Received')}
        </AppText>
      </View>
      <AppText style={Type.body(15, 800, sent ? Colors.ink : Colors.mint)}>{signed(tx)}</AppText>
    </Tap>
  );
}

/** Card tile used on the history screen. */
export function TransactionCard({ tx }: { tx: TransactionItem }) {
  const sent = tx.type === 'sent';
  const statusColor = tx.status === 'completed' ? Colors.mint : tx.status === 'pending' ? Colors.warning : Colors.coral;
  return (
    <View style={styles.card}>
      <DirectionIcon sent={sent} size={44} />
      <View style={styles.flex}>
        <AppText style={Type.body(14, 700)} numberOfLines={1}>
          {title(tx)}
        </AppText>
        <View style={styles.meta}>
          <View style={[styles.status, { backgroundColor: alpha(statusColor, 0.12) }]}>
            <AppText style={[Type.body(9, 800, statusColor), styles.statusText]}>{tx.status.toUpperCase()}</AppText>
          </View>
          <AppText style={Type.body(11, 500, Colors.textSecondary)}>
            {[formatDate(tx.timestamp), formatTime(tx.timestamp)].filter(Boolean).join(' · ')}
          </AppText>
        </View>
      </View>
      <AppText style={Type.amount(16, sent ? Colors.ink : Colors.mint)}>{signed(tx)}</AppText>
    </View>
  );
}

export function ActivityRowSkeleton() {
  return (
    <View style={styles.activityRow}>
      <Shimmer>
        <View style={styles.skeleton}>
          <SkeletonBar width={38} height={38} radius={12} />
          <View style={[styles.flex, styles.skeletonText]}>
            <SkeletonBar width={90} height={12} />
            <SkeletonBar width={140} height={10} />
          </View>
          <SkeletonBar width={56} height={14} />
        </View>
      </Shimmer>
    </View>
  );
}

const styles = StyleSheet.create({
  flex: { flex: 1 },
  icon: { borderRadius: 12, alignItems: 'center', justifyContent: 'center' },
  activityRow: { flexDirection: 'row', alignItems: 'center', gap: 12, paddingVertical: 14 },
  sub: { marginTop: 3 },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    paddingVertical: 14,
    paddingLeft: 14,
    paddingRight: 16,
    borderRadius: 18,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  meta: { flexDirection: 'row', alignItems: 'center', gap: 8, marginTop: 4 },
  status: { paddingHorizontal: 8, paddingVertical: 3, borderRadius: 6 },
  statusText: { letterSpacing: 0.6 },
  skeleton: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  skeletonText: { gap: 7 },
});
