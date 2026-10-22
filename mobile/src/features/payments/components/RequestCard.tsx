import { StyleSheet, View } from 'react-native';

import { AppButton, AppText, Avatar, Chip } from '@/core/components';
import { alpha, Colors, Type } from '@/core/theme';
import { formatDate, formatINR } from '@/core/utils/format';
import type { MoneyRequest, MoneyRequestStatus } from '@/models/money-request';

const STATUS_COLOR: Record<MoneyRequestStatus, string> = {
  pending: Colors.warning,
  approved: Colors.mint,
  rejected: Colors.coral,
  cancelled: Colors.coral,
};

/** One money request. Pending received requests can be paid or declined; pending sent ones cancelled. */
export function RequestCard({
  request,
  direction,
  busy,
  onAction,
}: {
  request: MoneyRequest;
  direction: 'received' | 'sent';
  busy: boolean;
  onAction: (status: 'approved' | 'rejected' | 'cancelled') => void;
}) {
  const color = STATUS_COLOR[request.status] ?? Colors.textSecondary;
  const pending = request.status === 'pending';
  return (
    <View style={styles.card}>
      <View style={styles.person}>
        <Avatar name={request.counterpartyName} size={44} />
        <View style={styles.flex}>
          <AppText style={Type.body(15, 700)} numberOfLines={1}>
            {request.counterpartyName}
          </AppText>
          <AppText style={Type.body(12, 500, Colors.textSecondary)}>{request.counterpartyPhone}</AppText>
        </View>
        <Chip label={request.status} background={alpha(color, 0.12)} color={color} />
      </View>

      <View style={styles.amountRow}>
        <View style={styles.flex}>
          <AppText style={Type.eyebrow(Colors.textSecondary, 10)}>
            {direction === 'received' ? 'Amount requested' : 'You requested'}
          </AppText>
          <AppText style={[Type.amount(22), styles.amount]}>{formatINR(request.amount)}</AppText>
        </View>
        <AppText style={Type.body(11, 600, Colors.textSecondary)}>{formatDate(request.createdAt)}</AppText>
      </View>

      {request.message ? (
        <AppText style={[Type.body(13, 500, Colors.textGrayDark), styles.message]}>“{request.message}”</AppText>
      ) : null}

      {pending &&
        (direction === 'received' ? (
          <View style={styles.actions}>
            <AppButton label="Decline" outline onPress={() => onAction('rejected')} disabled={busy} style={styles.flex} />
            <AppButton label="Pay" onPress={() => onAction('approved')} loading={busy} style={styles.flex} />
          </View>
        ) : (
          <AppButton
            label="Cancel request"
            outline
            onPress={() => onAction('cancelled')}
            loading={busy}
            style={styles.cancel}
          />
        ))}
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    padding: 16,
    gap: 14,
    borderRadius: 20,
    backgroundColor: Colors.surface,
    borderWidth: 1,
    borderColor: Colors.border,
  },
  flex: { flex: 1 },
  person: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  amountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 14,
    paddingVertical: 12,
    borderRadius: 14,
    backgroundColor: Colors.surfaceDim,
  },
  amount: { marginTop: 4 },
  message: { fontStyle: 'italic' },
  actions: { flexDirection: 'row', gap: 10 },
  cancel: { borderColor: alpha(Colors.coral, 0.4) },
});
